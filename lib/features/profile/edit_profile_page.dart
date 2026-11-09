import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/widgets/user_avatar.dart';
import '../dashboard/home_data.dart';
import '../tests/tests_repository.dart' show friendlyError;
import 'avatar_picker.dart';
import 'profile_repository.dart';

/// Change the profile photo, name and student ID, and the password.
/// Pops with `true` when something was changed.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.role, required this.data});

  final String role;
  final HomeData data;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _studentController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _repo = ProfileRepository.instance;

  String? _avatarUrl;
  bool _changed = false;
  bool _photoBusy = false;
  bool _saving = false;
  bool _passwordBusy = false;
  bool _obscure = true;

  bool get _isStudent => widget.role == 'student';

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.data.name;
    _studentController.text = widget.data.studentNumber ?? '';
    _avatarUrl = widget.data.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  String _errorText(Object error) {
    if (error is AuthException) return error.message;
    return friendlyError(error);
  }

  Future<void> _changePhoto() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, 'camera'),
            ),
            if (_avatarUrl != null)
              ListTile(
                leading:
                const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                title: const Text(
                  'Remove photo',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () => Navigator.pop(sheetContext, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    setState(() => _photoBusy = true);
    try {
      if (choice == 'remove') {
        await _repo.removeAvatar();
        if (!mounted) return;
        setState(() => _avatarUrl = null);
      } else {
        final photo = await pickPhoto(
          choice == 'camera' ? PhotoSource.camera : PhotoSource.gallery,
        );
        if (photo == null) return;
        final url = await _repo.uploadAvatar(
          bytes: photo.bytes,
          extension: photo.extension,
        );
        if (!mounted) return;
        setState(() => _avatarUrl = url);
      }
      _changed = true;
    } catch (e) {
      if (mounted) _message(_errorText(e));
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await _repo.updateProfile(
        fullName: _nameController.text.trim(),
        studentNumber: _isStudent ? _studentController.text.trim() : null,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _message(_errorText(e));
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _passwordBusy = true);
    try {
      await _repo.updatePassword(_newPasswordController.text);
      if (!mounted) return;
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _passwordBusy = false);
      _message('Password updated.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _passwordBusy = false);
      _message(_errorText(e));
    }
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit profile')),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          UserAvatar(
                            name: _nameController.text,
                            imageUrl: _avatarUrl,
                            size: 104,
                          ),
                          if (_photoBusy)
                            const SizedBox(
                              width: 104,
                              height: 104,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _photoBusy ? null : _changePhoto,
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Change photo'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _sectionCard(
                  title: 'Personal information',
                  child: Form(
                    key: _profileFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration:
                          const InputDecoration(labelText: 'Full name'),
                          validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Enter your full name'
                              : null,
                        ),
                        if (_isStudent) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _studentController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Student ID (optional)',
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _saving ? null : _saveProfile,
                          child: _saving
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                              : const Text('Save changes'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Change password',
                  child: Form(
                    key: _passwordFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'New password',
                            suffixIcon: IconButton(
                              tooltip:
                              _obscure ? 'Show password' : 'Hide password',
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter a new password';
                            }
                            if (value.length < 8) {
                              return 'Use at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscure,
                          decoration: const InputDecoration(
                            labelText: 'Confirm new password',
                          ),
                          validator: (value) {
                            if (value != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _passwordBusy ? null : _changePassword,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            minimumSize: const Size.fromHeight(54),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(AppRadius.button),
                            ),
                          ),
                          child: _passwordBusy
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                            ),
                          )
                              : const Text('Update password'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}