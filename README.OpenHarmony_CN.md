# 鸿蒙接入指南

本实现为 `advertising_id_flutter` 提供 HarmonyOS OAID 支持，基于 TPC 的
`fluttertpc_advertising_id` 鸿蒙代码适配。保留原有 Android、iOS、macOS API。

## 环境与验证状态

- 使用支持 `ohos` 的 Flutter 适配版，随附 Dart 必须满足 `>=3.8.0 <4.0.0`。
  普通 Flutter 可运行 Dart 测试，但不能构建鸿蒙 HAP。
- 需要 DevEco Studio、HarmonyOS SDK、应用签名和具备 Ads Kit 的真机。
- 示例沿用来源项目的 `5.0.0(12)` SDK 配置；这是配置基线，**不是本项目已经验证通过的版本声明**。
- 当前完成 Dart 和宿主侧原生逻辑测试；尚未完成 ArkTS 编译和真机验证。
  不承诺所有 OpenHarmony 发行版都具备 `@kit.AdsKit`。

## 1. 引入插件

当前改动尚未发布，开发阶段使用本地路径，指向本仓库根目录：

```yaml
dependencies:
  advertising_id_flutter:
    path: ../flutter_advertising_id
```

使用鸿蒙 Flutter 执行 `flutter pub get`。插件已经声明 `ohos` 平台，
宿主应使用工具链生成的插件注册文件，不需要手动创建 MethodChannel。

## 2. 声明应用权限

在宿主 `ohos/entry/src/main/module.json5` 的 `module.requestPermissions` 中添加：

```json
{
  "name": "ohos.permission.APP_TRACKING_CONSENT",
  "reason": "$string:tracking_reason",
  "usedScene": {
    "abilities": ["EntryAbility"],
    "when": "inuse"
  }
}
```

将 `EntryAbility` 替换为实际 Ability 名称。在宿主
`ohos/entry/src/main/resources/base/element/string.json` 的 `string` 数组中添加：

```json
{
  "name": "tracking_reason",
  "value": "用于获取广告标识符以提供个性化广告服务"
}
```

用途说明应符合应用实际用途，有多语言资源时一并翻译。权限必须由宿主声明，
仅依赖插件 HAR 不会替应用完成权限配置。

## 3. 调用

```dart
import 'package:advertising_id_flutter/flutter_advertising_id.dart';
import 'package:flutter/services.dart';

final advertisingId = AdvertisingId();

// 不弹出权限申请：没有权限时返回 null。
final existingId = await advertisingId.getAdvertisingId();

// 在前台页面、合适的用户操作之后申请权限。
try {
  final id = await advertisingId.getAdvertisingId(true);
  // id == null 表示拒绝授权或没有有效 OAID；由业务决定后续行为。
} on PlatformException catch (error) {
  // 可根据 error.code 展示错误或记录诊断信息，避免记录广告 ID。
}

// 这两个查询不会申请权限。
final status = await advertisingId.authorizationStatus;
final limited = await advertisingId.limitAdTrackingEnabled;
```

| API | 鸿蒙行为 |
| --- | --- |
| `getAdvertisingId(false)` | 已授权时读取 OAID；否则返回 null，不弹框 |
| `getAdvertisingId(true)` | 必要时使用前台 Ability 请求权限；拒绝返回 null |
| `authorizationStatus` | 已授权为 authorized，未授权为 denied；不区分首次未申请与已拒绝 |
| `limitAdTrackingEnabled` | APP_TRACKING_CONSENT 未授予时为 true，授予时为 false |

限制状态是**当前应用的跟踪权限状态**，不是独立的全局广告跟踪开关。
空 OAID 和全零 OAID 返回 null。插件不缓存 OAID，每次查询重新读取权限。
被拒绝后能否再次弹框由系统控制，应用可提示用户到系统设置修改授权。

| 错误码 | 含义 |
| --- | --- |
| `PERMISSION_ERROR` | 权限查询或申请调用失败；检查权限声明和环境 |
| `NO_ACTIVITY` | 需要申请权限但没有前台 Ability，或申请期间 Ability 被分离 |
| `GET_AD_ID_FAILED` | OAID 服务调用失败 |

三个 API 都可能抛出 PlatformException。权限拒绝本身不抛异常。

## 4. 运行示例

使用鸿蒙 Flutter，在仓库 `example` 目录执行：

```sh
flutter pub get
flutter devices
flutter build hap --debug
flutter run -d <设备ID>
```

首次运行前，在 DevEco Studio 打开 `example/ohos`，配置本机 SDK 和应用签名。
按工具链要求准备 `@ohos/flutter_ohos`；生成的依赖、注册文件及本地签名不提交。
示例提供“不申请读取”“申请授权并读取”“查询状态”三个入口，启动时不会申请权限。

## 5. 测试与验收

仓库根目录：

```sh
flutter test
node --test test/ohos/*.test.mjs
```

示例目录：

```sh
flutter test
```

Node 测试要求 Node 24，直接执行去除类型的插件源码，仅替换系统 SDK 边界。
它验证权限分支、并发和错误行为，**不验证 ArkTS 类型规则、SDK 链接或系统弹框**。

发布前必须补齐真机记录：首次不申请、允许、拒绝、系统撤销、重复调用、
并发申请、无前台 Ability、OAID 重置；同时记录 Flutter/Dart/SDK/IDE/ROM 版本。
来源项目的兼容性列表不等同于本项目的验收结果。
