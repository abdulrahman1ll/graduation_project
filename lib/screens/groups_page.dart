part of 'app_shell.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({
    super.key,
    required this.tr,
    required this.isArabic,
    required this.onToggleLanguage,
  });

  final Tr tr;
  final bool isArabic;
  final VoidCallback onToggleLanguage;

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final GroupService _groupService = GroupService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWithLanguage(
        tr: widget.tr,
        isArabic: widget.isArabic,
        title: widget.tr.t('groups'),
        onToggleLanguage: widget.onToggleLanguage,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('groups').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            logFirestoreReadError('groups', error);
            if (error is FirebaseException &&
                error.code == 'permission-denied') {
              return Center(child: Text(widget.tr.t('permission_denied')));
            }
            if (error is FirebaseException) {
              final link = extractIndexLink(error.message);
              if (link != null) {
                return const Center(
                  child: Text('Groups query requires a Firestore index.'),
                );
              }
            }
            return Center(child: Text(widget.tr.t('load_error')));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.groups, size: 72, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text(
                      widget.tr.t('no_groups_yet'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.tr.t('groups_empty_subtitle'),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              return Card(
                child: ListTile(
                  title: Text((data['name'] ?? '').toString()),
                  subtitle: Text((data['description'] ?? '').toString()),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer<RoleProvider>(
        builder: (context, provider, child) {
          final canCreate =
              provider.roles['groupOrganizer'] == true ||
              provider.roles['admin'] == true;
          if (!canCreate) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('New Group'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AddGroupPage(tr: widget.tr, groupService: _groupService),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AddGroupPage extends StatefulWidget {
  const AddGroupPage({super.key, required this.tr, required this.groupService});

  final Tr tr;
  final GroupService groupService;

  @override
  State<AddGroupPage> createState() => _AddGroupPageState();
}

class _AddGroupPageState extends State<AddGroupPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _saving = false;
  String _visibility = 'public';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Group')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Group Name'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _visibility,
            items: const [
              DropdownMenuItem(value: 'public', child: Text('Public')),
              DropdownMenuItem(value: 'private', child: Text('Private')),
            ],
            onChanged: _saving
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _visibility = value);
                    }
                  },
            decoration: const InputDecoration(labelText: 'Visibility'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save Group'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.tr.t('fill_all_fields'))));
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.groupService.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        visibility: _visibility,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        showFirestoreError(context, e);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(widget.tr.t('save_failed'))));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}


