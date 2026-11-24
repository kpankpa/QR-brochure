import 'package:flutter/material.dart';

/// A selectable icon that can be shown on a digital business card.
class CardIconOption {
  const CardIconOption(this.name, this.label, this.icon);

  final String name;
  final String label;
  final IconData icon;
}

/// Curated icon set used by the editor picker and the public card view.
class CardIcons {
  static const List<CardIconOption> options = <CardIconOption>[
    CardIconOption('business', 'Business', Icons.business_outlined),
    CardIconOption('person', 'Person', Icons.person_outline),
    CardIconOption('work', 'Work', Icons.work_outline_rounded),
    CardIconOption('star', 'Star', Icons.star_outline),
    CardIconOption('account', 'Finance', Icons.account_balance_outlined),
    CardIconOption('school', 'Education', Icons.school_outlined),
    CardIconOption('favorite', 'Creative', Icons.favorite_outline),
    CardIconOption('public', 'Global', Icons.public_outlined),
  ];

  static const String defaultName = 'business';

  static IconData iconFor(String? name) {
    for (final option in options) {
      if (option.name == name) return option.icon;
    }
    return options.first.icon;
  }

  static String labelFor(String? name) {
    for (final option in options) {
      if (option.name == name) return option.label;
    }
    return options.first.label;
  }
}
