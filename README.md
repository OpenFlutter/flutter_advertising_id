[![pub package](https://img.shields.io/pub/v/advertising_id_flutter.svg)](https://pub.dartlang.org/packages/advertising_id_flutter)
![Build status](https://github.com/OpenFlutter/flutter_advertising_id/actions/workflows/build_test.yml/badge.svg)
[![GitHub stars](https://img.shields.io/github/stars/OpenFlutter/flutter_advertising_id)](https://github.com/OpenFlutter/fluwx/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/OpenFlutter/flutter_advertising_id)](https://github.com/OpenFlutter/advertising_id_flutter/network)
[![GitHub license](https://img.shields.io/github/license/OpenFlutter/flutter_advertising_id)](https://github.com/OpenFlutter/fluwx/blob/master/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/OpenFlutter/flutter_advertising_id)](https://github.com/OpenFlutter/flutter_advertising_id/issues)
<a target="_blank" href="https://qm.qq.com/q/TJ29rkzywM"><img border="0" src="https://pub.idqqimg.com/wpa/images/group.png" alt="OpenFlutter" title="OpenFlutter"></a>

---

# advertising_id_flutter

A Flutter plugin to access advertising ID.

Wraps [ASIdentifierManager.advertisingIdentifier](https://developer.apple.com/documentation/adsupport/asidentifiermanager/1614151-advertisingidentifier) (on iOS) and [advertising ID](https://developers.google.com/android/reference/com/google/android/gms/ads/identifier/AdvertisingIdClient) (on Android).

## HarmonyOS

HarmonyOS OAID implementation is available in source. See the [中文接入指南](README.OpenHarmony_CN.md) for permissions, API semantics and toolchain requirements. Native build and device validation are still pending.

## Getting Started

Run this command
```
 flutter pub add advertising_id_flutter
```
This will add a line like this to your package's pubspec.yaml

```yaml
dependencies:
  ....
  advertising_id_flutter: ${latestVersion}
```

## Usage


### Get advertising ID.

```dart
String? advertisingId;
// Platform messages may fail, so we use a try/catch PlatformException.
try {
  advertisingId = await AdvertisingId().getAdvertisingId(true);
} on PlatformException {
  advertisingId = null;
}
```

### Get limitAdTrackingEnabled

Retrieves whether the user has limit ad tracking enabled or not.

```dart
bool? isLimitAdTrackingEnabled;
// Platform messages may fail, so we use a try/catch PlatformException.
try {
  isLimitAdTrackingEnabled = await AdvertisingId().limitAdTrackingEnabled;
} on PlatformException {
  isLimitAdTrackingEnabled = false;
}
```

### Get authorizationStatus

Retrieves whether the user has limit ad tracking enabled or not. This is only for iOS. It will always return `AuthorizationStatus.authorized` on Android.

```dart

final authorizationStatus = await AdvertisingId().authorizationStatus;

```

## Star history

![stars](https://starchart.cc/OpenFlutter/flutter_advertising_id.svg)

## LICENSE

    Copyright 2025 OpenFlutter Project

    Licensed to the Apache Software Foundation (ASF) under one or more contributor
    license agreements.  See the NOTICE file distributed with this work for
    additional information regarding copyright ownership.  The ASF licenses this
    file to you under the Apache License, Version 2.0 (the "License"); you may not
    use this file except in compliance with the License.  You may obtain a copy of
    the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
    License for the specific language governing permissions and limitations under
    the License.