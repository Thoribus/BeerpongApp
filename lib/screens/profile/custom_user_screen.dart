import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:beerpongapp/constants.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/util/localization_extensions.dart';
import 'package:beerpongapp/util/level_system.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:beerpongapp/widgets/user_card.dart';

enum UsernameStatus { idle, checking, available, taken, invalid }

/// Regex: 3–20 chars, starts/ends with alphanumeric, may contain underscores
/// or single spaces in the middle. No consecutive underscores or spaces.
final _usernameRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_ ]{1,18}[a-zA-Z0-9]$');

bool _isValidUsername(String value) {
  if (!_usernameRegex.hasMatch(value)) return false;
  if (value.contains('__')) return false;
  if (value.contains('  ')) return false;
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
  static const _backgroundKeys = AppConstants.backgroundKeys;

  late String _selectedAvatarKey;
  late String _selectedBackgroundKey;
  late String _selectedTitle;
  bool _isSaving = false;
  UsernameStatus _usernameStatus = UsernameStatus.idle;
  String _currentUsername = '';

  @override
  void initState() {
    super.initState();
    _selectedAvatarKey = _avatarKeys.contains(widget.user.avatarKey)
        ? widget.user.avatarKey
        : _avatarKeys.first;
    _selectedBackgroundKey =
        _backgroundKeys.contains(widget.user.backgroundKey)
            ? widget.user.backgroundKey
            : _backgroundKeys.first;
    _selectedTitle = widget.user.title;
    _currentUsername = widget.user.username;
  }

  List<String> get _availableTitles {
    final unlocked = widget.user.unlockedTitles;
    final base = unlocked.isNotEmpty ? unlocked : ['Beginner', 'Pro Player', 'Champion'];
    if (widget.user.isSupporter && !base.contains('Supporter')) {
      return [...base, 'Supporter'];
    }
    return base;
  }

  bool get _canSave =>
      _usernameStatus != UsernameStatus.checking &&
      _usernameStatus != UsernameStatus.taken &&
      _usernameStatus != UsernameStatus.invalid &&
      !_isSaving;

  User get _previewUser => widget.user.copyWith(
        avatarKey: _selectedAvatarKey,
        backgroundKey: _selectedBackgroundKey,
        title: _selectedTitle,
      );

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final provider = Provider.of<UserProvider>(context, listen: false);

      if (_currentUsername != widget.user.username) {
        await provider.claimUsername(_currentUsername);
      }

      await provider.updateUser(_previewUser.copyWith(
        username: _currentUsername,
      ));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.loc.profileUpdated),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.loc.profileSaveFailed(e)),
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
        label: Text(_isSaving ? context.loc.btnSaving : context.loc.btnSave),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Live preview card — wrapped in RepaintBoundary so only avatar/title
            // changes trigger a repaint; username typing does not.
            RepaintBoundary(
              child: UserCard(
                user: _previewUser,
                onTitleTap: () {},
                onAvatarTap: () {},
              ),
            ),
            const SizedBox(height: 28),

            _SectionHeader(title: context.loc.profileSectionUsername),
            const SizedBox(height: 12),
            // Extracted into its own StatefulWidget so username status changes
            // only rebuild the field, not the whole screen.
            _UsernameField(
              initialUsername: widget.user.username,
              userId: widget.user.id,
              onStatusChanged: (status, value) => setState(() {
                _usernameStatus = status;
                _currentUsername = value;
              }),
            ),

            const SizedBox(height: 28),

            _SectionHeader(title: context.loc.profileSectionAvatar),
            const SizedBox(height: 12),
            _buildAvatarGrid(),

            const SizedBox(height: 28),

            _SectionHeader(title: context.loc.profileSectionBackground),
            const SizedBox(height: 12),
            _buildBackgroundGrid(),

            const SizedBox(height: 28),

            _SectionHeader(title: context.loc.profileSectionTitle),
            const SizedBox(height: 12),
            _buildTitlePicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarGrid() {
    final c = AppColors.of(context);
    final userLevel = LevelSystem.levelFromXp(widget.user.xp);
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
        final requiredLevel = AppConstants.avatarLevelRequirements[key] ?? 1;
        final isLocked = userLevel < requiredLevel;

        return GestureDetector(
          onTap: isLocked ? null : () => setState(() => _selectedAvatarKey = key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isLocked
                  ? c.card.withValues(alpha: 0.5)
                  : isSelected
                      ? Colors.orange.withValues(alpha: 0.12)
                      : c.card,
              border: Border.all(
                color: isLocked
                    ? c.border.withValues(alpha: 0.4)
                    : isSelected
                        ? Colors.orange
                        : c.border,
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Opacity(
                    opacity: isLocked ? 0.25 : 1.0,
                    child: SvgPicture.asset(
                      'assets/avatars/$key.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (isLocked)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, color: c.subtle, size: 22),
                        const SizedBox(height: 2),
                        Text(
                          context.loc.profileLevelRequired(requiredLevel),
                          style: TextStyle(
                            color: c.subtle,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isSelected && !isLocked)
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

  Widget _buildBackgroundGrid() {
    final c = AppColors.of(context);
    final userLevel = LevelSystem.levelFromXp(widget.user.xp);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: _backgroundKeys.length,
      itemBuilder: (context, index) {
        final key = _backgroundKeys[index];
        final isSelected = _selectedBackgroundKey == key;
        final requiredLevel =
            AppConstants.backgroundLevelRequirements[key] ?? 1;
        final isLocked = userLevel < requiredLevel;
        final gradient = AppBackgrounds.gradientFor(key);

        return GestureDetector(
          onTap: isLocked
              ? null
              : () => setState(() => _selectedBackgroundKey = key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: isLocked
                  ? LinearGradient(
                      colors: [
                        gradient.colors.first.withValues(alpha: 0.25),
                        gradient.colors.last.withValues(alpha: 0.25),
                      ],
                      begin: gradient.begin,
                      end: gradient.end,
                    )
                  : gradient,
              border: Border.all(
                color: isLocked
                    ? c.border.withValues(alpha: 0.4)
                    : isSelected
                        ? Colors.orange
                        : c.border,
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: Stack(
              children: [
                if (isLocked)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock, color: Colors.white70, size: 18),
                        const SizedBox(height: 2),
                        Text(
                          context.loc.profileLevelRequired(requiredLevel),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Center(
                    child: Text(
                      AppBackgrounds.labelFor(key),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                if (isSelected && !isLocked)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          size: 10, color: Colors.white),
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

// ── Username field — isolated StatefulWidget so typing only rebuilds itself ────

class _UsernameField extends StatefulWidget {
  final String initialUsername;
  final String userId;
  final void Function(UsernameStatus status, String value) onStatusChanged;

  const _UsernameField({
    required this.initialUsername,
    required this.userId,
    required this.onStatusChanged,
  });

  @override
  State<_UsernameField> createState() => _UsernameFieldState();
}

class _UsernameFieldState extends State<_UsernameField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  UsernameStatus _status = UsernameStatus.idle;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUsername);
    _focusNode = FocusNode();
    // Ensure the field never steals focus on first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.unfocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();

    if (trimmed == widget.initialUsername) {
      _setStatus(UsernameStatus.idle, trimmed);
      return;
    }
    if (!_isValidUsername(trimmed)) {
      _setStatus(UsernameStatus.invalid, trimmed);
      return;
    }

    _setStatus(UsernameStatus.checking, trimmed);

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final available = await FirestoreService.instance.checkUsernameAvailable(
        trimmed.toLowerCase(),
        widget.userId,
      );
      if (!mounted) return;
      _setStatus(
        available ? UsernameStatus.available : UsernameStatus.taken,
        trimmed,
      );
    });
  }

  void _setStatus(UsernameStatus s, String value) {
    setState(() => _status = s);
    widget.onStatusChanged(s, value);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (color, icon, hint) = switch (_status) {
      UsernameStatus.idle => (Colors.grey.shade600, null, ''),
      UsernameStatus.checking =>
        (Colors.grey.shade400, Icons.hourglass_empty, context.loc.profileUsernameChecking),
      UsernameStatus.available =>
        (Colors.green, Icons.check_circle_outline, context.loc.profileUsernameAvailable),
      UsernameStatus.taken =>
        (Colors.red, Icons.cancel_outlined, context.loc.profileUsernameTaken),
      UsernameStatus.invalid => (
          Colors.orange,
          Icons.warning_amber_outlined,
          context.loc.profileUsernameInvalid,
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: false,
          maxLength: 20,
          style: TextStyle(color: c.onBackground),
          decoration: InputDecoration(
            hintText: context.loc.profileUsernamePlaceholder,
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
            suffixIcon: _status == UsernameStatus.checking
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
          onChanged: _onChanged,
        ),
        if (hint.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(hint, style: TextStyle(color: color, fontSize: 12)),
          ),
      ],
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
