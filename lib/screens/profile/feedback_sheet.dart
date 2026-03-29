import 'dart:io' show Platform;

import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:flutter/material.dart';

class FeedbackSheet extends StatefulWidget {
  final User user;
  const FeedbackSheet({super.key, required this.user});

  static Future<void> show(BuildContext context, User user) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FeedbackSheet(user: user),
      );

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  static const _categories = ['Bug', 'Suggestion', 'Other'];

  String _category = 'Bug';
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _ctrl.text.trim();
    if (message.isEmpty) return;
    setState(() => _loading = true);
    try {
      await FirestoreService.instance.submitFeedback(
        userId: widget.user.id,
        username: widget.user.username,
        platform: Platform.isIOS ? 'iOS' : 'Android',
        category: _category,
        message: message,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for your feedback!')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send feedback. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Send Feedback',
                style: TextStyle(
                  color: c.onBackground,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: c.subtle),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Category chips
          Row(
            children: _categories.map((cat) {
              final selected = _category == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = cat),
                  selectedColor: Colors.amber,
                  backgroundColor: c.surface2,
                  labelStyle: TextStyle(
                    color: selected ? Colors.black : c.subtle,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  side: BorderSide.none,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            maxLines: 4,
            autofocus: true,
            style: TextStyle(color: c.onBackground),
            decoration: InputDecoration(
              hintText: 'Describe the issue or idea…',
              hintStyle: TextStyle(color: c.subtle),
              filled: true,
              fillColor: c.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.amber.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Text(
                      'Send',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
