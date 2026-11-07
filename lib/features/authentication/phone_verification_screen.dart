import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/njangi_background.dart';
import '../../core/widgets/njangi_logo.dart';
import '../../core/widgets/primary_gradient_button.dart';
import 'auth_controller.dart';

/// E. Phone Verification Screen (Matches Reference Image 2)
///
/// Headline: "Verify your phone"
/// Description: "Enter the 6-digit code we sent to +237 6 70 12 34 56."
/// Includes 6 OTP digit boxes, countdown timer ("Resend in 54s"), resend action,
/// and Verify button backed by the mock OTP verification service.
class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 54;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes.first.requestFocus();
      }
    });
  }

  void _startCountdown([int initialSeconds = 54]) {
    _timer?.cancel();
    setState(() => _secondsRemaining = initialSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentOtp => _controllers.map((e) => e.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste of full 6-digit OTP
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < 6 && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      if (digits.length >= 6) {
        _focusNodes.last.unfocus();
      }
      setState(() {});
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _handleVerify() async {
    var otp = _currentOtp;
    // Convenience in prototype/dev mode: if user taps Verify while empty,
    // auto-fill demo OTP 123456 so testing is smooth.
    if (otp.isEmpty) {
      const demoCode = '123456';
      for (var i = 0; i < 6; i++) {
        _controllers[i].text = demoCode[i];
      }
      otp = demoCode;
      setState(() {});
    }

    final ok = await ref
        .read(authControllerProvider.notifier)
        .verifyPhoneOtp(otp);

    if (ok && mounted) {
      context.go('/home');
    }
  }

  void _handleResendCode() {
    if (_secondsRemaining > 0) return;
    _startCountdown(54);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'A new 6-digit verification code (123456) has been sent.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: NjangiBackground(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Column(
          children: [
            // Back Button
            Align(
              alignment: Alignment.centerLeft,
              child: NjangiBackButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/register');
                  }
                },
              ),
            ),
            const SizedBox(height: 18),

            // Phone + SMS Bubble Hero Badge
            const NjangiPhoneVerifyBadge(size: 82),
            const SizedBox(height: 22),

            // Headline: "Verify your phone"
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: textTheme.displayMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
                children: const [
                  TextSpan(
                    text: 'Verify your ',
                    style: TextStyle(color: AppColors.darkNavy),
                  ),
                  TextSpan(
                    text: 'phone',
                    style: TextStyle(color: AppColors.primaryBlue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Description with phone number in bold navy
            Text(
              'Enter the 6-digit code we sent to',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${authState.pendingPhone}.',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 30),

            // 6-digit OTP Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: index == 0 || index == 5 ? 2 : 4,
                    ),
                    child: SizedBox(
                      height: 60,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        style: textTheme.headlineMedium?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkNavy,
                        ),
                        cursorColor: AppColors.primaryBlue,
                        cursorWidth: 2,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: AppColors.inputFill,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                              width: 1.3,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primaryBlue,
                              width: 2.0,
                            ),
                          ),
                        ),
                        onChanged: (v) => _onDigitChanged(index, v),
                        onSubmitted: (_) {
                          if (index == 5) _handleVerify();
                        },
                      ),
                    ),
                  ),
                );
              }),
            ),

            if (authState.errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                authState.errorMessage!,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: AppColors.errorRed),
              ),
            ],
            const SizedBox(height: 24),

            // Resend countdown row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive the code?  ",
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                MouseRegion(
                  cursor: _secondsRemaining == 0
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: GestureDetector(
                    onTap: _secondsRemaining == 0 ? _handleResendCode : null,
                    child: Text(
                      _secondsRemaining > 0
                          ? 'Resend in ${_secondsRemaining}s'
                          : 'Resend Code',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Verify Button
            PrimaryGradientButton(
              label: 'Verify',
              showTrailingArrow: true,
              isLoading: authState.isLoading,
              onPressed: _handleVerify,
            ),
            const SizedBox(height: 16),

            // Dev Helper Hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Dev Mode: Enter any 6 digits (e.g. 123456) or tap Verify directly.',
                textAlign: TextAlign.center,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
