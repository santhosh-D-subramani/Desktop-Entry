
import 'dart:io';

import 'package:desktop_entry/Models/desktop_entry_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import 'main.dart';


final desktopEntryListProvider = StreamProvider.family<List<DesktopEntryModel>, bool>((ref, isDeleted) {

  return isar.desktopEntryModels
      .filter()
      .isDeletedEqualTo(isDeleted)
      .watch(fireImmediately: true);
});

final desktopEntryActionsProvider = Provider((ref) => DesktopEntryActions(ref));

class DesktopEntryActions {
  DesktopEntryActions(this.ref);
  final Ref ref;

  Future<void> addEntry(DesktopEntryModel entry) async {
    await isar.writeTxn(() async {
      await isar.desktopEntryModels.put(entry);
    });
    ref.invalidate(desktopEntryListProvider(false));
  }

  Future<void> deleteEntry(String appName) async {
    await isar.writeTxn(() async {
      final entry = await isar.desktopEntryModels.filter().appNameEqualTo(appName).findFirst();
      if (entry != null) {
        entry.isDeleted = true;
        await isar.desktopEntryModels.put(entry);
      }
    });
    ref.invalidate(desktopEntryListProvider(false));
    ref.invalidate(desktopEntryListProvider(true));
  }

  Future<void> restoreEntry(DesktopEntryModel desktopEntryModel, int id) async {
    final entry = '''[Desktop Entry]
      Name=${desktopEntryModel.appName}
        Exec=${desktopEntryModel.executablePath}
        Icon=${desktopEntryModel.iconPath}
        Type=Application
        Categories=Internet;FileTransfer;
        Comment=${desktopEntryModel.appName}
        Terminal=false
        ''';
    final homeDirectory =
        Directory.current.parent.parent.path;
    File('$homeDirectory/.local/share/applications/${desktopEntryModel.appName}.desktop')
        .writeAsStringSync(entry);
    await isar.writeTxn(() async {
      final entry = await isar.desktopEntryModels.get(id);
      if (entry != null) {
        entry.isDeleted = false;
        await isar.desktopEntryModels.put(entry);
      }
    });
    ref.invalidate(desktopEntryListProvider(false));
    ref.invalidate(desktopEntryListProvider(true));
  }
}
