import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chat_group.dart';
import '../../providers/theme_provider.dart';
import '../../services/chat_service.dart';
import '../../services/group_service.dart';
import '../../theme/app_tokens.dart';

class PendingInvitesScreen extends StatefulWidget {
  const PendingInvitesScreen({super.key});

  @override
  State<PendingInvitesScreen> createState() => _PendingInvitesScreenState();
}

class _PendingInvitesScreenState extends State<PendingInvitesScreen> {
  Future<void> _showJoinByCodeDialog(
    BuildContext context,
    ThemeProvider theme,
    GroupService groupService,
  ) async {
    final codeCtrl = TextEditingController();
    final joinedGroup = await showDialog<ChatGroup>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          side: BorderSide(color: theme.border),
        ),
        title: Text(
          'Join Group by Code or Name',
          style: TextStyle(
            color: theme.text,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a mesh group code (e.g. GRP-NDRF04) or group name shared by a responder:',
              style: TextStyle(color: theme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              autofocus: true,
              style: TextStyle(color: theme.text),
              decoration: InputDecoration(
                hintText: 'e.g. GRP-SEC4 or Sector 4 Relief',
                hintStyle: TextStyle(
                  color: theme.textMuted.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: theme.surfaceSunken,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  borderSide: BorderSide(color: theme.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: theme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.beaconTeal,
              foregroundColor: Colors.white,
              minimumSize: const Size(88, 42),
            ),
            onPressed: () async {
              final text = codeCtrl.text.trim();
              if (text.isEmpty) return;
              final grp = await groupService.joinGroupByCode(
                groupCodeOrName: text,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx, grp);
              }
            },
            child: const Text('Join Group'),
          ),
        ],
      ),
    );

    if (joinedGroup != null && context.mounted) {
      context.read<ChatService>().setActiveFilter('Group');
      groupService.selectGroup(joinedGroup.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTokens.beaconTeal,
          content: Text('Joined "${joinedGroup.name}"!'),
        ),
      );
      Navigator.pop(context);
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final groupService = context.watch<GroupService>();
    final pendingInvites = groupService.pendingInvites;
    final respondedInvites = groupService.respondedInvites;

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.surface,
        elevation: 0,
        title: Text(
          'Group Invitations',
          style: TextStyle(color: theme.text, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.text),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Scan / Receive Mesh Invite',
            icon: const Icon(Icons.wifi_tethering_rounded, color: AppTokens.beaconTeal),
            onPressed: () async {
              final inv = await groupService.createIncomingMeshInvite();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTokens.beaconTeal,
                    content: Text(
                      'Received mesh invite: "${inv.groupName}"',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Top Action Buttons: Join by Code & Scan for Mesh Invites
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.text,
                      side: BorderSide(color: theme.border),
                      minimumSize: const Size(48, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      ),
                    ),
                    icon: const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 18,
                      color: AppTokens.signalYellow,
                    ),
                    label: const Text(
                      'Join by Code',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () => _showJoinByCodeDialog(
                      context,
                      theme,
                      groupService,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTokens.beaconTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(48, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      ),
                    ),
                    icon: const Icon(Icons.radar_rounded, size: 18),
                    label: const Text(
                      'Scan Mesh Invites',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () async {
                      final inv = await groupService.createIncomingMeshInvite();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTokens.beaconTeal,
                            content: Text(
                              'Discovered mesh group invite: "${inv.groupName}"',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section 1: Pending Invitations
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PENDING INVITATIONS (${pendingInvites.length})',
                  style: TextStyle(
                    color: theme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                if (pendingInvites.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.signalYellow.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    ),
                    child: Text(
                      'Action Required',
                      style: TextStyle(
                        color: theme.isLightMode
                            ? AppTokens.lightPrimaryInk
                            : AppTokens.signalYellow,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (pendingInvites.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  border: Border.all(color: theme.border),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTokens.beaconTeal.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        size: 32,
                        color: AppTokens.beaconTeal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Pending Invitations',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap "Scan Mesh Invites" above to discover nearby responder groups or "Join by Code" to enter a group ID.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ...pendingInvites.map((invite) {
                return Card(
                  color: theme.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    side: BorderSide(color: theme.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTokens.signalYellow.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.group_rounded,
                                color: theme.isLightMode
                                    ? AppTokens.lightPrimaryInk
                                    : AppTokens.signalYellow,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    invite.groupName,
                                    style: TextStyle(
                                      color: theme.text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Invited by: ${invite.inviterName} • ${_formatTime(invite.sentAt)}',
                                    style: TextStyle(
                                      color: theme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Group ID: ${invite.groupId}',
                                    style: TextStyle(
                                      color: AppTokens.beaconTeal,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            // Reject / Decline Button
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTokens.sosRed,
                                  side: const BorderSide(color: AppTokens.sosRed),
                                  minimumSize: const Size(48, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                                  ),
                                ),
                                icon: const Icon(Icons.close_rounded, size: 18),
                                label: const Text(
                                  'Reject',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  await groupService.respondToInvite(
                                    invite,
                                    false,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Rejected invitation to "${invite.groupName}"',
                                        ),
                                        action: SnackBarAction(
                                          label: 'Undo (Accept)',
                                          onPressed: () {
                                            groupService.respondToInvite(
                                              invite,
                                              true,
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Accept & Join Button
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTokens.beaconTeal,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  minimumSize: const Size(48, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                                  ),
                                ),
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: const Text(
                                  'Accept & Join',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  await groupService.respondToInvite(
                                    invite,
                                    true,
                                  );
                                  if (context.mounted) {
                                    context
                                        .read<ChatService>()
                                        .setActiveFilter('Group');
                                    groupService.selectGroup(invite.groupId);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppTokens.beaconTeal,
                                        content: Text(
                                          'Accepted & joined "${invite.groupName}"!',
                                        ),
                                      ),
                                    );
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

            // Section 2: Responded Invitations History (Accepted & Rejected)
            if (respondedInvites.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'RESPONDED HISTORY (${respondedInvites.length})',
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              ...respondedInvites.map((invite) {
                final isAccepted = invite.status == GroupMemberStatus.accepted;
                final badgeColor =
                    isAccepted ? AppTokens.beaconTeal : AppTokens.sosRed;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    border: Border.all(color: theme.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isAccepted
                            ? Icons.check_circle_rounded
                            : Icons.cancel_outlined,
                        color: badgeColor,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invite.groupName,
                              style: TextStyle(
                                color: theme.text,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'From: ${invite.inviterName} • ${isAccepted ? "ACCEPTED" : "REJECTED"}',
                              style: TextStyle(
                                color: theme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isAccepted)
                        TextButton(
                          onPressed: () {
                            context.read<ChatService>().setActiveFilter('Group');
                            groupService.selectGroup(invite.groupId);
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Open Chat',
                            style: TextStyle(
                              color: AppTokens.beaconTeal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        TextButton(
                          onPressed: () async {
                            await groupService.respondToInvite(invite, true);
                            if (context.mounted) {
                              context
                                  .read<ChatService>()
                                  .setActiveFilter('Group');
                              groupService.selectGroup(invite.groupId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppTokens.beaconTeal,
                                  content: Text(
                                    'Re-accepted & joined "${invite.groupName}"!',
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Accept Now',
                            style: TextStyle(
                              color: AppTokens.beaconTeal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
