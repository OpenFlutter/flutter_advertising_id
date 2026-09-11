# HarmonyOS Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 TPC 的鸿蒙实现移植到 advertising_id_flutter，保留现有 Dart API，完成权限行为适配与真机验证。

**Architecture:** 在主包增加 ohos 原生平台，复用现有 MethodChannel。以相邻 fluttertpc_advertising_id 仓库的实现为来源，调整通信协议、授权行为和生命周期，不拆独立实现包。

**Tech Stack:** Dart、Flutter 鸿蒙适配版、ArkTS、@ohos/flutter_ohos、@kit.AbilityKit、@kit.AdsKit、DevEco Studio。

**Spec:** 本次对话中的移植方案；下述全局约束是可执行的行为约定。本文是开发计划，尚未执行实现或验证。

## Global Constraints

- 包名 advertising_id_flutter，保留 Dart SDK ^3.8.0；不为旧版鸿蒙 Flutter 降低约束。
- Channel 固定为 dev.openflutter/flutter_advertising_id。
- 不改变 Android、iOS、macOS 的实现，不改变 Dart 公共方法签名。
- 支持范围是具备所需 Ads Kit 能力的 HarmonyOS；不承诺所有 OpenHarmony 发行版。
- 来源：相邻 fluttertpc_advertising_id 仓库，评估时 HEAD 为 8bef9e5；执行前记录完整 SHA。保留移植文件原有版权与许可，注明修改。
- getAdvertisingId(false)：未授权返回 null，不弹框；true：必要时申请权限，拒绝返回 null。
- limitAdTrackingEnabled：只查询，鸿蒙定义为 APP_TRACKING_CONSENT 未授予，不宣称它是独立的系统全局广告开关。
- authorizationStatus：只查询；授予返回 3，未授予返回 2。鸿蒙首期不返回 0 或 1，不自行持久化首次申请状态。
- 权限检查失败抛 PERMISSION_ERROR；缺少可请求权限的 UI 上下文抛 NO_ACTIVITY；OAID 服务失败抛 GET_AD_ID_FAILED。用户拒绝不作为系统错误。
- 不复制签名、缓存、构建输出、机器路径；发布仅在验收通过后另行执行。

## 文件与职责

| 文件 | 变更及职责 |
| --- | --- |
| pubspec.yaml | 增加 ohos 平台注册，更新描述 |
| ohos/index.ets | 导出 FlutterAdvertisingIdPlugin |
| ohos/oh-package.json5 | HAR 包元数据，名称 advertising_id_flutter |
| ohos/build-profile.json5、ohos/hvigorfile.ts | 移植 HAR 构建配置 |
| ohos/src/main/module.json5 | HAR 模块声明 |
| ohos/src/main/ets/components/plugin/FlutterAdvertisingIdPlugin.ets | Channel、权限检查与申请、OAID、生命周期 |
| test/flutter_advertising_id_method_channel_test.dart | 通信协议与返回值、异常测试 |
| test/flutter_advertising_id_test.dart | 公共 API 转发测试 |
| example/ohos/ | 鸿蒙宿主、权限声明与资源 |
| example/lib/main.dart | 手动查询、授权并读取、显示状态与错误 |
| example/integration_test/plugin_integration_test.dart | 去掉错误的“始终返回非空 ID”假设 |
| README.md、lib/flutter_advertising_id.dart、CHANGELOG.md | 平台语义、接入步骤、变更记录 |

## Task 1：确认工具链并锁定通信契约

**Interfaces:** 消费现有 AdvertisingId API；产出三个 Channel 方法的回归测试及可用工具链记录。

- [ ] 记录来源 git rev-parse HEAD、目标工作区 git status --short，保护已有改动。
- [ ] 检查鸿蒙 Flutter 的 flutter --version、flutter doctor -v、flutter build hap --help 和 flutter devices。选择实际 Dart >=3.8.0 且 <4.0.0 的工具链；3.35 系列作为候选，不能仅凭名称判定兼容。
- [ ] 核验目标 SDK 的 Ads Kit、APP_TRACKING_CONSENT、Flutter Ability 生命周期 API。以安装的 SDK 类型声明和对应版本官方文档为准；记录 Flutter/Dart/SDK/IDE/ROM 版本。缺少环境时继续源码任务，但不得标记原生验收完成。
- [ ] 将现有空 MethodChannel 测试改成实际契约测试。必须使用真实 Channel：

```dart
const channel = MethodChannel('dev.openflutter/flutter_advertising_id');
test('forwards explicit authorization request', () async {
  MethodCall? received;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    received = call;
    return 'test-oaid';
  });
  final platform = MethodChannelFlutterAdvertisingId();
  expect(await platform.getAdvertisingId(true), 'test-oaid');
  expect(received!.method, 'getAdvertisingId');
  expect(received!.arguments, true);
});
```

- [ ] 同一测试文件补充默认参数 false、null ID、limitAdTrackingEnabled 的 true/false/null、authorizationStatus 的 0/1/2/3 映射及 PlatformException 透传。每次测试后清理 mock handler；这些测试证明 Dart 契约，不证明原生行为。
- [ ] 运行 flutter test。记录已有失败，避免将旧问题误判为鸿蒙回归；已有实现满足的契约测试可以直接通过。
- [ ] 提交契约测试，提交信息 test: cover advertising ID channel contract。

## Task 2：移植 HAR 并实现权限契约

**Interfaces:** 输入 getAdvertisingId(bool)、limitAdTrackingEnabled、authorizationStatus；输出 String?/bool?/int 或约定的 PlatformException。

- [ ] 复制来源 ohos/ 六个源码与配置文件；将 AdvertisingIdPlugin.ets 重命名为 FlutterAdvertisingIdPlugin.ets，统一类名、导出和 getUniqueClassName。
- [ ] 在 pubspec.yaml 的现有 platforms 下追加：

```yaml
      ohos:
        pluginClass: FlutterAdvertisingIdPlugin
```

- [ ] 将 HAR 和模块名改为 advertising_id_flutter；Channel 改为 dev.openflutter/flutter_advertising_id；保留来源许可，清理模板描述。
- [ ] 将 isLimitAdTrackingEnabled 方法名适配为 limitAdTrackingEnabled，补 authorizationStatus。核心决策固定为：

```text
authorizationStatus -> check permission -> granted ? 3 : 2
limitAdTrackingEnabled -> check permission -> !granted
getAdvertisingId -> check permission
  denied and argument != true -> success(null)
  denied and argument == true -> request permission using attached UI ability
  still denied -> success(null)
  granted -> identifier.getOAID() -> empty/all-zero ID becomes null
```

- [ ] 将权限检查和权限申请分开；移除查询方法中的 requestPermissionsFromUser，移除 finally return 吞异常，以及跨调用共享的 isLimitAdTrackingEnabled 字段。
- [ ] 使用目标 Flutter embedding 支持的 Ability 生命周期提供 UI 上下文，替代 getContext(this)。无 UI 上下文时只拒绝需要弹框的调用，允许纯查询。
- [ ] 用一个正在进行的授权 Promise 合并并发授权请求，并在 finally 清理；每次读取使用本次权限检查结果。
- [ ] 卸载时解除 Channel handler、清理上下文；异步操作仅完成一次结果，不继续使用已卸载的 UI 上下文。未知方法继续 result.notImplemented()。
- [ ] 使用 Task 3 的宿主运行构建并修复 ArkTS 类型错误；在真机验证两个查询不弹框、false 不弹框、true 可授权。未完成原生构建前不将该任务认定为通过。
- [ ] 提交实现，提交信息 feat: add HarmonyOS advertising ID implementation。

## Task 3：提供可验证的鸿蒙宿主

**Interfaces:** 消费 Task 2 的插件注册和三个 API；产出可构建运行的 example/ohos 和手动验收入口。本任务的宿主搭建可在 Task 2 编译验证前完成。

- [ ] 使用已选工具链在临时目录生成插件示例宿主，迁入 example/ohos；参考 TPC 的构建和权限配置，不覆盖现有其他平台目录。
- [ ] 确认自动插件注册引用 advertising_id_flutter，清除旧 advertising_id 包引用；由工具链生成依赖文件，不手写机器绝对路径。
- [ ] 在 example/ohos/entry/src/main/module.json5 增加应用权限，并在资源 string.json 中增加 tracking_reason：

```json
{
  "name": "ohos.permission.APP_TRACKING_CONSENT",
  "reason": "$string:tracking_reason",
  "usedScene": { "abilities": ["EntryAbility"], "when": "inuse" }
}
```

- [ ] 示例增加“读取 ID（不申请）”“申请授权并读取”“查询状态”三个按钮，分别调用 getAdvertisingId(false)、getAdvertisingId(true) 和两个 getter。展示 null、枚举、限制状态和 PlatformException.code；启动时不申请权限。
- [ ] 将 integration test 中 getPlatformVersion 命名和强制非空断言改为广告 ID 场景；允许未授权 null。授权弹框和系统设置切换由明确的真机步骤验证，不用 mock 声称覆盖系统 UI。
- [ ] 在 example 执行 flutter pub get、flutter build hap --debug；签名在本机配置，运行 flutter run -d <flutter devices 返回的设备 ID>。
- [ ] 提交示例，提交信息 feat: add HarmonyOS example and permission setup。

## Task 4：回归、文档与交付

**Interfaces:** 消费可运行示例；产出测试记录、接入文档和可评审改动。

- [ ] 完成以下真机矩阵，每项记录实际返回值、是否弹框和测试版本：

| 场景 | 预期 |
| --- | --- |
| 首次安装，读取 false | null，不弹框 |
| 首次安装，两个状态 getter | denied/true，不弹框 |
| 读取 true，用户允许 | 返回有效 OAID，之后 authorized/false |
| 读取 true，用户拒绝 | null，之后 denied/true |
| 系统设置撤销权限后回到应用 | 查询立即反映撤销，false 返回 null |
| 已授权后重复读取 | 不重复弹框 |
| 两个并发授权请求 | 最多一个在途申请，两次调用各结束一次 |
| 无前台 Ability 且需要申请 | NO_ACTIVITY，不挂起 |
| SDK 调用失败或声明配置错误 | 返回约定错误，不误报用户拒绝 |
| OAID 重置 | 后续读取不使用插件缓存；记录设备实际行为 |

- [ ] 根目录运行 flutter analyze、flutter test；example 运行 flutter analyze、flutter test。新问题必须修复，已有问题单独记录。
- [ ] 使用常规 Flutter 工具链验证 pub get 和现有平台测试，确认新增 ohos 元数据未影响使用；在现有 CI/可用环境执行 Android 构建、iOS 无签名构建及 macOS 构建。环境不可用项明确列为未验证。
- [ ] README 记录鸿蒙工具链版本、宿主权限配置、三个 API 的平台语义、失败行为和真机结果；Dart 注释说明权限未授予时 null、系统失败可能抛 PlatformException。
- [ ] CHANGELOG 增加鸿蒙支持记录；不自动发布或宣称未经验证的平台兼容。
- [ ] 执行 git diff --check，检查产物无签名、缓存、绝对路径与无关修改；提交文档及验证修正，提交信息 docs: document HarmonyOS support and validation。

## 完成标准与估算

- 三个公共 API 在选定鸿蒙真机上可调用，行为符合全局约束；拒绝授权是正常结果。
- 实际鸿蒙 HAP 构建通过，记录工具链和真机版本；Dart mock 测试不能替代该标准。
- 常规平台回归完成或明确披露未验证项，用户能够按 README 配置示例。
- 环境齐全时预计 2–4 个工作日：契约/环境 0.5 天，移植 0.5–1 天，示例与原生调试 0.5–1 天，回归文档 0.5–1.5 天。工具链安装、签名和设备等待另计。

## 计划自检

- 已覆盖：包注册、Channel 差异、缺少的方法、授权参数、只读查询、错误语义、生命周期、并发、许可保留、宿主配置、工具链约束和回归。
- 原生 SDK 的具体生命周期签名须在 Task 1 对所选 SDK 核验；本计划不冒充已编译通过的 ArkTS 代码。
- 实施可以在当前会话逐项推进；涉及提交时遵守实际沙箱与仓库权限。

## 执行记录（2026-09-11）

- 工作分支：codex/harmonyos-support；源码及文档已落地，未提交或发布。
- 来源完整 SHA：8bef9e53f153db64dc7f935f065acfd299150599。
- 已完成：主包注册、ArkTS 移植、权限语义、示例宿主与 UI、中文接入文档 README.OpenHarmony_CN.md、CI 测试入口。
- TDD 证据：原 TPC false 调用触发 1 次申请（期望 0）；新实现通过。示例不申请读取、显式授权、状态查询、异常展示均先观察失败后实现；HAR 旧名称/导出路径由注册测试发现后修复。
- 已通过：根包 15 项测试，示例 4 项测试，Node 原生逻辑/注册 11 项测试；根包与示例 flutter analyze 无问题。
- Node 测试执行实际 ArkTS 类去除类型后的代码，替代 SDK 边界；不代表 ArkTS 类型检查、原生链接或真机权限弹框通过。
- 工具链：官方 Flutter 3.47.2 / Dart 3.13.2；当前未找到 DevEco/HarmonyOS SDK。flutter build hap --debug 失败，不能作为鸿蒙构建环境。
- 待完成：选定鸿蒙 Flutter/SDK 上编译 HAP、签名与真机验收矩阵。不得将来源项目版本列表当成本项目的验证结果。
- 方案调整：无法用本机工具链生成鸿蒙宿主，因此移植来源项目中受版本控制的宿主文件，排除原始测试模板、签名、缓存与构建产物。

- 常规平台回归：Android debug APK、iOS --no-codesign、macOS release 构建均通过。官方 Flutter 构建过程中自动迁移了 Apple 工程；验证后已还原这些无关配置变更及依赖锁文件。
