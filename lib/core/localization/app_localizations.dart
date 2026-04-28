import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'createQuiz': 'Create Quiz',
      'joinGame': 'Join Game',
      'make': 'Make',
      'myQuizzes': 'My Quizzes',
      'player': 'Player',
      'language': 'Language',
      'theme': 'Theme',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
      'english': 'English',
      'french': 'French',
      'arabic': 'Arabic',
      'welcomeBack': 'Welcome back!',
      'createAccount': 'Create Account',
      'email': 'Email',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'username': 'Username',
      'signUp': 'Sign up',
      'logIn': 'Log In',
      'alreadyHaveAccount': 'Already have an account?',
      'dontHaveAccount': 'Don\'t have an account?',
      'correct': 'Correct!',
      'wrong': 'Wrong!',
      'waitingForOthers': 'Waiting for others…',
    },
    'fr': {
      'createQuiz': 'Créer un quiz',
      'joinGame': 'Rejoindre une partie',
      'make': 'Créer',
      'myQuizzes': 'Mes quiz',
      'player': 'Joueur',
      'language': 'Langue',
      'theme': 'Thème',
      'system': 'Système',
      'light': 'Clair',
      'dark': 'Sombre',
      'english': 'Anglais',
      'french': 'Français',
      'arabic': 'Arabe',
      'welcomeBack': 'Bon retour !',
      'createAccount': 'Créer un compte',
      'email': 'E-mail',
      'password': 'Mot de passe',
      'confirmPassword': 'Confirmer le mot de passe',
      'username': 'Nom d\'utilisateur',
      'signUp': 'S\'inscrire',
      'logIn': 'Se connecter',
      'alreadyHaveAccount': 'Vous avez déjà un compte ?',
      'dontHaveAccount': 'Vous n\'avez pas de compte ?',
      'correct': 'Correct !',
      'wrong': 'Faux !',
      'waitingForOthers': 'En attente des autres…',
    },
    'ar': {
      'createQuiz': 'إنشاء اختبار',
      'joinGame': 'الانضمام إلى لعبة',
      'make': 'إنشاء',
      'myQuizzes': 'اختباراتي',
      'player': 'لاعب',
      'language': 'اللغة',
      'theme': 'المظهر',
      'system': 'النظام',
      'light': 'فاتح',
      'dark': 'داكن',
      'english': 'الإنجليزية',
      'french': 'الفرنسية',
      'arabic': 'العربية',
      'welcomeBack': 'مرحبًا بعودتك!',
      'createAccount': 'إنشاء حساب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'confirmPassword': 'تأكيد كلمة المرور',
      'username': 'اسم المستخدم',
      'signUp': 'إنشاء حساب',
      'logIn': 'تسجيل الدخول',
      'alreadyHaveAccount': 'لديك حساب بالفعل؟',
      'dontHaveAccount': 'ليس لديك حساب؟',
      'correct': 'إجابة صحيحة!',
      'wrong': 'إجابة خاطئة!',
      'waitingForOthers': 'بانتظار الآخرين…',
    },
  };

  String t(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key] ??
        key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales
          .any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppL10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
