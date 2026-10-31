import 'dart:io';

import 'package:etabli_atelier/fs/workspace_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temp;
  late WorkspaceStore store;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('atelier-workspace-test-');
    store = WorkspaceStore.at(
      await Directory('${temp.path}/workspace').create(),
    );
  });
  tearDown(() => temp.delete(recursive: true));

  test('nested files survive edits, moves and reopening', () async {
    await store.writeText('data/input.csv', 'a,b\n1,2');
    await store.writeText('data/input.csv', 'a,b\n3,4');
    await store.rename('data/input.csv', 'output.csv');
    await store.move('data/output.csv', 'results');
    final reopened = WorkspaceStore.at(store.root);
    expect(await reopened.readText('results/output.csv'), 'a,b\n3,4');
    expect(await reopened.exists('data/input.csv'), isFalse);
    expect(
      (await reopened.list()).any((e) => e.relPath.contains('.write-')),
      isFalse,
    );
  });

  test(
    'invalid paths cannot read, write or delete outside the workspace',
    () async {
      final sentinel = File('${temp.path}/keep.txt');
      await sentinel.writeAsString('preserve');
      for (final path in [
        '../keep.txt',
        'a/../../keep.txt',
        '/keep.txt',
        '.',
        '',
        r'C:\keep.txt',
      ]) {
        await expectLater(
          store.writeText(path, 'overwrite'),
          throwsArgumentError,
        );
        await expectLater(store.delete(path), throwsArgumentError);
      }
      expect(await sentinel.readAsString(), 'preserve');
    },
  );

  test('symlinks cannot expose files outside the workspace', () async {
    final outside = await Directory('${temp.path}/outside').create();
    await File('${outside.path}/secret').writeAsString('preserve');
    await Link('${store.root.path}/linked').create(outside.path);
    await expectLater(
      store.writeText('linked/secret', 'changed'),
      throwsA(isA<FileSystemException>()),
    );
    expect(
      () => store.readText('linked/secret'),
      throwsA(isA<FileSystemException>()),
    );
    expect(await store.list(), isEmpty);
    expect(await File('${outside.path}/secret').readAsString(), 'preserve');
  });

  test('rename and import collisions preserve both files', () async {
    await store.writeText('one.txt', 'first');
    await store.writeText('two.txt', 'second');
    await expectLater(
      store.rename('one.txt', 'two.txt'),
      throwsA(isA<FileSystemException>()),
    );
    final external = File('${temp.path}/two.txt');
    await external.writeAsString('external');
    await expectLater(
      store.importFile(external.path),
      throwsA(isA<FileSystemException>()),
    );
    expect(await store.readText('one.txt'), 'first');
    expect(await store.readText('two.txt'), 'second');
    await store.createDir('folder/sub');
    await expectLater(store.move('folder', 'folder/sub'), throwsArgumentError);
  });
}
