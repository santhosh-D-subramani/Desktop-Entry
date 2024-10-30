import 'package:desktop_entry/Models/desktop_entry_model.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'main.dart';

class IsarService {
  static Future<void> initializeDB() async {
    final dir = await getApplicationDocumentsDirectory();
    if (Isar.instanceNames.isEmpty) {
      isar = await Isar.open(
        [DesktopEntryModelSchema],
        directory: dir.path,
      );
    }
  }
  static Future<void> deleteDesktopEntry(int entryId) async {
    await isar.writeTxn(() async {
      await isar.desktopEntryModels.delete(entryId);
    });
  }
}