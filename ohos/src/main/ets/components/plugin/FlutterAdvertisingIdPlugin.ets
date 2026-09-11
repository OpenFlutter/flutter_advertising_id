/*
 * Copyright (C) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * Modified for advertising_id_flutter: channel, permission semantics and lifecycle.
 */
import {
  AbilityAware, AbilityPluginBinding, FlutterPlugin, FlutterPluginBinding,
  MethodCall, MethodCallHandler, MethodChannel, MethodResult,
} from '@ohos/flutter_ohos';
import { abilityAccessCtrl, Permissions, bundleManager, common } from '@kit.AbilityKit';
import { identifier } from '@kit.AdsKit';

class PluginFailure extends Error {
  code: string;
  constructor(code: string, message: string) {
    super(message);
    this.code = code;
  }
}

export default class FlutterAdvertisingIdPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private channel: MethodChannel | null = null;
  private abilityContext: common.UIAbilityContext | null = null;
  private abilityGeneration: number = 0;
  private authorization: Promise<boolean> | null = null;

  getUniqueClassName(): string {
    return 'FlutterAdvertisingIdPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'dev.openflutter/flutter_advertising_id');
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
    this.onDetachedFromAbility();
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.abilityGeneration++;
    this.abilityContext = binding.getAbility().context;
  }

  onDetachedFromAbility(): void {
    this.abilityGeneration++;
    this.abilityContext = null;
  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    if (call.method !== 'getAdvertisingId' && call.method !== 'limitAdTrackingEnabled' &&
      call.method !== 'authorizationStatus') {
      result.notImplemented();
      return;
    }
    try {
      let granted = await this.hasPermission();
      if (call.method === 'authorizationStatus') {
        result.success(granted ? 3 : 2);
        return;
      }
      if (call.method === 'limitAdTrackingEnabled') {
        result.success(!granted);
        return;
      }
      if (!granted && call.args === true) {
        granted = await this.requestPermission();
      }
      result.success(granted ? await this.getOAID() : null);
    } catch (error) {
      if (error instanceof PluginFailure) {
        result.error(error.code, error.message, null);
      } else {
        result.error('PERMISSION_ERROR', 'Failed to obtain tracking permission', null);
      }
    }
  }

  private async hasPermission(): Promise<boolean> {
    const permission: Permissions = 'ohos.permission.APP_TRACKING_CONSENT';
    const info = await bundleManager.getBundleInfoForSelf(
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    const status = await abilityAccessCtrl.createAtManager().checkAccessToken(
      info.appInfo.accessTokenId, permission);
    return status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  }

  private async requestPermission(): Promise<boolean> {
    if (this.authorization !== null) {
      return this.authorization;
    }
    const context = this.abilityContext;
    if (context === null) {
      throw new PluginFailure('NO_ACTIVITY', 'A UI Ability is required to request tracking permission');
    }
    const generation = this.abilityGeneration;
    const pending = this.requestFromAbility(context, generation);
    this.authorization = pending;
    try {
      return await pending;
    } finally {
      this.authorization = null;
    }
  }

  private async requestFromAbility(context: common.UIAbilityContext, generation: number): Promise<boolean> {
    const permission: Permissions = 'ohos.permission.APP_TRACKING_CONSENT';
    await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context, [permission]);
    if (generation !== this.abilityGeneration || this.abilityContext === null) {
      throw new PluginFailure('NO_ACTIVITY', 'The UI Ability detached during the permission request');
    }
    return this.hasPermission();
  }

  private async getOAID(): Promise<string | null> {
    try {
      const oaid = await identifier.getOAID();
      return !oaid || /^0+(?:-0+)*$/.test(oaid) ? null : oaid;
    } catch (error) {
      throw new PluginFailure('GET_AD_ID_FAILED', 'Failed to obtain OAID');
    }
  }
}
