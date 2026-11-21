// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:yummealprep/app_services.dart';
import 'package:yummealprep/data/choice_list_repository.dart';
import 'package:yummealprep/utils/search.dart';
import 'package:yummealprep/utils/ui.dart';
import 'package:yummealprep/widgets/empty_state.dart';

/// Search, add, rename and remove the side dishes or drinks offered in the
/// meal form.
class ManageChoicesScreen extends StatefulWidget {
  const ManageChoicesScreen({required this.list, super.key});

  final ChoiceList list;

  @override
  State<ManageChoicesScreen> createState() => _ManageChoicesScreenState();
}

class _ManageChoicesScreenState extends State<ManageChoicesScreen> {
  late final ChoiceListRepository _choices = AppScope.of(
    context,
  ).choices(widget.list);
  late final Stream<List<String>> _names = _choices.watch();
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = await _askForName(title: 'Add ${widget.list.singular}');
    if (name == null) return;
    await _choices.add([name]);
  }

  Future<void> _rename(String name) async {
    final renamed = await _askForName(
      title: 'Rename ${widget.list.singular}',
      initial: name,
    );
    if (renamed == null || renamed == name) return;
    final meals = await _choices.rename(name, renamed);
    if (!mounted || meals == 0) return;
    showMessage(
      context,
      'Also renamed in $meals ${meals == 1 ? 'meal' : 'meals'}',
    );
  }

  Future<void> _remove(String name) async {
    final remove = await confirm(
      context,
      title: 'Remove $name?',
      // Meals are left alone, so removing a name never changes a meal.
      message:
          'It will no longer be offered when you add a meal. Meals that '
          'already have it keep it.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (remove) await _choices.remove(name);
  }

  Future<String?> _askForName({required String title, String? initial}) =>
      showDialog<String>(
        context: context,
        builder: (context) => _NameDialog(title: title, initial: initial),
      );

  @override
  Widget build(BuildContext context) {
    final label = widget.list.label;
    return Scaffold(
      appBar: AppBar(title: Text('Manage ${label.toLowerCase()}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text('Add ${widget.list.singular}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              controller: _search,
              hintText: 'Search ${label.toLowerCase()}',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<String>>(
              stream: _names,
              builder: (context, snapshot) {
                final all = snapshot.data;
                if (all == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final query = _search.text.trim();
                final names = all
                    .where((name) => matchesQuery(query, [name]))
                    .toList();
                if (names.isEmpty) {
                  return EmptyState(
                    message: query.isEmpty
                        ? 'No ${label.toLowerCase()} yet.'
                        : 'Nothing matches "$query".',
                    showImage: false,
                  );
                }
                return ListView.separated(
                  // Room for the add button and the navigation bar.
                  padding: EdgeInsets.only(
                    bottom: 96 + MediaQuery.paddingOf(context).bottom,
                  ),
                  itemCount: names.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final name = names[index];
                    return ListTile(
                      title: Text(name),
                      onTap: () => _rename(name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Rename',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _rename(name),
                          ),
                          IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _remove(name),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, this.initial});

  final String title;
  final String? initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Name'),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
