import 'package:flutter/widgets.dart';

/// Provides localized strings for the application.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[Locale('es'), Locale('en')];

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'appTitle': 'Brownbook',
      'loginTitle': 'Sign in',
      'loginSubtitle': 'Choose a language and continue with Google.',
      'signInWithGoogle': 'Sign in with Google',
      'signInError': 'Unable to sign in. Please try again.',
      'signingIn': 'Signing in...',
      'signOut': 'Sign out',
      'signingOut': 'Signing out...',
      'languageLabel': 'Language',
      'welcomeTitle': 'Welcome!',
      'welcomeBody': 'You are now signed in to Brownbook.',
      'welcomeCardTitle': "Here's what you can do next:",
      'welcomeFeature1': 'Organize your books with custom shelves.',
      'welcomeFeature2': 'Capture notes and highlights instantly.',
      'welcomeFeature3': 'Invite teammates to collaborate securely.',
      'getStarted': 'Get started',
      'loading': 'Loading...',
    },
    'es': {
      'appTitle': 'Brownbook',
      'loginTitle': 'Iniciar sesión',
      'loginSubtitle': 'Elige un idioma y continúa con Google.',
      'signInWithGoogle': 'Iniciar sesión con Google',
      'signInError': 'No se pudo iniciar sesión. Inténtalo de nuevo.',
      'signingIn': 'Iniciando sesión...',
      'signOut': 'Cerrar sesión',
      'signingOut': 'Cerrando sesión...',
      'languageLabel': 'Idioma',
      'welcomeTitle': '¡Bienvenido!',
      'welcomeBody': 'Ahora has iniciado sesión en Brownbook.',
      'welcomeCardTitle': 'Esto es lo que puedes hacer ahora:',
      'welcomeFeature1': 'Organiza tus libros con estantes personalizados.',
      'welcomeFeature2': 'Captura notas y resaltados al instante.',
      'welcomeFeature3': 'Invita a tu equipo a colaborar de forma segura.',
      'getStarted': 'Comenzar',
      'loading': 'Cargando...',
    },
  };

  static const _languageNames = <String, String>{
    'en': 'English',
    'es': 'Español',
  };

  /// Returns the localized string for [key]. Falls back to English if missing.
  String translate(String key) {
    final languageCode = locale.languageCode;
    final localeValues = _localizedValues[languageCode];
    if (localeValues != null && localeValues.containsKey(key)) {
      return localeValues[key]!;
    }
    return _localizedValues['en']?[key] ?? key;
  }

  /// Returns the display name for the provided [languageCode].
  String languageName(String languageCode) {
    return _languageNames[languageCode] ?? languageCode;
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
