import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:beerpongapp/theme.dart';
import 'package:beerpongapp/util/localization_extensions.dart';
import 'package:flutter/material.dart';

// ── Rule definition ────────────────────────────────────────────────────────────

class _Rule {
  final IconData icon;
  final String name;
  final Color accent;
  final String tagline;
  final String description;
  final List<String> steps;
  final String? tip;

  const _Rule({
    required this.icon,
    required this.name,
    required this.accent,
    required this.tagline,
    required this.description,
    required this.steps,
    this.tip,
  });
}

List<_Rule> _buildRules(AppLocalizations l) => [
  _Rule(
    icon: BeerpongIcons.airball,
    name: l.gameModeRuleAirballs,
    accent: const Color(0xFFFF6D00),
    tagline: l.rulebookAirballsTagline,
    description: l.rulebookAirballsDescription,
    steps: [l.rulebookAirballsStep1, l.rulebookAirballsStep2, l.rulebookAirballsStep3],
    tip: l.rulebookAirballsTip,
  ),
  _Rule(
    icon: Icons.roundabout_left,
    name: l.gameModeRuleBounce,
    accent: const Color(0xFF1E88E5),
    tagline: l.rulebookBounceTagline,
    description: l.rulebookBounceDescription,
    steps: [l.rulebookBounceStep1, l.rulebookBounceStep2, l.rulebookBounceStep3],
    tip: l.rulebookBounceTip,
  ),
  _Rule(
    icon: Icons.sports_basketball_outlined,
    name: l.gameModeRulePutback,
    accent: const Color(0xFFFFB300),
    tagline: l.rulebookPutbackTagline,
    description: l.rulebookPutbackDescription,
    steps: [l.rulebookPutbackStep1, l.rulebookPutbackStep2, l.rulebookPutbackStep3],
    tip: l.rulebookPutbackTip,
  ),
  _Rule(
    icon: BeerpongIcons.palmTree,
    name: l.gameModeRuleIsland,
    accent: const Color(0xFF00897B),
    tagline: l.rulebookIslandTagline,
    description: l.rulebookIslandDescription,
    steps: [l.rulebookIslandStep1, l.rulebookIslandStep2, l.rulebookIslandStep3, l.rulebookIslandStep4],
    tip: l.rulebookIslandTip,
  ),
  _Rule(
    icon: BeerpongIcons.skull,
    name: l.gameModeRuleDeathcup,
    accent: const Color(0xFFE53935),
    tagline: l.rulebookDeathcupTagline,
    description: l.rulebookDeathcupDescription,
    steps: [l.rulebookDeathcupStep1, l.rulebookDeathcupStep2, l.rulebookDeathcupStep3],
    tip: l.rulebookDeathcupTip,
  ),
  _Rule(
    icon: BeerpongIcons.umstellen,
    name: l.gameModeRuleRearrange,
    accent: const Color(0xFF8E24AA),
    tagline: l.rulebookRearrangeTagline,
    description: l.rulebookRearrangeDescription,
    steps: [l.rulebookRearrangeStep1, l.rulebookRearrangeStep2, l.rulebookRearrangeStep3],
    tip: l.rulebookRearrangeTip,
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class RulebookScreen extends StatelessWidget {
  const RulebookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final rules = _buildRules(context.loc);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        title: Text(
          context.loc.homeRulebookTitle,
          style: TextStyle(
            color: c.onBackground,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: IconThemeData(color: c.onBackground),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: rules.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) => _RuleCard(rule: rules[i]),
      ),
    );
  }
}

// ── Rule card ─────────────────────────────────────────────────────────────────

class _RuleCard extends StatelessWidget {
  final _Rule rule;
  const _RuleCard({required this.rule});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: rule.accent.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: rule.accent.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: rule.accent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(rule.icon, color: rule.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rule.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: c.onBackground,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: rule.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    context.loc.rulebookSpecialBadge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: rule.accent,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tagline
                Text(
                  rule.tagline,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: rule.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),

                // Description
                Text(
                  rule.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: c.onBackground,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 14),

                // How to activate
                Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: rule.accent, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      context.loc.rulebookHowToActivate,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: rule.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...rule.steps.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(top: 1, right: 8),
                            decoration: BoxDecoration(
                              color: rule.accent.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${e.key + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: rule.accent,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 13,
                                color: c.onBackground,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),

                // Tip
                if (rule.tip != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1, right: 6),
                          child: Icon(Icons.lightbulb_outline_rounded,
                              color: Colors.amber, size: 14),
                        ),
                        Expanded(
                          child: Text(
                            rule.tip!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.amber,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
