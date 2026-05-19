import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/kashta_colors.dart';
import '../../../core/utils/firestore_utils.dart';
import '../../../core/utils/localization.dart';
import '../../groups/models/group.dart';
import '../../groups/services/group_service.dart';
import '../services/trip_service.dart';

class AddTripPage extends StatefulWidget {
  const AddTripPage({
    super.key,
    required this.tr,
    required this.isArabic,
    this.linkedGroupId,
  });

  final Tr tr;
  final bool isArabic;
  final String? linkedGroupId;

  @override
  State<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends State<AddTripPage> {
  final TripService _tripService = TripService();
  final GroupService _groupService = GroupService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _mapLinkController = TextEditingController();

  String? _selectedGroupId;
  DateTime? _tripDateTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = _emptyToNull(widget.linkedGroupId);
    _titleController.addListener(_refreshPreview);
    _locationNameController.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _titleController
      ..removeListener(_refreshPreview)
      ..dispose();
    _descriptionController.dispose();
    _locationNameController
      ..removeListener(_refreshPreview)
      ..dispose();
    _mapLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.tr;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final selectedTripDateTime = _tripDateTime;

    return Scaffold(
      appBar: AppBar(title: Text(tr.t('add_trip'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: tr.t('trip_name')),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: tr.t('description')),
              maxLines: 2,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            if (currentUserId == null)
              Text(tr.t('sign_in_select_group'))
            else
              StreamBuilder<List<Group>>(
                stream: _groupService.watchUserGroups(currentUserId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    logFirestoreReadError('groups', snapshot.error);
                    return Text(tr.t('load_error'));
                  }

                  final groups = snapshot.data ?? const <Group>[];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue:
                            _hasSelectedGroup(groups) ? _selectedGroupId : null,
                        items: groups
                            .map(
                              (group) => DropdownMenuItem<String>(
                                value: group.id,
                                child: Text(
                                  group.name.trim().isEmpty
                                      ? tr.t('untitled_group')
                                      : group.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: _saving
                            ? null
                            : (value) {
                                setState(() => _selectedGroupId = value);
                              },
                        decoration: InputDecoration(
                          labelText: tr.t('select_group'),
                        ),
                      ),
                      if (groups.isEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          tr.t('link_group_later'),
                          style: TextStyle(
                            color:
                                KashtaColors.textDark.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationNameController,
              decoration: InputDecoration(labelText: tr.t('location_name')),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mapLinkController,
              decoration: InputDecoration(
                labelText: tr.t('map_link_optional'),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickDateTime,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                selectedTripDateTime == null
                    ? tr.t('choose_date_time')
                    : _formatDateTime(selectedTripDateTime, tr),
              ),
            ),
            const SizedBox(height: 16),
            if (currentUserId == null)
              _TripPreview(
                tr: tr,
                title: _titleController.text.trim(),
                dateTime: _tripDateTime,
                groupName: '',
              )
            else
              StreamBuilder<List<Group>>(
                stream: _groupService.watchUserGroups(currentUserId),
                builder: (context, snapshot) {
                  return _TripPreview(
                    tr: tr,
                    title: _titleController.text.trim(),
                    dateTime: _tripDateTime,
                    groupName: _groupNameForSelection(
                      snapshot.data ?? const <Group>[],
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(tr.t('create_trip')),
              style: FilledButton.styleFrom(
                backgroundColor: KashtaColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _tripDateTime ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (selectedDate == null || !mounted) {
      return;
    }

    final currentTripDateTime = _tripDateTime;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: currentTripDateTime == null
          ? TimeOfDay.fromDateTime(now)
          : TimeOfDay.fromDateTime(currentTripDateTime),
    );
    if (selectedTime == null || !mounted) {
      return;
    }

    setState(() {
      _tripDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  Future<void> _save() async {
    final tr = widget.tr;
    final linkedGroupId = _selectedGroupId?.trim() ?? '';
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final tripDateTime = _tripDateTime;
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _locationNameController.text.trim().isEmpty ||
        tripDateTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr.t('fill_all_fields'))));
      return;
    }

    setState(() => _saving = true);
    try {
      final tripId = await _tripService.createTrip(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        locationName: _locationNameController.text.trim(),
        mapLink: _mapLinkController.text.trim(),
        tripDate: tripDateTime,
      );

      if (linkedGroupId.isNotEmpty && userId.isNotEmpty) {
        await _groupService.linkChecklistToGroup(
          groupId: linkedGroupId,
          tripId: tripId,
          userId: userId,
        );
        await _tripService.syncGroupMembersToTrip(
          groupId: linkedGroupId,
          tripId: tripId,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        showFirestoreError(context, e, tr: widget.tr);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr.t('save_failed'))));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  bool _hasSelectedGroup(List<Group> groups) {
    final selected = _selectedGroupId;
    return selected != null && groups.any((group) => group.id == selected);
  }

  String _groupNameForSelection(List<Group> groups) {
    final selected = _selectedGroupId;
    if (selected == null) {
      return '';
    }
    for (final group in groups) {
      if (group.id == selected) {
        return group.name.trim().isEmpty
            ? widget.tr.t('untitled_group')
            : group.name;
      }
    }
    return '';
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}

class _TripPreview extends StatelessWidget {
  const _TripPreview({
    required this.tr,
    required this.title,
    required this.dateTime,
    required this.groupName,
  });

  final Tr tr;
  final String title;
  final DateTime? dateTime;
  final String groupName;

  @override
  Widget build(BuildContext context) {
    final previewDateTime = dateTime;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KashtaColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KashtaColors.sandBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr.t('preview'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _PreviewLine(
            icon: Icons.route_outlined,
            text: title.isEmpty ? tr.t('trip_name') : title,
          ),
          const SizedBox(height: 8),
          _PreviewLine(
            icon: Icons.event_outlined,
            text: previewDateTime == null
                ? tr.t('date_time')
                : _formatDateTime(previewDateTime, tr),
          ),
          const SizedBox(height: 8),
          _PreviewLine(
            icon: Icons.groups_outlined,
            text: groupName.isEmpty ? tr.t('no_group_selected') : groupName,
          ),
        ],
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: KashtaColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

String _formatDateTime(DateTime value, Tr tr) {
  final months = <String>[
    tr.t('jan'),
    tr.t('feb'),
    tr.t('mar'),
    tr.t('apr'),
    tr.t('may'),
    tr.t('jun'),
    tr.t('jul'),
    tr.t('aug'),
    tr.t('sep'),
    tr.t('oct'),
    tr.t('nov'),
    tr.t('dec'),
  ];
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour < 12 ? tr.t('am') : tr.t('pm');
  return '${value.day} ${months[value.month - 1]} - $hour:$minute $period';
}
