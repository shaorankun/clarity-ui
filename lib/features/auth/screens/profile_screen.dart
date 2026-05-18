import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../rooms/providers/room_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Avatar
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user?.displayName.isNotEmpty == true
                        ? user!.displayName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 36,
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Name & email
              Text(user?.displayName ?? 'User',
                  style: const TextStyle(fontSize: 22,
                      fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(user?.email ?? '',
                  style: const TextStyle(color: AppColors.textSecondary,
                      fontSize: 14)),

              const SizedBox(height: 32),

              // Settings list
              _SettingsSection(
                title: 'Account',
                items: [
                  _SettingsItem(
                    icon: Icons.person_outline,
                    label: 'Display Name',
                    trailing: user?.displayName ?? '',
                    onTap: null,
                  ),
                  _SettingsItem(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    trailing: user?.email ?? '',
                    onTap: null, // read only
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _SettingsSection(
                title: 'About',
                items: [
                  _SettingsItem(
                    icon: Icons.info_outline,
                    label: 'Version',
                    trailing: '1.0.0',
                    onTap: null,
                  ),
                  _SettingsItem(
                    icon: Icons.code,
                    label: 'Built with Flutter & Spring Boot',
                    trailing: '',
                    onTap: null,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Logout button
              GestureDetector(
                onTap: () => _confirmLogout(context, auth),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.danger.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout, color: AppColors.danger, size: 20),
                      SizedBox(width: 8),
                      Text('Log Out',
                          style: TextStyle(color: AppColors.danger,
                              fontWeight: FontWeight.w600, fontSize: 16)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Log Out?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('You will be signed out of your account.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Leave room trước khi logout
              await context.read<RoomProvider>().leaveRoom();
              await auth.logout();
            },
            child: const Text('Log Out',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// ── Settings Section ──────────────────────────────────────
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title.toUpperCase(),
              style: const TextStyle(color: AppColors.textMuted,
                  fontSize: 11, fontWeight: FontWeight.w600,
                  letterSpacing: 1.2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (i < items.length - 1)
                    const Divider(
                        height: 1, color: AppColors.surfaceLight,
                        indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(label,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing.isNotEmpty)
            Text(trailing,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 18),
          ],
        ],
      ),
    );
  }
}