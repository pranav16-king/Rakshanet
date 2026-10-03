import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/mesh_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/group_service.dart';
import '../../theme/app_tokens.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final Set<String> _selectedPeers = {};
  bool _isCreating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isCreating = true);

    try {
      final groupService = context.read<GroupService>();
      final group = await groupService.createGroup(
        _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        inviteeDeviceIds: _selectedPeers.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTokens.beaconTeal,
            content: Text(
              'Group "${group.name}" created! Invites sent to ${_selectedPeers.length} peer(s).',
            ),
          ),
        );
        Navigator.pop(context, group);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTokens.sosRed,
            content: Text('Failed to create group: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final mesh = context.watch<MeshProvider>();
    final availablePeers = mesh.nearbyDevices;

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.surface,
        elevation: 0,
        title: Text(
          'Create Mesh Group',
          style: TextStyle(color: theme.text, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Group Name Field
              TextFormField(
                controller: _nameCtrl,
                style: TextStyle(color: theme.text),
                decoration: InputDecoration(
                  labelText: 'Group Name *',
                  labelStyle: TextStyle(color: theme.textMuted),
                  hintText: 'e.g. Sector 4 Rescue Team, Family Safe',
                  hintStyle: TextStyle(color: theme.textMuted.withValues(alpha: 0.6)),
                  prefixIcon: const Icon(Icons.group_add_rounded, color: AppTokens.signalYellow),
                  filled: true,
                  fillColor: theme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    borderSide: BorderSide(color: theme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    borderSide: BorderSide(color: theme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    borderSide: const BorderSide(color: AppTokens.signalYellow, width: 2),
                  ),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Please enter a group name' : null,
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descCtrl,
                style: TextStyle(color: theme.text),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: TextStyle(color: theme.textMuted),
                  hintText: 'e.g. Coordination for local relief & supplies',
                  hintStyle: TextStyle(color: theme.textMuted.withValues(alpha: 0.6)),
                  prefixIcon: const Icon(Icons.description_outlined, color: AppTokens.beaconTeal),
                  filled: true,
                  fillColor: theme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    borderSide: BorderSide(color: theme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    borderSide: BorderSide(color: theme.border),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Peer Invitation Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invite Nearby Peers (${_selectedPeers.length} selected)',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${availablePeers.length} in range',
                    style: TextStyle(color: theme.textMuted, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (availablePeers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    border: Border.all(color: theme.border),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.wifi_tethering_off_rounded, color: theme.textMuted, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        'No physical peers in range right now',
                        style: TextStyle(color: theme.text, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You can still create the group now. Peers can join later via mesh broadcasts.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else
                ...availablePeers.map((peer) {
                  final isChecked = _selectedPeers.contains(peer.deviceId);
                  return Card(
                    color: theme.surface,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      side: BorderSide(
                        color: isChecked ? AppTokens.signalYellow : theme.border,
                        width: isChecked ? 1.5 : 1.0,
                      ),
                    ),
                    child: CheckboxListTile(
                      activeColor: AppTokens.signalYellow,
                      checkColor: AppTokens.lightOnPrimary,
                      value: isChecked,
                      onChanged: (bool? val) {
                        setState(() {
                          if (val == true) {
                            _selectedPeers.add(peer.deviceId);
                          } else {
                            _selectedPeers.remove(peer.deviceId);
                          }
                        });
                      },
                      secondary: CircleAvatar(
                        backgroundColor: AppTokens.beaconTeal.withValues(alpha: 0.2),
                        child: Text(
                          peer.displayName.isNotEmpty
                              ? peer.displayName[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            color: AppTokens.beaconTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        peer.displayName.isNotEmpty ? peer.displayName : peer.deviceId,
                        style: TextStyle(color: theme.text, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'ID: ${peer.deviceId} • Battery: ${peer.batteryLevel}%',
                        style: TextStyle(color: theme.textMuted, fontSize: 12),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                height: AppTokens.buttonPrimary,
                child: ElevatedButton.icon(
                  onPressed: _isCreating ? null : _handleCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.signalYellow,
                    foregroundColor: AppTokens.lightOnPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    ),
                  ),
                  icon: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTokens.lightOnPrimary,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    _isCreating ? 'Creating Group...' : 'Create Group & Broadcast Invites',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
