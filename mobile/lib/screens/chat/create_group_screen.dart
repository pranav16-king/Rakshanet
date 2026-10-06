import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/mesh_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/chat_service.dart';
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
  final _customPeerCtrl = TextEditingController();

  final Set<String> _selectedPeers = {};
  final Map<String, String> _customPeers = {}; // deviceId -> displayName
  bool _isCreating = false;

  final List<String> _quickGroupTemplates = const [
    'Family Safe Zone',
    'Sector Relief Squad',
    'Medical & First Aid Team',
    'Shelter Supply Coordination',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _customPeerCtrl.dispose();
    super.dispose();
  }

  void _addCustomMember() {
    final text = _customPeerCtrl.text.trim();
    if (text.isEmpty) return;
    final id = 'PEER-${text.hashCode.abs().toString().padLeft(4, '0').substring(0, 4)}';
    setState(() {
      _customPeers[id] = text;
      _selectedPeers.add(id);
      _customPeerCtrl.clear();
    });
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isCreating = true);

    try {
      final groupService = context.read<GroupService>();
      final chatService = context.read<ChatService>();
      final mesh = context.read<MeshProvider>();

      final namesById = <String, String>{..._customPeers};
      for (final peer in mesh.nearbyDevices) {
        namesById[peer.deviceId] =
            peer.displayName.isNotEmpty ? peer.displayName : peer.deviceId;
      }

      final group = await groupService.createGroup(
        _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        inviteeDeviceIds: _selectedPeers.toList(),
        inviteeNamesById: namesById,
      );

      chatService.setActiveFilter('Group');
      groupService.selectGroup(group.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTokens.beaconTeal,
            content: Text(
              _selectedPeers.isEmpty
                  ? 'Group "${group.name}" created & broadcast to nearby mesh!'
                  : 'Group "${group.name}" created! Invites sent to ${_selectedPeers.length} member(s).',
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
        actions: [
          TextButton.icon(
            onPressed: mesh.isScanning ? null : () => mesh.startScan(),
            icon: Icon(
              Icons.radar_rounded,
              size: 18,
              color: mesh.isScanning ? theme.textMuted : AppTokens.beaconTeal,
            ),
            label: Text(
              mesh.isScanning ? 'Scanning...' : 'Scan Peers',
              style: TextStyle(
                color: mesh.isScanning ? theme.textMuted : AppTokens.beaconTeal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Quick Group Name Templates
              Text(
                'Quick Templates',
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickGroupTemplates.map((tpl) {
                  return ActionChip(
                    backgroundColor: theme.surface,
                    side: BorderSide(color: theme.border),
                    label: Text(
                      tpl,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _nameCtrl.text = tpl;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Group Name Field
              TextFormField(
                controller: _nameCtrl,
                style: TextStyle(color: theme.text),
                decoration: InputDecoration(
                  labelText: 'Group Name *',
                  labelStyle: TextStyle(color: theme.textMuted),
                  hintText: 'e.g. Sector 4 Rescue Team, Family Safe',
                  hintStyle: TextStyle(
                    color: theme.textMuted.withValues(alpha: 0.6),
                  ),
                  prefixIcon: const Icon(
                    Icons.group_add_rounded,
                    color: AppTokens.signalYellow,
                  ),
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
                    borderSide: const BorderSide(
                      color: AppTokens.signalYellow,
                      width: 2,
                    ),
                  ),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Please enter a group name'
                    : null,
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descCtrl,
                style: TextStyle(color: theme.text),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description / Mission (Optional)',
                  labelStyle: TextStyle(color: theme.textMuted),
                  hintText: 'e.g. Coordination for local relief & medical supplies',
                  hintStyle: TextStyle(
                    color: theme.textMuted.withValues(alpha: 0.6),
                  ),
                  prefixIcon: const Icon(
                    Icons.description_outlined,
                    color: AppTokens.beaconTeal,
                  ),
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

              // Manual Member / Peer Invite Input
              Text(
                'Invite Member by Name or Mesh ID',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customPeerCtrl,
                      style: TextStyle(color: theme.text),
                      onSubmitted: (_) => _addCustomMember(),
                      decoration: InputDecoration(
                        hintText: 'Enter responder name or peer ID...',
                        hintStyle: TextStyle(
                          color: theme.textMuted.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: theme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                          borderSide: BorderSide(color: theme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                          borderSide: BorderSide(color: theme.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _addCustomMember,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTokens.beaconTeal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      ),
                    ),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),

              if (_customPeers.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _customPeers.entries.map((entry) {
                    final isSelected = _selectedPeers.contains(entry.key);
                    return FilterChip(
                      selected: isSelected,
                      selectedColor: AppTokens.signalYellow.withValues(alpha: 0.25),
                      checkmarkColor: theme.text,
                      backgroundColor: theme.surface,
                      side: BorderSide(
                        color: isSelected ? AppTokens.signalYellow : theme.border,
                      ),
                      label: Text(
                        '${entry.value} (${entry.key})',
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedPeers.add(entry.key);
                          } else {
                            _selectedPeers.remove(entry.key);
                          }
                        });
                      },
                      onDeleted: () {
                        setState(() {
                          _customPeers.remove(entry.key);
                          _selectedPeers.remove(entry.key);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 24),

              // Peer Invitation Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nearby Mesh Peers (${_selectedPeers.length} invited)',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 15,
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    border: Border.all(color: theme.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.wifi_tethering_rounded,
                        color: AppTokens.beaconTeal,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Group invite will be queued in your Mesh Outbox and automatically broadcast to nearby devices when in range.',
                          style: TextStyle(
                            color: theme.textMuted,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
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
                        peer.displayName.isNotEmpty
                            ? peer.displayName
                            : peer.deviceId,
                        style: TextStyle(
                          color: theme.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'ID: ${peer.deviceId} • Battery: ${peer.batteryLevel}%',
                        style: TextStyle(color: theme.textMuted, fontSize: 12),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 28),

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
                    _isCreating
                        ? 'Creating Group...'
                        : 'Create Group & Broadcast Invites',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
