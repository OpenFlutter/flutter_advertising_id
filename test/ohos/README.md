# Host-side HarmonyOS tests

Run from the repository root with Node 24:

```sh
node --test test/ohos/*.test.mjs
```

`plugin.test.mjs` executes the actual plugin class after stripping TypeScript
annotations and imports. Only Flutter/AbilityKit/AdsKit boundaries are replaced.
This is not an ArkTS compiler, HarmonyOS runtime, or device integration test.
`registration.test.mjs` checks the HAR export resolves to the registered plugin.

To reproduce the original TPC permission regression, point `OHOS_PLUGIN_SOURCE`
at its `AdvertisingIdPlugin.ets` and run with
`--test-name-pattern='false does not request'`. The original implementation
requests permission once although the request argument is false.

Source baseline: fluttertpc_advertising_id commit
`8bef9e53f153db64dc7f935f065acfd299150599`.

Embedding interfaces were checked against the public engine source:
https://gitee.com/openharmony-sig/flutter_engine/tree/master/shell/platform/ohos/flutter_embedding/flutter
(`index.ets`, `AbilityAware.ets`, `MethodCall.ets`). A selected SDK build remains required.
