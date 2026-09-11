import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import test from 'node:test';

test('HAR entry resolves to the registered plugin', () => {
  const metadata = JSON.parse(readFileSync('ohos/oh-package.json5', 'utf8'));
  assert.equal(metadata.name, 'advertising_id_flutter');
  const entry = readFileSync(`ohos/${metadata.main}`, 'utf8');
  const relative = entry.match(/from ['"](.+)['"]/)[1];
  assert.ok(existsSync(`ohos/${relative}.ets`), 'export must resolve to a plugin source file');
  const plugin = readFileSync(`ohos/${relative}.ets`, 'utf8');
  const registered = readFileSync('pubspec.yaml', 'utf8').match(/ohos:\s+pluginClass: (\w+)/)[1];
  assert.ok(plugin.includes(`export default class ${registered} `));
});
