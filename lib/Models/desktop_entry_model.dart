import 'package:isar/isar.dart';

part 'desktop_entry_model.g.dart';
@collection
class DesktopEntryModel {
  Id? id;
  late String appName;
  late String executablePath;
  late String iconPath;
  late bool isDeleted; // false
}