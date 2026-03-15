import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:beerpongapp/constants.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:beerpongapp/widgets/user_card.dart';

class CustomUserScreen extends StatefulWidget {
  final User user;
  const CustomUserScreen({super.key, required this.user});

  @override
  State<CustomUserScreen> createState() => _CustomUserScreenState();
}

class _CustomUserScreenState extends State<CustomUserScreen> {
  static const _avatarKeys = AppConstants.avatarKeys;

  static const _bgColor = AppConstants.bgDark;
  static const _cardColor = AppConstants.surfaceDark;
  static const _borderColor = AppConstants.borderDark;

  late String _selectedAvatarKey;
  late String _selectedTitle;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedAvatarKey = _avatarKeys.contains(widget.user.avatarKey)
        ? widget.user.avatarKey
        : _avatarKeys.first;
    _selectedTitle = widget.user.title;
  }

  List<String> get _availableTitles {
    final unlocked = widget.user.unlockedTitles;
    return unlocked.isNotEmpty ? unlocked : ['Beginner', 'Pro Player', 'Champion'];
  }

  // Local preview — updates live as the user picks
  User get _previewUser => widget.user.copyWith(
        avatarKey: _selectedAvatarKey,
        title: _selectedTitle,
      );

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final provider = Provider.of<UserProvider>(context, listen: false);
      await provider.updateUser(_previewUser);
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
    return Scaffold(
      backgroundColor: _bgColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _save,
        backgroundColor: Colors.orange,
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

  Widget _buildAvatarGrid() {
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
                  : _cardColor,
              border: Border.all(
                color: isSelected ? Colors.orange : _borderColor,
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
              color: isSelected ? Colors.orange : _cardColor,
              border: Border.all(
                color: isSelected ? Colors.orange : _borderColor,
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade400,
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
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
