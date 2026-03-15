import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:beerpongapp/constants.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:beerpongapp/widgets/user_card.dart';

enum UsernameStatus { idle, checking, available, taken, invalid }

/// Regex: 3–20 chars, starts/ends with alphanumeric, may contain underscores,
/// no consecutive underscores.
final _usernameRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_]{1,18}[a-zA-Z0-9]$');

bool _isValidUsername(String value) {
  if (!_usernameRegex.hasMatch(value)) return false;
  if (value.contains('__')) return false;
  return true;
}

class CustomUserScreen extends StatefulWidget {
  final User user;
  const CustomUserScreen({super.key, required this.user});

  @override
  State<CustomUserScreen> createState() => _CustomUserScreenState();
}

class _CustomUserScreenState extends State<CustomUserScreen> {
  static const _avatarKeys = AppConstants.avatarKeys;

  late String _selectedAvatarKey;
  late String _selectedTitle;
  bool _isSaving = false;

  // Username editing
  late final TextEditingController _usernameController;
  UsernameStatus _usernameStatus = UsernameStatus.idle;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _selectedAvatarKey = _avatarKeys.contains(widget.user.avatarKey)
        ? widget.user.avatarKey
        : _avatarKeys.first;
    _selectedTitle = widget.user.title;
    _usernameController =
        TextEditingController(text: widget.user.username);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _usernameController.dispose();
    super.dispose();
  }

  List<String> get _availableTitles {
    final unlocked = widget.user.unlockedTitles;
    return unlocked.isNotEmpty ? unlocked : ['Beginner', 'Pro Player', 'Champion'];
  }

  String get _currentUsername => _usernameController.text.trim();

  bool get _usernameChanged =>
      _currentUsername != widget.user.username;

  bool get _canSave =>
      _usernameStatus != UsernameStatus.checking &&
      _usernameStatus != UsernameStatus.taken &&
      _usernameStatus != UsernameStatus.invalid &&
      !_isSaving;

  // Local preview — updates live as the user picks
  User get _previewUser => widget.user.copyWith(
        avatarKey: _selectedAvatarKey,
        title: _selectedTitle,
      );

  void _onUsernameChanged(String value) {
    _debounceTimer?.cancel();
    final trimmed = value.trim();

    if (trimmed == widget.user.username) {
      setState(() => _usernameStatus = UsernameStatus.idle);
      return;
    }

    if (!_isValidUsername(trimmed)) {
      setState(() => _usernameStatus = UsernameStatus.invalid);
      return;
    }

    setState(() => _usernameStatus = UsernameStatus.checking);

    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      final available = await FirestoreService.instance.checkUsernameAvailable(
        trimmed.toLowerCase(),
        widget.user.id,
      );
      if (!mounted) return;
      setState(() => _usernameStatus =
          available ? UsernameStatus.available : UsernameStatus.taken);
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final provider = Provider.of<UserProvider>(context, listen: false);

      if (_usernameChanged) {
        await provider.claimUsername(_currentUsername);
      }

      await provider.updateUser(_previewUser.copyWith(
        username: _currentUsername,
      ));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _canSave ? _save : null,
        backgroundColor: _canSave ? Colors.orange : Colors.grey,
        foregroundColor: Colors.white,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.check),
        label: Text(_isSaving ? 'Saving…' : 'Save'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Live preview card — reflects picks in real time
            UserCard(
              user: _previewUser,
              onTitleTap: () {},
              onAvatarTap: () {},
            ),
            const SizedBox(height: 28),

            const _SectionHeader(title: 'Username'),
            const SizedBox(height: 12),
            _buildUsernameField(),

            const SizedBox(height: 28),

            const _SectionHeader(title: 'Avatar'),
            const SizedBox(height: 12),
            _buildAvatarGrid(),

            const SizedBox(height: 28),

            const _SectionHeader(title: 'Title'),
            const SizedBox(height: 12),
            _buildTitlePicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    final c = AppColors.of(context);
    final (color, icon, hint) = switch (_usernameStatus) {
      UsernameStatus.idle => (Colors.grey.shade600, null, ''),
      UsernameStatus.checking =>
        (Colors.grey.shade400, Icons.hourglass_empty, 'Checking…'),
      UsernameStatus.available =>
        (Colors.green, Icons.check_circle_outline, 'Available'),
      UsernameStatus.taken =>
        (Colors.red, Icons.cancel_outlined, 'Already taken'),
      UsernameStatus.invalid => (
          Colors.orange,
          Icons.warning_amber_outlined,
          '3–20 chars, letters/numbers/underscores, no consecutive __'
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _usernameController,
          maxLength: 20,
          style: TextStyle(color: c.onBackground),
          decoration: InputDecoration(
            hintText: 'Choose a username',
            hintStyle: TextStyle(color: c.subtle),
            counterStyle: TextStyle(color: c.subtle),
            filled: true,
            fillColor: c.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 2),
            ),
            suffixIcon: _usernameStatus == UsernameStatus.checking
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white54),
                    ),
                  )
                : icon != null
                    ? Icon(icon, color: color, size: 22)
                    : null,
          ),
          onChanged: _onUsernameChanged,
        ),
        if (hint.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              hint,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarGrid() {
    final c = AppColors.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _avatarKeys.length,
      itemBuilder: (context, index) {
        final key = _avatarKeys[index];
        final isSelected = _selectedAvatarKey == key;

        return GestureDetector(
          onTap: () => setState(() => _selectedAvatarKey = key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isSelected
                  ? Colors.orange.withValues(alpha: 0.12)
                  : c.card,
              border: Border.all(
                color: isSelected ? Colors.orange : c.border,
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: SvgPicture.asset(
                    'assets/avatars/$key.svg',
                    fit: BoxFit.contain,
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          size: 11, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitlePicker() {
    final c = AppColors.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableTitles.map((title) {
        final isSelected = _selectedTitle == title;
        return GestureDetector(
          onTap: () => setState(() => _selectedTitle = title),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isSelected ? Colors.orange : c.card,
              border: Border.all(
                color: isSelected ? Colors.orange : c.border,
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : c.subtle,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Text(
      title,
      style: TextStyle(
        color: c.onBackground,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
