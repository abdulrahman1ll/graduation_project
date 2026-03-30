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
  Future<List<chat.Group>> fetchUserGroups(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: userId)
        .get();

    final groups = snapshot.docs
        .map(chat.Group.fromFirestore)
        .toList(growable: false)
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: appBarWithLanguage(
        tr: widget.tr,
        isArabic: widget.isArabic,
        title: widget.tr.t('groups'),
        onToggleLanguage: widget.onToggleLanguage,
      ),
      body: currentUserId == null
          ? const Center(child: Text('Failed to load groups'))
          : FutureBuilder<List<chat.Group>>(
              future: fetchUserGroups(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print(snapshot.error);
                  return const Center(child: Text('Failed to load groups'));
                }

                final groups = snapshot.data ?? const <chat.Group>[];

                if (groups.isEmpty) {
                  return const Center(child: Text('No groups yet'));
                }

                return ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];

                    return ListTile(
                      title: Text(group.name),
                      subtitle: Text(group.description),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                chat.GroupChatPage(groupId: group.id),
                          ),
                        );
                      },
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
                  builder: (_) => const chat.CreateGroupPage(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
