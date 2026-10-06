import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/emergency_design_tokens.dart';
import 'app_bar_actions.dart';

/// 1. Compact Sticky Header for Safety & Survival Tools (64dp height, zero truncation, no logo).
class SafetyHeader extends StatelessWidget {
  final int batteryLevel;
  final VoidCallback onBack;
  final VoidCallback onOpenProfile;

  const SafetyHeader({
    super.key,
    required this.batteryLevel,
    required this.onBack,
    required this.onOpenProfile,
  });

  Color _batteryColor() {
    if (batteryLevel <= 0) return AppColors.textSecondary;
    if (batteryLevel > 50) return AppColors.success;
    if (batteryLevel >= 20) return AppColors.primaryAmber;
    return AppColors.danger;
  }

  IconData _batteryIcon() {
    if (batteryLevel <= 0) return Icons.battery_std_rounded;
    if (batteryLevel < 20) return Icons.battery_alert_rounded;
    if (batteryLevel < 50) return Icons.battery_3_bar_rounded;
    return Icons.battery_full_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final batColor = _batteryColor();

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          bottom: BorderSide(color: theme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 44x44dp Back Button
          Semantics(
            button: true,
            label: 'Back',
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.bgAlt,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: theme.border),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: theme.text,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Non-truncated Header Title
          Expanded(
            child: Text(
              'Safety & Survival',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.text,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),

          // Compact Real-Time Battery Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.bgAlt,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: theme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_batteryIcon(), size: 16, color: batColor),
                const SizedBox(width: 5),
                Text(
                  batteryLevel > 0 ? '$batteryLevel%' : '--%',
                  style: TextStyle(
                    color: batColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Theme Toggle Button
          const ThemeToggleButton(compact: true),
          const SizedBox(width: 4),

          // Compact 44x44dp Profile / Status Button
          Semantics(
            button: true,
            label: 'Emergency Profile',
            child: InkWell(
              onTap: onOpenProfile,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.bgAlt,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: theme.border),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: theme.text,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2. Compact Offline Readiness Banner (72–88dp height).
class OfflineReadinessBanner extends StatelessWidget {
  final bool isOnline;
  final bool isMeshActive;

  const OfflineReadinessBanner({
    super.key,
    required this.isOnline,
    required this.isMeshActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final String subtitleText = isOnline
        ? 'Essential survival tools operate offline; cloud sync is currently active.'
        : 'Essential tools remain available without internet.';

    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: AppElevation.card,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.32),
              ),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.success,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'OFFLINE SURVIVAL MODE',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.38),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.circle,
                            size: 6,
                            color: AppColors.success,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'READY OFFLINE',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitleText,
                  style: TextStyle(
                    color: theme.textMuted,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 3. Reusable Section Header with Title and Subtitle.
class ToolSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const ToolSection({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// 4. Compact Quick Action Row (76–86dp height tiles for immediate emergency access).
class QuickActionRow extends StatelessWidget {
  final VoidCallback onFirstAid;
  final VoidCallback onEmergencyNumbers;
  final VoidCallback onIAmSafe;
  final VoidCallback onAlerts;
  final int activeAlertCount;

  const QuickActionRow({
    super.key,
    required this.onFirstAid,
    required this.onEmergencyNumbers,
    required this.onIAmSafe,
    required this.onAlerts,
    required this.activeAlertCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              color: theme.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildCompactTile(
                theme: theme,
                icon: Icons.medical_services_outlined,
                label: 'First Aid',
                accent: AppColors.sosRed,
                onTap: onFirstAid,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactTile(
                theme: theme,
                icon: Icons.phone_in_talk_outlined,
                label: 'Numbers',
                accent: AppColors.blue,
                onTap: onEmergencyNumbers,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactTile(
                theme: theme,
                icon: Icons.verified_user_outlined,
                label: 'I Am Safe',
                accent: AppColors.success,
                onTap: onIAmSafe,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactTile(
                theme: theme,
                icon: Icons.notifications_none_rounded,
                label: 'Alerts',
                accent: AppColors.primaryAmber,
                badgeCount: activeAlertCount,
                onTap: onAlerts,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactTile({
    required ThemeProvider theme,
    required IconData icon,
    required String label,
    required Color accent,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          constraints: const BoxConstraints(minHeight: 78),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: theme.border),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: accent),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (badgeCount > 0)
                Positioned(
                  top: 0,
                  right: 2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.sosRed,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
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

/// 5. Distinct Emergency Communication Action Card for "I Am Safe" (Section 14).
class SafetyStatusAction extends StatelessWidget {
  final bool isMeshActive;
  final bool isOnline;
  final VoidCallback onTap;

  const SafetyStatusAction({
    super.key,
    required this.isMeshActive,
    required this.isOnline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final List<String> activeChannels = [];
    if (isMeshActive) activeChannels.add('Mesh (BLE / Wi-Fi)');
    if (isOnline) activeChannels.add('Internet');
    final String channelText = activeChannels.isNotEmpty
        ? 'Channels: ${activeChannels.join(' • ')}'
        : 'Stored locally for mesh relay';

    return Semantics(
      button: true,
      label: 'I Am Safe. Broadcast your safe status.',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'I Am Safe',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Broadcast your safe status',
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      channelText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  'Send',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
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

/// 6. Compact 2-Column Survival Tool Card (~138–152dp height, zero wasted vertical space).
class SurvivalToolCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color semanticColor;
  final String? statusText;
  final VoidCallback onTap;

  const SurvivalToolCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.semanticColor,
    this.statusText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Semantics(
      button: true,
      label: '$title. $description',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          constraints: const BoxConstraints(minHeight: 136),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: theme.border,
              width: 1,
            ),
            boxShadow: AppElevation.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: semanticColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: semanticColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(icon, size: 22, color: semanticColor),
                  ),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: theme.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.text,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
              if (statusText != null) ...[
                const SizedBox(height: 6),
                Text(
                  statusText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: semanticColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 7. Horizontal Relief & Response Operation Card (80–94dp height).
class ReliefOperationCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color semanticColor;
  final VoidCallback onTap;

  const ReliefOperationCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.semanticColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Semantics(
      button: true,
      label: '$title. $description',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          constraints: const BoxConstraints(minHeight: 82),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: theme.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: semanticColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: semanticColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(icon, size: 22, color: semanticColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 8. Dedicated Disaster Alerts Card driven by real application alert count (Section 15).
class DisasterAlertCard extends StatelessWidget {
  final int activeAlertCount;
  final VoidCallback onTap;

  const DisasterAlertCard({
    super.key,
    required this.activeAlertCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final bool hasAlerts = activeAlertCount > 0;
    final Color badgeColor =
        hasAlerts ? AppColors.primaryAmber : theme.textMuted;
    final String badgeText =
        hasAlerts ? '$activeAlertCount active' : 'No active alerts';

    return Semantics(
      button: true,
      label: 'Disaster Alerts. Emergency warnings and updates. $badgeText.',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          constraints: const BoxConstraints(minHeight: 82),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: hasAlerts
                  ? AppColors.primaryAmber.withValues(alpha: 0.45)
                  : theme.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryAmber.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryAmber.withValues(alpha: 0.32),
                  ),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 22,
                  color: AppColors.primaryAmber,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Disaster Alerts',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.text,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: badgeColor.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Emergency warnings & updates',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 9. Highlighted Offline AI Survival Assistant Card (Section 12).
class OfflineAIAssistantCard extends StatelessWidget {
  final VoidCallback onTap;

  const OfflineAIAssistantCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Semantics(
      button: true,
      label:
          'Offline AI Survival Assistant. Step-by-step guidance for emergency situations. Available Offline.',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: AppColors.aiPurple.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: AppElevation.card,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.aiPurple.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.aiPurple.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: AppColors.aiPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Offline AI Survival Assistant',
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: AppColors.cyan.withValues(alpha: 0.38),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: AppColors.cyan,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Available Offline',
                                style: TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Step-by-step guidance for emergency situations.',
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
