import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../../../features/auth/presentation/cubit/auth_state.dart';

class JoinPage extends StatefulWidget {
  const JoinPage({super.key});

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  final _pinCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _pageController = PageController();
  int _currentStep = 0;
  String _selectedAvatar = 'https://api.dicebear.com/7.x/avataaars/png?seed=Felix';

  final List<String> _avatars = [
    'https://api.dicebear.com/7.x/avataaars/png?seed=Felix',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Aneka',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Buster',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Daisy',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Ginger',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Leo',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Mia',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Oliver',
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_handlePageChange);
  }

  void _handlePageChange() {
    final page = _pageController.hasClients ? _pageController.page?.round() ?? 0 : 0;
    if (page != _currentStep && mounted) {
      setState(() => _currentStep = page);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageChange);
    _pinCtrl.dispose();
    _nicknameCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ✅ ENHANCED: Better error handling for PIN entry
  void _onEnterPin() {
    if (_pinCtrl.text.trim().length < 4) {
      DialogUtils.showErrorSnackbar(
        context,
        '❌ No game found with this PIN',
      );
      return;
    }

    final authState = context.read<AuthCubit>().state;

    if (authState is AuthAuthenticated) {
      // ✅ AUTO-FILL: Authenticated user - skip nickname selection
      final user = authState.user;
      context.push('/game/lobby', extra: {
        'pin': _pinCtrl.text.trim(),
        'nickname': user.username.isNotEmpty ? user.username : 'Player',
        'avatarUrl': user.avatarUrl ?? _getDefaultAvatar(),
        'isHost': false,
      });
    } else {
      // ✅ ANONYMOUS: Show nickname/avatar selection
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onJoinGame() {
    final nickname = _nicknameCtrl.text.trim();
    if (nickname.isEmpty) {
      DialogUtils.showErrorSnackbar(
        context,
        '❌ Please enter a nickname',
      );
      return;
    }

    context.push('/game/lobby', extra: {
      'pin': _pinCtrl.text.trim(),
      'nickname': nickname,
      'avatarUrl': _selectedAvatar,
      'isHost': false,
    });
  }

  String _getDefaultAvatar() {
    return 'https://api.dicebear.com/7.x/avataaars/png?seed=Default';
  }

  @override
  Widget build(BuildContext context) {
    final isAvatarPage = _currentStep == 1;
    final authState = context.watch<AuthCubit>().state;
    final isAuthenticated = authState is AuthAuthenticated;
    final showBack = isAvatarPage || isAuthenticated;
    return PopScope(
      canPop: !isAvatarPage,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (isAvatarPage) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primary800,  
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: showBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.neutral50),
                  onPressed: () {
                    if (isAvatarPage) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else if (context.canPop()) {
                      context.pop();
                    }
                  },
                )
              : null,
          leadingWidth: showBack ? null : 0,
          actions: [
            if (!isAvatarPage && !isAuthenticated)
              TextButton(
                onPressed: () => context.push('/login'),
                child: Text(
                  'Host / Login',
                  style: GoogleFonts.nunito(
                    color: AppColors.neutral50,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildScreen(child: _buildPinInput()),
            _buildScreen(child: _buildNicknameInput()),
          ],
        ),
      ),
    );
  }

  Widget _buildScreen({required Widget child}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1100;
            final isTablet = constraints.maxWidth >= 700 && !isDesktop;
            final cardWidth = isDesktop ? 460.0 : (isTablet ? 420.0 : 340.0);
            final titleSize = isDesktop ? 64.0 : (isTablet ? 60.0 : 52.0);

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppConstants.appName,
                  style: GoogleFonts.nunito(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w900,
                    color: AppColors.neutral50,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 48),
                Container(
                  width: cardWidth,
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  decoration: BoxDecoration(
                    color: AppColors.neutral50,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neutral800.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: child,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPinInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _pinCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: 'Game PIN',
            filled: true,
            fillColor: AppColors.neutral200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _onEnterPin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              foregroundColor: AppColors.neutral50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              'Enter',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNicknameInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Choose Avatar',
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.neutral800,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _avatars.length,
            itemBuilder: (context, index) {
              final avatar = _avatars[index];
              final isSelected = _selectedAvatar == avatar;
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatar = avatar),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary600
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: AppColors.neutral200,
                    radius: 26,
                    backgroundImage: NetworkImage(avatar),
                    onBackgroundImageError: (_, __) {},
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nicknameCtrl,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: 'Nickname',
            filled: true,
            fillColor: AppColors.neutral200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _onJoinGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary600,
              foregroundColor: AppColors.neutral50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              'OK, go!',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}