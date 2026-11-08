import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:etabli_atelier/fs/workspace_export.dart';
import 'package:etabli_atelier/fs/workspace_store.dart';

void main() {
  late Directory temp;
  late WorkspaceStore store;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('atelier-export-');
    store = WorkspaceStore.at(temp);
  });
  tearDown(() async => temp.delete(recursive: true));
  test('export preserves binary content and original file', () async {
    final bytes = Uint8List.fromList([0, 255, 10, 128, 34]);
    await store.writeBytes('results/plot.bin', bytes);
    final data = await prepareWorkspaceExport(store, 'results/plot.bin');
    expect(data.name, 'plot.bin');
    expect(data.bytes, bytes);
    expect(await store.readBytes('results/plot.bin'), bytes);
  });
  test('missing and escaped sources do not produce an export', () async {
    await expectLater(
      prepareWorkspaceExport(store, 'missing.R'),
      throwsA(isA<FileSystemException>()),
    );
    await expectLater(
      prepareWorkspaceExport(store, '../outside.R'),
      throwsArgumentError,
    );
  });
  test('export cannot follow a workspace symlink', () async {
    await Link('${temp.path}/linked.R').create('/etc/hosts');
    await expectLater(
      prepareWorkspaceExport(store, 'linked.R'),
      throwsA(isA<FileSystemException>()),
    );
  });
}
