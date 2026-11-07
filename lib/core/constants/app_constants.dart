/// Core application constants and default market settings for Njangiva.
abstract final class AppConstants {
  static const String appName = 'Njangiva';
  static const String tagline = 'Save. Prepare. Contribute.';
  static const String coreMessage =
      'Save little by little today, so you are financially ready when your Njangi contribution is due.';

  /// Brand image assets
  static const String logoSymbolAsset =
      'assets/images/njangiva_symbol_transparent.png';
  static const String coinStackAsset =
      'assets/images/Glossy Red Logo Coin Stack.png';

  /// Default market settings (Cameroon)
  static const String defaultCurrency = 'FCFA';
  static const String defaultIsoCurrency = 'XAF';
  static const String defaultCountryCode = '+237';
  static const List<String> supportedCountryCodes = [
    '+237',
    '+234',
    '+225',
    '+221',
    '+33',
    '+1',
  ];

  /// Minimum savings goal and deposit amounts in FCFA
  static const int minGoalAmountFcfa = 5000;
  static const int minDepositAmountFcfa = 100; // Fapshi minimum is 100 XAF

  /// Backend & Fapshi environment configuration
  /// Note: Never embed Fapshi API secrets (`FAPSHI_API_KEY`) in the Flutter binary.
  /// All authenticated Fapshi requests pass through the Njangiva / AfroDocs backend.
  static const String defaultApiBaseUrl = String.fromEnvironment(
    'NJANGISAVE_API_BASE_URL',
    defaultValue: 'https://afrodocs.app',
  );

  static const String fapshiEnvironment = String.fromEnvironment(
    'FAPSHI_ENV',
    defaultValue: 'sandbox',
  );

  static const String fapshiSandboxBaseUrl = 'https://sandbox.fapshi.com';
  static const String fapshiProductionBaseUrl = 'https://live.fapshi.com';

  /// Gentle polling configuration (reusing AfroDocs' proven Fapshi rate-limit fix:
  /// 3 attempts spaced by 10 seconds after a 3-second initial delay so webhooks
  /// handle instant crediting without triggering Fapshi HTTP 429 errors).
  static const int fapshiMaxPollAttempts = 3;
  static const Duration fapshiInitialPollDelay = Duration(seconds: 3);
  static const Duration fapshiPollInterval = Duration(seconds: 10);
}
