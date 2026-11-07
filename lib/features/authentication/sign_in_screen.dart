import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/njangi_background.dart';
import '../../core/widgets/njangi_logo.dart';
import '../../core/widgets/njangi_text_field.dart';
import '../../core/widgets/phosphor_icon.dart';
import '../../core/widgets/primary_gradient_button.dart';
import 'auth_controller.dart';

/// Sign In Screen for existing NjangiSave members.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(
    text: '+237 6 70 12 34 56',
  );
  final _passwordController = TextEditingController(text: 'njangi2026');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await ref
        .read(authControllerProvider.notifier)
        .signIn(
          identifier: _identifierController.text,
          password: _passwordController.text,
        );

    if (ok && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: NjangiBackground(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
              const SizedBox(height: 12),
              const NjangiHeroBadge(size: 74, iconSize: 38),
              const SizedBox(height: 18),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: textTheme.displayMedium?.copyWith(
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Welcome ',
                      style: TextStyle(color: AppColors.darkNavy),
                    ),
                    TextSpan(
                      text: 'back',
                      style: TextStyle(color: AppColors.primaryBlue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to monitor your Njangi savings goals.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 28),
              NjangiTextField(
                controller: _identifierController,
                hintText: 'Phone number (+237...) or Email',
                prefixIcon: PhosphorIcons.user,
                textInputAction: TextInputAction.next,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your phone number or email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              NjangiTextField(
                controller: _passwordController,
                hintText: 'Password',
                prefixIcon: PhosphorIcons.lock,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleSignIn(),
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
                  if (val == null || val.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              if (authState.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  authState.errorMessage!,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.errorRed,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryGradientButton(
                label: 'Sign In',
                showTrailingArrow: true,
                isLoading: authState.isLoading,
                onPressed: _handleSignIn,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?  ",
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => context.push('/register'),
                      child: Text(
                        'Create Account',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
