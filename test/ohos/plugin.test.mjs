import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { runInNewContext } from 'node:vm';
import test from 'node:test';

const path = process.env.OHOS_PLUGIN_SOURCE ?? 'ohos/src/main/ets/components/plugin/FlutterAdvertisingIdPlugin.ets';
function fixture(options = {}) {
  const state = { granted: false, requests: 0, reads: 0, handlers: [], ...options };
  const manager = {
    async checkAccessToken() { if (state.checkError) throw Error('check'); return state.granted ? 0 : -1; },
    async requestPermissionsFromUser(context) {
      state.requests++; state.requestContext = context;
      if (state.requestError) throw Error('request');
      if (state.wait) await state.wait;
      state.granted = state.allow ?? false;
    },
  };
  const source = readFileSync(path, 'utf8').replace(/import\s+[\s\S]*?from\s+['"][^'"]+['"];?/g, '').replace('export default class', 'class');
  const className = source.match(/class (\w+) implements/)[1];
  const Plugin = runInNewContext(stripTypeScriptTypes(source) + `\n${className}`, {
    console, getContext: () => ({}),
    MethodChannel: class { constructor(messenger, name) { state.channel = name; } setMethodCallHandler(handler) { state.handlers.push(handler); } },
    abilityAccessCtrl: { createAtManager: () => manager, GrantStatus: { PERMISSION_GRANTED: 0, PERMISSION_DENIED: -1 } },
    bundleManager: { BundleFlag: { GET_BUNDLE_INFO_WITH_APPLICATION: 1 }, async getBundleInfoForSelf() { return { appInfo: { accessTokenId: 1 } }; } },
    identifier: { async getOAID() { state.reads++; if (state.oaidError) throw Error('oaid'); return state.oaid ?? 'test-oaid'; } },
  });
  const plugin = new Plugin();
  plugin.onAttachedToEngine({ getBinaryMessenger() {} });
  const context = {};
  if (options.attached !== false) plugin.onAttachedToAbility?.({ getAbility: () => ({ context }) });
  async function call(method, args) {
    const replies = [];
    await plugin.onMethodCall({ method, args }, { success: value => replies.push({ value }), error: code => replies.push({ error: code }), notImplemented: () => replies.push({ missing: true }) });
    assert.equal(replies.length, 1, 'each call must complete exactly once');
    return replies[0];
  }
  return { state, plugin, call, context };
}

test('false does not request permission or access OAID when denied', async () => {
  const f = fixture();
  assert.deepEqual(await f.call('getAdvertisingId', false), { value: null });
  assert.equal(f.state.requests, 0);
  assert.equal(f.state.reads, 0);
});

test('status methods are readonly and reflect current permission', async () => {
  const f = fixture();
  assert.deepEqual(await f.call('authorizationStatus'), { value: 2 });
  assert.deepEqual(await f.call('limitAdTrackingEnabled'), { value: true });
  f.state.granted = true;
  assert.deepEqual(await f.call('authorizationStatus'), { value: 3 });
  assert.deepEqual(await f.call('limitAdTrackingEnabled'), { value: false });
  assert.equal(f.state.requests, 0);
});
test('true requests using attached Ability and denial is normal', async () => {
  const f = fixture();
  assert.deepEqual(await f.call('getAdvertisingId', true), { value: null });
  assert.equal(f.state.requestContext, f.context);
  assert.equal(f.state.reads, 0);
});
test('permission checks and requests surface errors', async () => {
  for (const method of ['authorizationStatus', 'limitAdTrackingEnabled', 'getAdvertisingId']) {
    assert.deepEqual(await fixture({ checkError: true }).call(method, true), { error: 'PERMISSION_ERROR' });
  }
  assert.deepEqual(await fixture({ requestError: true }).call('getAdvertisingId', true), { error: 'PERMISSION_ERROR' });
});
test('missing Ability blocks only a required prompt', async () => {
  const f = fixture({ attached: false });
  assert.deepEqual(await f.call('getAdvertisingId', false), { value: null });
  assert.deepEqual(await f.call('getAdvertisingId', true), { error: 'NO_ACTIVITY' });
  f.state.granted = true;
  assert.deepEqual(await f.call('getAdvertisingId', true), { value: 'test-oaid' });
});
test('normalizes unavailable OAIDs and surfaces service failures', async () => {
  for (const oaid of ['', '00000000-0000-0000-0000-000000000000', '000000']) {
    assert.deepEqual(await fixture({ granted: true, oaid }).call('getAdvertisingId', false), { value: null });
  }
  assert.deepEqual(await fixture({ granted: true, oaidError: true }).call('getAdvertisingId', false), { error: 'GET_AD_ID_FAILED' });
});
test('channel registration and unknown method', async () => {
  const f = fixture();
  assert.equal(f.state.channel, 'dev.openflutter/flutter_advertising_id');
  assert.equal(f.plugin.getUniqueClassName(), 'FlutterAdvertisingIdPlugin');
  assert.deepEqual(await f.call('unknown'), { missing: true });
});
test('concurrent requests share a prompt and permit retry after denial', async () => {
  let release;
  const f = fixture({ wait: new Promise(resolve => { release = resolve; }), allow: true });
  const a = f.call('getAdvertisingId', true);
  const b = f.call('getAdvertisingId', true);
  await new Promise(resolve => setImmediate(resolve));
  assert.equal(f.state.requests, 1);
  release();
  assert.deepEqual(await a, { value: 'test-oaid' });
  assert.deepEqual(await b, { value: 'test-oaid' });
  f.state.granted = false;
  f.state.allow = false;
  assert.deepEqual(await f.call('getAdvertisingId', true), { value: null });
  assert.equal(f.state.requests, 2);
});
test('detaching engine removes handler and invalidates pending prompt', async () => {
  let release;
  const f = fixture({ wait: new Promise(resolve => { release = resolve; }), allow: true });
  const pending = f.call('getAdvertisingId', true);
  await new Promise(resolve => setImmediate(resolve));
  f.plugin.onDetachedFromEngine({});
  assert.equal(f.state.handlers.at(-1), null);
  release();
  assert.deepEqual(await pending, { error: 'NO_ACTIVITY' });
  assert.equal(f.state.reads, 0);
});
test('detaching Ability clears context but leaves queries usable', async () => {
  const f = fixture();
  f.plugin.onDetachedFromAbility();
  assert.deepEqual(await f.call('getAdvertisingId', true), { error: 'NO_ACTIVITY' });
  assert.deepEqual(await f.call('authorizationStatus'), { value: 2 });
});
