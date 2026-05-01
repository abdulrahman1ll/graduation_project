// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> migrateGroupMembersToTripMembers({bool dryRun = true}) async {
  final firestore = FirebaseFirestore.instance;

  print(
    'Starting migration: groups.members -> trips/{tripId}/members '
    '(dryRun: $dryRun)',
  );

  try {
    final groupsSnapshot = await firestore.collection('groups').get();
    print('Found ${groupsSnapshot.docs.length} group(s).');

    var createdCount = 0;
    var skippedCount = 0;
    var errorCount = 0;

    for (final groupDoc in groupsSnapshot.docs) {
      final groupId = groupDoc.id;

      try {
        final data = groupDoc.data();
        final tripId = (data['tripId'] ?? '').toString().trim();

        if (tripId.isEmpty) {
          skippedCount++;
          print('Skipping group $groupId: missing tripId.');
          continue;
        }

        final rawMembers = data['members'];
        if (rawMembers is! List || rawMembers.isEmpty) {
          skippedCount++;
          print('Skipping group $groupId: members array is missing or empty.');
          continue;
        }

        final memberIds = rawMembers
            .map((member) => member.toString().trim())
            .where((memberId) => memberId.isNotEmpty)
            .toSet()
            .toList(growable: false);

        if (memberIds.isEmpty) {
          skippedCount++;
          print('Skipping group $groupId: no valid member IDs.');
          continue;
        }

        print(
          'Processing group $groupId -> trip $tripId '
          '(${memberIds.length} member(s)).',
        );

        for (final userId in memberIds) {
          final memberRef = firestore
              .collection('trips')
              .doc(tripId)
              .collection('members')
              .doc(userId);

          try {
            if (dryRun) {
              final existingMember = await memberRef.get();
              if (existingMember.exists) {
                skippedCount++;
                print('DRY RUN skip: trip $tripId member $userId exists.');
                continue;
              }

              print('DRY RUN create: trip $tripId member $userId.');
              createdCount++;
              continue;
            }

            final didCreate = await firestore.runTransaction<bool>((
              transaction,
            ) async {
              final existingMember = await transaction.get(memberRef);
              if (existingMember.exists) {
                return false;
              }

              transaction.set(memberRef, <String, dynamic>{
                'userId': userId,
                'status': 'pending',
                'joinedAt': FieldValue.serverTimestamp(),
              });
              return true;
            });

            if (didCreate) {
              createdCount++;
              print('Created: trip $tripId member $userId.');
            } else {
              skippedCount++;
              print('Skipped: trip $tripId member $userId already exists.');
            }
          } catch (error, stackTrace) {
            errorCount++;
            print(
              'Error processing member $userId for group $groupId '
              'and trip $tripId: $error',
            );
            print(stackTrace);
          }
        }
      } catch (error, stackTrace) {
        errorCount++;
        print('Error processing group $groupId: $error');
        print(stackTrace);
      }
    }

    print(
      'Migration finished. Created: $createdCount, '
      'skipped: $skippedCount, errors: $errorCount, dryRun: $dryRun.',
    );
  } catch (error, stackTrace) {
    print('Migration failed while reading groups: $error');
    print(stackTrace);
  }
}
