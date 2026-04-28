import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../../../../core/utils/supabase_storage.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../../../core/widgets/avatar_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _usernameCtrl = TextEditingController();
  XFile? _avatarFile;
  String? _avatarUrl;
  bool _isUploadingAvatar = false;
  bool _isEditing = false;

  void _initFromUser(UserModel user) {
    if (_usernameCtrl.text.isEmpty) {
      _usernameCtrl.text = user.username;
    }
    _avatarUrl ??= user.avatarUrl;
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final xfile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xfile == null) return;
    setState(() => _isUploadingAvatar = true);
    try {
      final url = await SupabaseStorageHelper.uploadAvatar(xfile);
      setState(() {
        _avatarFile = xfile;
        _avatarUrl = url;
        _isUploadingAvatar = false;
      });
    } catch (e) {
      setState(() => _isUploadingAvatar = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  void _saveProfile(BuildContext context) {
    if (_usernameCtrl.text.trim().isEmpty) return;
    context.read<ProfileCubit>().updateProfile(
          username: _usernameCtrl.text.trim(),
          avatarUrl: _avatarUrl,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded) {
          _initFromUser(state.user);
        } else if (state is ProfileUpdated) {
          _initFromUser(state.user);
          setState(() => _isEditing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated ✅'),
              backgroundColor: AppColors.success400,
            ),
          );
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error400,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.primary800,
          appBar: AppBar(
            backgroundColor: AppColors.primary600,
            iconTheme: const IconThemeData(color: AppColors.neutral50),
            title: Text(
              'Profile',
              style: GoogleFonts.nunito(
                color: AppColors.neutral50,
                fontWeight: FontWeight.w900,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Log out',
                icon: const Icon(Icons.logout, color: AppColors.neutral50),
                onPressed: () async {
                  await context.read<AuthCubit>().logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
          body: state is ProfileLoading && state is! ProfileLoaded
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.neutral50),
                )
              : ResponsiveContainer(
                  maxWidth: 600,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // ✅ ENHANCED: Avatar with AvatarWidget
                        GestureDetector(
                          onTap: _isEditing ? _pickAvatar : null,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              AvatarWidget(
                                avatarUrl: _avatarUrl,
                                username: _usernameCtrl.text.isNotEmpty
                                    ? _usernameCtrl.text
                                    : 'Profile',
                                radius: 60,
                                showBorder: true,
                                borderColor: AppColors.primary400,
                              ),
                              if (_isEditing)
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.accent400,
                                  child: _isUploadingAvatar
                                      ? const SizedBox(
                                          height: 14,
                                          width: 14,
                                          child: CircularProgressIndicator(
                                            color: AppColors.neutral50,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt,
                                          color: AppColors.neutral50,
                                          size: 18,
                                        ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        _ProfileField(
                          controller: _usernameCtrl,
                          label: 'Username',
                          icon: Icons.person_outline,
                          enabled: _isEditing,
                        ),
                        const SizedBox(height: 12),

                        if (state is ProfileLoaded)
                          _ProfileField(
                            controller: TextEditingController(
                                text: state.user.email),
                            label: 'Email',
                            icon: Icons.email_outlined,
                            enabled: false,
                          ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: _isEditing
                              ? ElevatedButton.icon(
                                  onPressed: state is ProfileLoading
                                      ? null
                                      : () => _saveProfile(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success400,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: state is ProfileLoading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            color: AppColors.neutral50,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save_outlined,
                                          color: AppColors.neutral50),
                                  label: Text(
                                    'Save Changes',
                                    style: GoogleFonts.nunito(
                                      color: AppColors.neutral50,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () => setState(
                                      () => _isEditing = true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary600,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.edit_outlined,
                                      color: AppColors.neutral50),
                                  label: Text(
                                    'Edit Profile',
                                    style: GoogleFonts.nunito(
                                      color: AppColors.neutral50,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                        ),

                        if (_isEditing) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () => setState(() {
                                _isEditing = false;
                                if (state is ProfileLoaded) {
                                  _usernameCtrl.text = state.user.username;
                                  _avatarUrl = state.user.avatarUrl;
                                  _avatarFile = null;
                                }
                              }),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.neutral50,
                                side:
                                    BorderSide(color: AppColors.neutral200.withOpacity(0.5)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        Builder(builder: (context) {
                          final user = state is ProfileLoaded
                              ? state.user
                              : state is ProfileUpdated
                                  ? state.user
                                  : null;
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.neutral50.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Stats',
                                  style: GoogleFonts.nunito(
                                    color: AppColors.neutral50,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _StatBadge(
                                      icon: Icons.quiz_outlined,
                                      label: 'Quizzes\nCreated',
                                      value: user != null
                                          ? '${user.quizzesCreated}'
                                          : '—',
                                    ),
                                    _StatBadge(
                                      icon: Icons.gamepad_outlined,
                                      label: 'Games\nPlayed',
                                      value: user != null
                                          ? '${user.gamesPlayed}'
                                          : '—',
                                    ),
                                    _StatBadge(
                                      icon: Icons.emoji_events_outlined,
                                      label: 'Best\nRank',
                                      value: user?.bestRank != null
                                          ? '#${user!.bestRank}'
                                          : '—',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      style: GoogleFonts.nunito(
        color: enabled ? AppColors.neutral50 : AppColors.neutral200.withOpacity(0.8),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: enabled ? AppColors.neutral200 : AppColors.neutral200.withOpacity(0.5),
        ),
        filled: true,
        fillColor: enabled
            ? AppColors.neutral50.withOpacity(0.12)
            : AppColors.neutral50.withOpacity(0.05),
        labelStyle: TextStyle(
          color: enabled ? AppColors.neutral200 : AppColors.neutral200.withOpacity(0.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.neutral200.withOpacity(0.7), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.neutral200.withOpacity(0.7), size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.nunito(
            color: AppColors.neutral50,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.nunito(
            color: AppColors.neutral200.withOpacity(0.7),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}