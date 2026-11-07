import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/services/platform_file_service.dart';
import '../../core/widgets/njangi_background.dart';
import '../../core/widgets/phosphor_icon.dart';
import '../authentication/auth_controller.dart';
import '../savings_goals/goals_controller.dart';

/// Profile & Settings Screen matching exact UI reference (Image 4):
/// - "Profile & Settings" header
/// - Personal info card with "NE" light blue avatar, name, phone, email & pencil icon
/// - Section 1: "Account & notifications" (Sample demo mode, Push notifications, SMS reminders)
/// - Section 2: "Security & payments" (Biometric / app lock, Fapshi payment gateway)
/// - Section 3: "Legal & support" (Terms & conditions, Privacy policy, Help & support)
/// - Centered blue "Log out" button with signOut icon
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _pushNotifications = true;
  bool _smsReminders = true;
  bool _biometricLock = true;

  Future<void> _pickAvatarBytes() async {
    final fileService = ref.read(platformFileServiceProvider);
    final picked = await fileService.pickImageOrDocumentBytes(
      allowedExtensions: const ['png', 'jpg', 'jpeg'],
    );
    if (picked == null || !mounted) return;

    ref
        .read(authControllerProvider.notifier)
        .updateProfile(avatarBytes: picked.bytes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Updated profile photo (${picked.name}).'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    final user = ref.read(authControllerProvider).user;
    final nameCtrl = TextEditingController(
      text: user?.fullName ?? 'Ngwa Emmanuel',
    );
    final emailCtrl = TextEditingController(
      text: user?.email ?? 'emmanuel.ngwa@njangiva.com',
    );
    final phoneCtrl = TextEditingController(
      text: user?.phoneNumber ?? '+237 6 70 12 34 56',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Personal Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone number'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email address'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            fullName: nameCtrl.text.trim(),
            email: emailCtrl.text.trim(),
            phoneNumber: phoneCtrl.text.trim(),
          );
    }
  }

  void _showInfoDialog(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final goalsState = ref.watch(goalsControllerProvider);
    final user = authState.user;

    final userName = user?.fullName.isNotEmpty == true
        ? user!.fullName
        : 'Ngwa Emmanuel';
    final userPhone = user?.phoneNumber.isNotEmpty == true
        ? user!.phoneNumber
        : '+237 6 70 12 34 56';
    final userEmail = user?.email.isNotEmpty == true
        ? user!.email
        : 'emmanuel.ngwa@njangiva.com';

    return NjangiBackground(
      maxContentWidth: 620,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Title
            const Text(
              'Profile & Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.darkNavy,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),

            // Profile Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickAvatarBytes,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.lightBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: user?.avatarBytes != null
                            ? ClipOval(
                                child: Image.memory(
                                  user!.avatarBytes!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Text(
                                'NE',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userPhone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _showEditProfileDialog,
                    icon: const Icon(
                      PhosphorIcons.pencilSimple,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Section 1: Account & notifications
            const Text(
              'Account & notifications',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildSwitchRow(
                    icon: PhosphorIcons.stack,
                    title: 'Sample demonstration mode',
                    subtitle: 'Show sample goals alongside live balances',
                    value: goalsState.isSampleDataMode,
                    onChanged: (v) => ref
                        .read(goalsControllerProvider.notifier)
                        .setSampleDataMode(v),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),
                  _buildSwitchRow(
                    icon: PhosphorIcons.bell,
                    title: 'Push notifications',
                    subtitle: 'Deposit confirmations and maturity alerts',
                    value: _pushNotifications,
                    onChanged: (v) => setState(() => _pushNotifications = v),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),
                  _buildSwitchRow(
                    icon: PhosphorIcons.chatCircleDots,
                    title: 'SMS reminders',
                    subtitle: 'Weekly reminders before your Njangi is due',
                    value: _smsReminders,
                    onChanged: (v) => setState(() => _smsReminders = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Section 2: Security & payments
            const Text(
              'Security & payments',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildSwitchRow(
                    icon: PhosphorIcons.lock,
                    title: 'Biometric / app lock',
                    subtitle: 'Require verification when opening Njangiva',
                    value: _biometricLock,
                    onChanged: (v) => setState(() => _biometricLock = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Section 3: Legal & support
            const Text(
              'Legal & support',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildNavRow(
                    icon: PhosphorIcons.fileText,
                    title: 'Terms & conditions',
                    subtitle: null,
                    onTap: () {
                      _showInfoDialog(
                        'Terms & Conditions',
                        'Njangiva helps you save gradually for upcoming contributions. '
                            'Deposits are held safely and restricted until your selected due date according to platform rules.',
                      );
                    },
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),
                  _buildNavRow(
                    icon: PhosphorIcons.shieldCheck,
                    title: 'Privacy policy',
                    subtitle: null,
                    onTap: () {
                      _showInfoDialog(
                        'Privacy Policy',
                        'We value your privacy and encrypt all user credentials, transaction logs, and telephone numbers.',
                      );
                    },
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),
                  _buildNavRow(
                    icon: PhosphorIcons.question,
                    title: 'Help & support',
                    subtitle: null,
                    onTap: () {
                      _showInfoDialog(
                        'Help & Support',
                        'Support Email: support@njangiva.com\n'
                            'Phone: +237 6 70 12 34 56\n'
                            'Available Monday to Saturday, 8am – 6pm.',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // Log Out Button (Centered Blue Action)
            Center(
              child: InkWell(
                onTap: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/welcome');
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        PhosphorIcons.signOut,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Log out',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primaryBlue),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: AppColors.primaryBlue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primaryBlue),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              PhosphorIcons.caretRight,
              size: 16,
              color: AppColors.secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}
