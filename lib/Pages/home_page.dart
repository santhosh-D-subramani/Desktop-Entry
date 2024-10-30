import 'dart:io';

import 'package:desktop_entry/isar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../custom_list_tile.dart';
import '../main_controller.dart';
import 'create_desktop_entry.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final PageController _pageController = PageController(initialPage: 0);

  void _deleteDesktopEntry(DesktopEntryActions actions, String appName) {
    final homeDirectory = Directory.current.parent.parent.path;
    final filePath =
        '$homeDirectory/.local/share/applications/$appName.desktop';

    final file = File(filePath);
    if (file.existsSync()) {
      file.deleteSync();
    }
    actions.deleteEntry(appName);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _pageController.jumpToPage(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final desktopEntries = ref.watch(desktopEntryListProvider(false));
    final deletedEntries = ref.watch(desktopEntryListProvider(true));
    final actions = ref.read(desktopEntryActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Desktop Entry'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tooltip(
                message: 'All Entries',
                child: Tab(icon: Icon(Icons.cloud_outlined))),
            Tooltip(message: 'Deleted', child: Tab(icon: Icon(Icons.delete))),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return const CreateNewEntryPage();
          }));
        },
        child: const Icon(Icons.add),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          _tabController.animateTo(index);
        },
        children: [
          desktopEntries.when(
            data: (entries) {
              if (entries.isEmpty) {
                return const Center(child: Text('No Desktop Entries created.'));
              }
              return ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return CustomListTile(
                    child: ListTile(
                      leading: entry.iconPath.isNotEmpty
                          ? Image.file(File(entry.iconPath))
                          : const Placeholder(),
                      title: Text(entry.appName,
                          style: Theme.of(context).textTheme.headlineLarge),
                      subtitle: Text(entry.executablePath),
                      trailing: IconButton(
                        onPressed: () =>
                            _deleteDesktopEntry(actions, entry.appName),
                        icon: const Icon(Icons.delete),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
          deletedEntries.when(
            data: (entries) {
              if (entries.isEmpty) {
                return const Center(child: Text('No Deleted Entries.'));
              }
              return ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return CustomListTile(
                    child: ListTile(
                      leading: entry.iconPath.isNotEmpty
                          ? Image.file(File(entry.iconPath))
                          : const Placeholder(),
                      title: Text(entry.appName,
                          style: Theme.of(context).textTheme.headlineLarge),
                      subtitle: Text(entry.executablePath),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => actions.restoreEntry(entry,entry.id!),
                            icon: const Icon(Icons.restore),
                          ),
                          IconButton(
                            onPressed: () =>
                                IsarService.deleteDesktopEntry(entry.id!),
                            icon: const Icon(Icons.delete_forever),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ],
      ),
    );
  }
}

