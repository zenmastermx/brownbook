import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;

import 'firebase_options.dart';
import 'localization/app_localizations.dart';
import 'welcome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('es');

  void _updateLocale(Locale locale) {
    if (_locale.languageCode == locale.languageCode) {
      return;
    }
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brownbook',
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(onLocaleChange: _updateLocale),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onLocaleChange});

  final void Function(Locale locale) onLocaleChange;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomePage()),
        );
      }
    });

    if (kIsWeb) {
      _authService.googleSignIn.onCurrentUserChanged.listen((account) async {
        if (account != null) {
          setState(() {
            _isSigningIn = true;
          });
          final user = await _authService.signInWithGoogleAccount(account);
          if (!mounted) return;
          setState(() {
            _isSigningIn = false;
          });
          if (user == null) {
            final strings = AppLocalizations.of(context);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
                SnackBar(content: Text(strings.translate('signInError'))));
          }
        }
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isSigningIn = true;
    });

    final user = await _authService.signInWithGoogle();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSigningIn = false;
    });

    if (user == null) {
      final strings = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.translate('signInError'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      onSignInWithGoogle: _handleGoogleSignIn,
      onLocaleChange: widget.onLocaleChange,
      isSigningIn: _isSigningIn,
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.onSignInWithGoogle,
    required this.onLocaleChange,
    required this.isSigningIn,
    this.onRefreshAuth,
  });

  final Future<void> Function() onSignInWithGoogle;
  final void Function(Locale) onLocaleChange;
  final bool isSigningIn;
  final VoidCallback? onRefreshAuth;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.translate('appTitle')),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: LanguageSwitcher(onLocaleChange: onLocaleChange),
          ),
        ],
      ),
      body: _LoginView(
        onSignInPressed: onSignInWithGoogle,
        onLocaleChange: onLocaleChange,
        isSigningIn: isSigningIn,
        onRefreshAuth: onRefreshAuth,
      ),
      floatingActionButton: onRefreshAuth != null
          ? FloatingActionButton(
              onPressed: onRefreshAuth,
              tooltip: 'Refresh Auth State',
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView({
    required this.onSignInPressed,
    required this.onLocaleChange,
    required this.isSigningIn,
    this.onRefreshAuth,
  });

  final Future<void> Function() onSignInPressed;
  final void Function(Locale) onLocaleChange;
  final bool isSigningIn;
  final VoidCallback? onRefreshAuth;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings.translate('loginTitle'),
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                strings.translate('loginSubtitle'),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              LanguageSelector(onLocaleChange: onLocaleChange),
              const SizedBox(height: 32),
              if (kIsWeb)
                Builder(builder: (context) {
                  return (GoogleSignInPlatform.instance as web.GoogleSignInPlugin)
                      .renderButton();
                })
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSigningIn ? null : onSignInPressed,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isSigningIn) ...[
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                            const SizedBox(width: 12),
                            Text(strings.translate('signingIn')),
                          ] else ...[
                            const Icon(Icons.login),
                            const SizedBox(width: 12),
                            Text(strings.translate('signInWithGoogle')),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Debug refresh button
              if (onRefreshAuth != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onRefreshAuth,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('🔄 Refresh Auth State'),
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

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key, required this.onLocaleChange});

  final void Function(Locale) onLocaleChange;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.translate('appTitle')),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: LanguageSwitcher(onLocaleChange: onLocaleChange),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(strings.translate('loading')),
          ],
        ),
      ),
    );
  }
}

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key, required this.onLocaleChange});

  final void Function(Locale) onLocaleChange;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final selectedLocale = Localizations.localeOf(context);

    final selected = AppLocalizations.supportedLocales.firstWhere(
      (locale) => locale.languageCode == selectedLocale.languageCode,
      orElse: () => AppLocalizations.supportedLocales.first,
    );

    return DropdownButtonHideUnderline(
      child: DropdownButton<Locale>(
        value: selected,
        icon: const Icon(Icons.language),
        onChanged: (Locale? locale) {
          if (locale != null) {
            onLocaleChange(locale);
          }
        },
        items: AppLocalizations.supportedLocales.map((locale) {
          final languageCode = locale.languageCode;
          return DropdownMenuItem<Locale>(
            value: locale,
            child: Text(strings.languageName(languageCode)),
          );
        }).toList(),
      ),
    );
  }
}

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key, required this.onLocaleChange});

  final void Function(Locale) onLocaleChange;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          strings.translate('languageLabel'),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(20),
          ),
          child: LanguageSwitcher(onLocaleChange: onLocaleChange),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'openid'],
  );

  GoogleSignIn get googleSignIn => _googleSignIn;

  Future<User?> signInWithGoogleAccount(GoogleSignInAccount googleUser) async {
    try {
      print('Got Google user: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('Google authentication failed: missing tokens');
        return null;
      }

      print('Got Google auth tokens, creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Signing in with Firebase...');
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      print('Firebase sign-in successful: ${userCredential.user?.email}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Exception: ${e.code} - ${e.message}");
    } catch (e) {
      print("General Exception during Google Sign-In: $e");
    }
    return null;
  }

  Future<User?> signInWithGoogle() async {
    if (kIsWeb) {
      return null;
    }
    try {
      print('Starting Google Sign-In process...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Google Sign-In cancelled by user');
        return null;
      }
      return await signInWithGoogleAccount(googleUser);
    } catch (e) {
      print("General Exception during Google Sign-In: $e");
    }
    return null;
  }

  Future<void> signOutGoogle() async {
    try {
      print('Starting sign-out process...');
      await _googleSignIn.signOut();
      print('Google Sign-In signed out');
      await _auth.signOut();
      print('Firebase Auth signed out');
    } catch (e) {
      print("Error during sign-out: $e");
      // Even if there's an error, try to sign out from both services
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print("Error signing out from Google: $e");
      }
      try {
        await _auth.signOut();
      } catch (e) {
        print("Error signing out from Firebase: $e");
      }
    }
  }
}
