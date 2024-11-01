import 'dart:io';
import 'package:desktop_entry/Models/desktop_entry_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../custom_list_tile.dart';
import '../main_controller.dart';

class CreateNewEntryPage extends ConsumerStatefulWidget {
  const CreateNewEntryPage({super.key});

  @override
  ConsumerState createState() => _CreateNewEntryPageState();
}

class _CreateNewEntryPageState extends ConsumerState<CreateNewEntryPage> {
  final nameController = TextEditingController();
  final execController = TextEditingController();
  final iconController = TextEditingController();
  void _createDesktopEntry(DesktopEntryActions actions) {
    if (nameController.text.isNotEmpty &&
        execController.text.isNotEmpty &&
        iconController.text.isNotEmpty) {
      final name = nameController.text;
      final execPath = execController.text;
      final iconPath = iconController.text;
      final entry = '''[Desktop Entry]
      Name=$name
        Exec=$execPath
        Icon=$iconPath
        Type=Application
        Categories=Internet;FileTransfer;
        Comment=$name
        Terminal=false
        ''';
      final homeDirectory = Platform.environment['HOME'];
      if (homeDirectory == null) {
        throw Exception('Could not locate the user home directory.');
      }

     // final homeDirectory = Directory.current.parent.parent.path;
      File('$homeDirectory/.local/share/applications/$name.desktop')
          .writeAsStringSync(entry);
      final newDesktopEntry = DesktopEntryModel()
        ..appName = name
        ..iconPath = iconPath
        ..executablePath = execPath
        ..isDeleted = false;
      actions.addEntry(newDesktopEntry);

      nameController.clear();
      execController.clear();
      iconController.clear();
      Navigator.pop(context);
    } else {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              icon: const CircleAvatar(
                backgroundColor: Colors.yellowAccent,
                child: Icon(
                  Icons.warning_amber_rounded,
                ),
              ),
              title: const Text('Warning'),
              content: const Text('Fill All Fields'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'))
              ],
            );
          });
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        iconController.text = image.path;
      });
    }
  }

  Future<String?> pickExecutable() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['AppImage', 'deb', 'sh', 'bin', 'py', 'pl']);

    if (result != null) {
      return result.files.single.path!;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = ref.read(desktopEntryActionsProvider);
    final ThemeData theme = Theme.of(context);
    final bool isLightMode = theme.brightness == Brightness.light;
    return Scaffold(
      appBar: AppBar(title: const Text('Create Desktop Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomListTile(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'App Name')),
              ),
            ),
            CustomListTile(
              child: ListTile(
                title: TextButton.icon(
                    onPressed: () async {
                      final path = await pickExecutable();
                      if (path != null) {
                        setState(() {
                          execController.text = path;
                        });
                      }
                    },
                    label: const Text('Select Executable')),
                subtitle: TextField(
                    controller: execController,
                    decoration:
                        const InputDecoration(labelText: 'Executable Path')),
              ),
            ),
            CustomListTile(
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CustomListTile(
                      color: !isLightMode
                          ? theme.colorScheme.onInverseSurface
                          : theme.colorScheme.inversePrimary,
                      child: TextButton.icon(
                        onPressed: () async {
                          pickImage();
                        },
                        label: const Text('Select Icon'),
                        icon: const Icon(Icons.image),
                      ),
                    ),
                  ),
                  if (iconController.text.isNotEmpty)
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Stack(children: [
                          Image.file(File(iconController.text)),
                          IconButton.filledTonal(
                              onPressed: () {
                                setState(() {
                                  iconController.clear();
                                });
                              },
                              icon: const Icon(Icons.close))
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: CustomListTile(
          child: TextButton(
            onPressed: () {
              _createDesktopEntry(actions);
            },
            child: const Text('Create Entry'),
          ),
        ),
      ),
    );
  }
}
