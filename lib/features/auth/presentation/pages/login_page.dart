import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_logo.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error400,
            ),
          );
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary600, AppColors.primary800],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Logo ──────────────────────────────────────
                        const QuizBlitzLogo(),
                        const SizedBox(height: 40),

                        // ── White card form ───────────────────────────
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: AppColors.neutral50,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neutral800.withOpacity(0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  context.l10n.t('welcomeBack'),
                                  style: GoogleFonts.nunito(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),

                                // Email field
                                CardTextField(
                                  controller: _emailCtrl,
                                  label: 'Email',
                                  hint: 'you@example.com',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) =>
                                      (v == null || !v.contains('@'))
                                          ? 'Enter a valid email'
                                          : null,
                                ),
                                const SizedBox(height: 16),

                                // Password field
                                CardTextField(
                                  controller: _passwordCtrl,
                                  label: 'Password',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.neutral400,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscurePassword =
                                          !_obscurePassword,
                                    ),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.length < 6)
                                          ? 'Min 6 characters'
                                          : null,
                                ),
                                const SizedBox(height: 28),

                                // Login button
                                BlocBuilder<AuthCubit, AuthState>(
                                  builder: (context, state) {
                                    return SizedBox(
                                      height: 52,
                                      child: ElevatedButton(
                                        onPressed: state is AuthLoading
                                            ? null
                                            : () => _submit(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primary600,
                                          foregroundColor: AppColors.neutral50,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: state is AuthLoading
                                            ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: AppColors.neutral50,
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : Text(
                                                context.l10n.t('logIn'),
                                                style: GoogleFonts.nunito(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Register link ─────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.l10n.t('dontHaveAccount'),
                              style: GoogleFonts.nunito(
                                color: AppColors.neutral200,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/register'),
                              child: Text(
                                context.l10n.t('signUp'),
                                style: GoogleFonts.nunito(
                                  color: AppColors.neutral50,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.neutral50,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // ── Play anonymously link ──────────────────────────
                        TextButton.icon(
                          onPressed: () => context.push('/join'),
                          icon: const Icon(Icons.videogame_asset_rounded, color: AppColors.neutral50, size: 24),
                          label: Text(
                            'Play Anonymously',
                            style: GoogleFonts.nunito(
                              color: AppColors.neutral50,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Register page
// ─────────────────────────────────────────────────────────────────────────────

/// QuizBlitz logo widget shared by login & register pages.
class QuizBlitzLogo extends StatelessWidget {
  const QuizBlitzLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.neutral800.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: AppLogo(
              size: 48,
              color: AppColors.primary600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppConstants.appName,
          style: GoogleFonts.nunito(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: AppColors.neutral50,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          'Play. Learn. Compete.',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: AppColors.neutral200.withOpacity(0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Text field styled for the white card on auth screens.
class CardTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const CardTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.nunito(
        color: AppColors.neutral800,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary600),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.primary50,
        labelStyle: const TextStyle(color: AppColors.primary600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary600, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.error400, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.error400, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}
