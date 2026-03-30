import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:beerpongapp/theme.dart';
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

const _rules = [
  _Rule(
    icon: BeerpongIcons.airball,
    name: 'Airballs',
    accent: Color(0xFFFF6D00),
    tagline: 'Miss out loud — your team pays the price.',
    description:
        'An airball is a throw that misses every cup without touching '
        'anything. When a team accumulates 3 airballs in total, all players '
        'must take a penalty sip. The counter resets and keeps climbing.',
    steps: [
      'Enable "Airballs" in game setup.',
      'When a shot misses completely, tap the orange miss zone below '
          'the cups.',
      'At every 3rd airball, a dialog prompts the penalty.',
    ],
    tip: 'The miss zone only appears when the Airballs rule is active — '
        'remember to tap it on every complete miss.',
  ),
  _Rule(
    icon: Icons.roundabout_left,
    name: 'Bounce',
    accent: Color(0xFF1E88E5),
    tagline: 'One ball, two cups — but the defense can swat it.',
    description:
        'A bounce shot is a throw where the ball bounces off the table '
        'before landing in a cup. It rewards risk: a successful bounce '
        'removes the hit cup plus one additional random cup. However, the '
        'defending team is allowed to swat the ball away after the first '
        'bounce, so it can be blocked.',
    steps: [
      'Enable "Bounce" in game setup.',
      'During your turn, open the action menu (⋯) and tap "Bounce Shot".',
      'Select who made the bounce, then tap the cup they sank.',
    ],
    tip: 'Bounce shots are high-risk, high-reward. Save them for when '
        'you need to close a gap quickly.',
  ),
  _Rule(
    icon: Icons.sports_basketball_outlined,
    name: 'Putback',
    accent: Color(0xFFFFB300),
    tagline: 'The game isn\'t over until the last redemption throw lands.',
    description:
        'When a team sinks the opponent\'s final cup, the losing side '
        'earns one redemption throw per player. If any throw lands, the '
        'last cup is restored and the game continues into overtime. Every '
        'player must attempt their throw before the result is decided.',
    steps: [
      'Enable "Putback" in game setup.',
      'When the last cup is sunk, the redemption dialog appears '
          'automatically.',
      'Each losing-team player takes one shot. A hit keeps the game alive.',
    ],
    tip: 'If multiple redemption throws land, only one cup is restored — '
        'aim carefully.',
  ),
  _Rule(
    icon: BeerpongIcons.palmTree,
    name: 'Island',
    accent: Color(0xFF00897B),
    tagline: 'An isolated cup means a free bonus cup.',
    description:
        'An island cup is one with no neighbours — completely surrounded '
        'by empty space. A designated shooter can call an island shot on '
        'it. If they sink it, they win that cup plus a bonus cup of their '
        'choice. A miss scores nothing and the attempt is used up.',
    steps: [
      'Enable "Island" in game setup.',
      'Tap "Island Shot" in the action menu and select the shooter.',
      'Island cups glow yellow. Tap one to take the shot.',
      'On success, pick your free bonus cup from the bottom sheet.',
    ],
    tip: 'If only one island cup exists, the shot triggers automatically '
        'after selecting the shooter — no extra tap needed.',
  ),
  _Rule(
    icon: BeerpongIcons.skull,
    name: 'Deathcup',
    accent: Color(0xFFE53935),
    tagline: 'Sink the cup being drunk and the game ends instantly.',
    description:
        'When the Deathcup rule is active, each cup that has been sunk '
        'but not yet fully drunk is a live deathcup. If a player lands '
        'a ball in it while an opponent is still drinking, that team '
        'immediately loses — all remaining cups are cleared.',
    steps: [
      'Enable "Deathcup" in game setup.',
      'When a deathcup is sunk, open the action menu (⋯) and tap '
          '"Deathcup".',
      'Select the player who made the shot to trigger the instant win.',
    ],
    tip: 'Keep track of which cups opponents are currently drinking — '
        'they\'re your highest-value targets.',
  ),
  _Rule(
    icon: BeerpongIcons.umstellen,
    name: 'Rearrange',
    accent: Color(0xFF8E24AA),
    tagline: 'Regroup scattered cups into a tighter formation.',
    description:
        'Once per game, when 6 or fewer cups remain on your side, you '
        'can call a re-rack. Cups are rearranged into a standard triangle '
        'formation, closing the gaps that make individual cups harder to '
        'hit. The re-rack can only be used once and only within the '
        '6-cup limit.',
    steps: [
      'Enable "Rearrange" in game setup.',
      'When 6 or fewer cups remain, tap the re-rack button in the '
          'bottom dock bar.',
      'Cups immediately shift into a compact triangle.',
    ],
    tip: 'Save your re-rack for when cups are most scattered — a tight '
        'triangle is significantly easier to aim at.',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class RulebookScreen extends StatelessWidget {
  const RulebookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        title: Text(
          'Rulebook',
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
        itemCount: _rules.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) => _RuleCard(rule: _rules[i]),
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
                    'SPECIAL',
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
                      'How to activate',
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
