import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/njangi_background.dart';
import '../../core/widgets/njangi_logo.dart';
import '../../core/widgets/njangi_text_field.dart';
import '../../core/widgets/phosphor_icon.dart';
import '../../core/widgets/primary_gradient_button.dart';
import 'auth_controller.dart';

/// D. Create Account Screen (Matches Reference Image 1)
///
/// Fields:
/// - Full name
/// - Email address
/// - Telephone number (defaulting to +237)
/// - Password (with visibility toggle)
/// Plus Google & Facebook integration-ready buttons and link to Sign In.
class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedCountryCode = AppConstants.defaultCountryCode;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _formatCameroonPhone(String countryCode, String rawDigits) {
    final cleaned = rawDigits.replaceAll(RegExp(r'\s+'), '');
    if (countryCode == '+237' && cleaned.length == 9) {
      return '$countryCode ${cleaned[0]} ${cleaned.substring(1, 3)} ${cleaned.substring(3, 5)} ${cleaned.substring(5, 7)} ${cleaned.substring(7, 9)}';
    }
    return '$countryCode $cleaned';
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final formattedPhone = _formatCameroonPhone(
      _selectedCountryCode,
      _phoneController.text.trim(),
    );

    final ok = await ref
        .read(authControllerProvider.notifier)
        .registerAccount(
          fullName: _nameController.text,
          email: _emailController.text,
          phoneNumber: formattedPhone,
          password: _passwordController.text,
        );

    if (ok && mounted) {
      context.push('/verify-phone');
    }
  }

  Future<void> _handleSocialAuth(String provider) async {
    final msg = await ref
        .read(authControllerProvider.notifier)
        .initiateOAuthSignIn(provider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkNavy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: NjangiBackground(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back Button Row
              Align(
                alignment: Alignment.centerLeft,
                child: NjangiBackButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/welcome');
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Centered App Badge
              const NjangiHeroBadge(size: 74, iconSize: 38),
              const SizedBox(height: 18),

              // Title: "Create your account"
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: textTheme.displayMedium?.copyWith(
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Create your ',
                      style: TextStyle(color: AppColors.darkNavy),
                    ),
                    TextSpan(
                      text: 'account',
                      style: TextStyle(color: AppColors.primaryBlue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start saving for your Njangi today.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 24),

              // 1. Full name
              NjangiTextField(
                controller: _nameController,
                hintText: 'Full name',
                prefixIcon: PhosphorIcons.user,
                textInputAction: TextInputAction.next,
                validator: (val) {
                  if (val == null || val.trim().length < 2) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 2. Email address
              NjangiTextField(
                controller: _emailController,
                hintText: 'Email address',
                prefixIcon: PhosphorIcons.envelopeSimple,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (val) {
                  final text = val?.trim() ?? '';
                  if (text.isEmpty ||
                      !text.contains('@') ||
                      !text.contains('.')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 3. Telephone number defaulting to +237
              NjangiTextField(
                controller: _phoneController,
                hintText: 'Phone number',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                prefixWidget: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        PhosphorIcons.phone,
                        size: 20,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCountryCode,
                          isDense: true,
                          icon: const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              PhosphorIcons.caretDownBold,
                              size: 13,
                              color: AppColors.darkNavy,
                            ),
                          ),
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.darkNavy,
                            fontWeight: FontWeight.w600,
                          ),
                          items: AppConstants.supportedCountryCodes
                              .map(
                                (code) => DropdownMenuItem(
                                  value: code,
                                  child: Text(code),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCountryCode = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(width: 1, height: 22, color: AppColors.border),
                    ],
                  ),
                ),
                validator: (val) {
                  final digits = (val ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 8) {
                    return 'Please enter a valid phone number (e.g. 670123456)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 4. Create a password
              NjangiTextField(
                controller: _passwordController,
                hintText: 'Create a password',
                prefixIcon: PhosphorIcons.lock,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submitForm(),
                suffixWidget: IconButton(
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? PhosphorIcons.eye
                        : PhosphorIcons.eyeSlash,
                    size: 20,
                    color: AppColors.secondaryText,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Create Account Button
              PrimaryGradientButton(
                label: 'Create Account',
                showTrailingArrow: true,
                isLoading: authState.isLoading,
                onPressed: _submitForm,
              ),
              const SizedBox(height: 22),

              // Divider: "Or continue with"
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'Or continue with',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 18),

              // Google & Facebook Sign-in Buttons
              Row(
                children: [
                  Expanded(
                    child: _SocialAuthButton(
                      label: 'Google',
                      leading: const _GoogleColorBadge(),
                      onTap: () => _handleSocialAuth('Google'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _SocialAuthButton(
                      label: 'Facebook',
                      leading: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1877F2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'f',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                      onTap: () => _handleSocialAuth('Facebook'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Already have an account? Sign in
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?  ',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => context.push('/login'),
                      child: Text(
                        'Sign in',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialAuthButton extends StatelessWidget {
  const _SocialAuthButton({
    required this.label,
    required this.leading,
    required this.onTap,
  });

  final String label;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: 10),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleColorBadge extends StatelessWidget {
  const _GoogleColorBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4285F4),
          height: 1.0,
        ),
      ),
    );
  }
}
