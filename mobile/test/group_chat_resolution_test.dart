import 'package:flutter_test/flutter_test.dart';
import 'package:rakshanet_mobile/models/chat_group.dart';
import 'package:rakshanet_mobile/models/chat_message.dart';
import 'package:rakshanet_mobile/models/message_envelope.dart';
import 'package:rakshanet_mobile/services/chat_service.dart';
import 'package:rakshanet_mobile/services/group_service.dart';
import 'package:rakshanet_mobile/services/database_service.dart';
import 'package:rakshanet_mobile/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await AppDatabase.instance.delete('groups');
    await AppDatabase.instance.delete('group_members');
    await AppDatabase.instance.delete('group_invites');
    await AppDatabase.instance.delete('messages');
  });

  group('Group Chat & Name Resolution Tests', () {
    test('Envelope serialization preserves conv_id for group messages', () {
      const groupConvId = 'CONV_GRP-2D53EAB';
      final env = MessageEnvelope(
        uuid: 'MSG-001',
        senderId: 'DEV-A',
        senderName: 'Alice',
        conversationId: groupConvId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        payload: 'We are safe here',
      );

      final json = env.toJson();
      expect(json['conv_id'], equals(groupConvId));
      expect(json['sender_id'], equals('DEV-A'));
      expect(json['sender_name'], equals('Alice'));
      expect(json['payload'], equals('We are safe here'));
    });

    test('joinGroupByCode recovers real name from welcome message or invite', () async {
      final groupService = GroupService();

      // Create a group
      const realName = 'Shelter Supply Coordination';
      final createdGroup = await groupService.createGroup(
        realName,
        description: 'Coordinating emergency relief supplies at shelter',
      );

      expect(createdGroup.name, equals(realName));
      expect(createdGroup.id.startsWith('GRP-'), isTrue);

      // Now join using the group code
      final joinedGroup = await groupService.joinGroupByCode(
        groupCodeOrName: createdGroup.id,
      );

      // Must resolve the real created name, not "Mesh Group (GRP-XXXX)"!
      expect(joinedGroup.name, equals(realName));
    });

    test('joinGroupByCode accepts raw hex code without GRP- prefix', () async {
      final groupService = GroupService();
      const realName = 'Family Safe Zone';
      final createdGroup = await groupService.createGroup(realName);
      final rawCode = createdGroup.id.replaceFirst('GRP-', '');

      final joined = await groupService.joinGroupByCode(groupCodeOrName: rawCode);
      expect(joined.id, equals(createdGroup.id));
      expect(joined.name, equals(realName));
    });
  });
}
