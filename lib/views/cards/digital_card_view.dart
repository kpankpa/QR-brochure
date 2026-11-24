import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/card_icon.dart';
import '../../models/digital_card.dart';

/// Shared card layout used by both the in-app preview and the public `/c/{slug}`
/// page. The public page passes a brand colour through [DigitalCard].
class DigitalCardView extends StatelessWidget {
  const DigitalCardView({
    super.key,
    required this.card,
    this.onSaveContact,
    this.onCopyLink,
    this.showActions = true,
  });

  final DigitalCard card;
  final VoidCallback? onSaveContact;
  final VoidCallback? onCopyLink;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final brand = Color(card.brandColorValue);
    final darkBrand = Color.lerp(brand, Colors.black, 0.38) ?? brand;
    final scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.light,
    );

    return Theme(
      data: Theme.of(context).copyWith(colorScheme: scheme),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFF7F8FA)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [darkBrand, brand],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                  child: Column(
                    children: [
                      if (card.logoUrl.trim().isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            height: 34,
                            child: Image.network(
                              card.logoUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const SizedBox(),
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.white,
                          foregroundColor: brand,
                          child:
                              card.photoUrl.trim().isNotEmpty
                                  ? ClipOval(
                                    child: Image.network(
                                      card.photoUrl,
                                      width: 92,
                                      height: 92,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => Text(
                                            card.initials,
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                    ),
                                  )
                                  : Text(
                                    card.initials,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        card.displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      if (card.jobTitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          card.jobTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if (card.companyName.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CardIcons.iconFor(card.iconName),
                                size: 15,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                card.companyName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (showActions) const SizedBox(height: 20),
                      if (showActions)
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: brand,
                                  minimumSize: const Size.fromHeight(46),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: onSaveContact,
                                icon: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                ),
                                label: const Text('Save contact'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white70),
                                  minimumSize: const Size.fromHeight(46),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: onCopyLink,
                                icon: const Icon(Icons.ios_share_rounded),
                                label: const Text('Share'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _QuickActions(card: card),
                  if (card.summary.trim().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _Section(
                      title: 'About',
                      child: Text(
                        card.summary,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                  if (card.hasAddress) ...[
                    const SizedBox(height: 18),
                    _Section(
                      title: 'Address',
                      child: InkWell(
                        onTap: () => _open(card.mapUrl),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.locationDot,
                                size: 17,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  card.addressLine,
                                  style: const TextStyle(fontSize: 13.5),
                                ),
                              ),
                              Text(
                                'View on map',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 13,
                                color: scheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _Section(
                    title: 'Contact details',
                    child: Column(
                      children: [
                        if (card.primaryPhone.trim().isNotEmpty)
                          _ContactRow(
                            icon: const Icon(
                              Icons.phone_outlined,
                              size: 18,
                              color: Color(0xFF6B7280),
                            ),
                            label: 'Mobile',
                            value: card.primaryPhone,
                            onTap:
                                () => _open(card.primaryPhone, prefix: 'tel:'),
                          ),
                        if (card.secondaryPhone.trim().isNotEmpty)
                          _ContactRow(
                            icon: const Icon(
                              Icons.work_outline_rounded,
                              size: 18,
                              color: Color(0xFF6B7280),
                            ),
                            label: 'Office',
                            value: card.secondaryPhone,
                            onTap:
                                () =>
                                    _open(card.secondaryPhone, prefix: 'tel:'),
                          ),
                        if (card.primaryEmail.trim().isNotEmpty)
                          _ContactRow(
                            icon: const Icon(
                              Icons.email_outlined,
                              size: 18,
                              color: Color(0xFF6B7280),
                            ),
                            label: 'Email',
                            value: card.primaryEmail,
                            onTap:
                                () =>
                                    _open(card.primaryEmail, prefix: 'mailto:'),
                          ),
                        if (card.secondaryEmail.trim().isNotEmpty)
                          _ContactRow(
                            icon: const Icon(
                              Icons.alternate_email_rounded,
                              size: 18,
                              color: Color(0xFF6B7280),
                            ),
                            label: 'Other email',
                            value: card.secondaryEmail,
                            onTap:
                                () => _open(
                                  card.secondaryEmail,
                                  prefix: 'mailto:',
                                ),
                          ),
                        if (card.website.trim().isNotEmpty)
                          _ContactRow(
                            icon: const FaIcon(
                              FontAwesomeIcons.globe,
                              size: 16,
                              color: Color(0xFF6B7280),
                            ),
                            label: 'Website',
                            value: card.website,
                            onTap: () => _open(card.website),
                          ),
                        if (card.companyWebsite.trim().isNotEmpty &&
                            card.companyWebsite.trim() != card.website.trim())
                          _ContactRow(
                            icon: const FaIcon(
                              FontAwesomeIcons.building,
                              size: 16,
                              color: Color(0xFF6B7280),
                            ),
                            label: 'Company website',
                            value: card.companyWebsite,
                            onTap: () => _open(card.companyWebsite),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Powered by WBC-QR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.outline,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _open(String raw, {String? prefix}) async {
    final value = raw.trim();
    if (value.isEmpty) return;

    Uri? uri;
    if (prefix != null && !value.contains('://')) {
      uri = Uri.tryParse('$prefix${Uri.encodeComponent(value)}');
    } else if (!value.contains('://')) {
      uri = Uri.tryParse('https://$value');
    } else {
      uri = Uri.tryParse(value);
    }
    if (uri == null) return;
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.card});

  final DigitalCard card;

  @override
  Widget build(BuildContext context) {
    final actions = <_Action>[
      if (card.primaryPhone.trim().isNotEmpty)
        _Action(
          (color) => FaIcon(FontAwesomeIcons.phone, size: 18, color: color),
          'Call',
          () => DigitalCardView._open(card.primaryPhone, prefix: 'tel:'),
        ),
      if (card.whatsapp.trim().isNotEmpty)
        _Action(
          (color) => FaIcon(FontAwesomeIcons.whatsapp, size: 18, color: color),
          'WhatsApp',
          () {
            final raw = card.whatsapp.trim();
            final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
            final target = raw.contains('://') ? raw : 'https://wa.me/$digits';
            return DigitalCardView._open(target);
          },
        ),
      if (card.primaryEmail.trim().isNotEmpty)
        _Action(
          (color) => FaIcon(FontAwesomeIcons.envelope, size: 18, color: color),
          'Email',
          () => DigitalCardView._open(card.primaryEmail, prefix: 'mailto:'),
        ),
      if (card.website.trim().isNotEmpty)
        _Action(
          (color) => FaIcon(FontAwesomeIcons.globe, size: 18, color: color),
          'Website',
          () => DigitalCardView._open(card.website),
        ),
      if (card.hasAddress)
        _Action(
          (color) =>
              FaIcon(FontAwesomeIcons.locationDot, size: 18, color: color),
          'Map',
          () => DigitalCardView._open(card.mapUrl),
        ),
      if (card.linkedin.trim().isNotEmpty)
        _Action(
          (color) =>
              FaIcon(FontAwesomeIcons.linkedinIn, size: 18, color: color),
          'LinkedIn',
          () => DigitalCardView._open(card.linkedin),
        ),
      if (card.instagram.trim().isNotEmpty)
        _Action(
          (color) => FaIcon(FontAwesomeIcons.instagram, size: 18, color: color),
          'Instagram',
          () => DigitalCardView._open(card.instagram),
        ),
      if (card.twitter.trim().isNotEmpty)
        _Action(
          (color) => FaIcon(FontAwesomeIcons.xTwitter, size: 18, color: color),
          'X',
          () => DigitalCardView._open(card.twitter),
        ),
      if (card.facebook.trim().isNotEmpty)
        _Action(
          (color) => FaIcon(FontAwesomeIcons.facebookF, size: 18, color: color),
          'Facebook',
          () => DigitalCardView._open(card.facebook),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            actions
                .map(
                  (action) =>
                      SizedBox(width: 92, child: _ActionTile(action: action)),
                )
                .toList(),
      ),
    );
  }
}

class _Action {
  const _Action(this.iconBuilder, this.label, this.onTap);

  final Widget Function(Color color) iconBuilder;
  final String label;
  final Future<void> Function() onTap;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});

  final _Action action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            action.iconBuilder(scheme.primary),
            const SizedBox(height: 6),
            Text(
              action.label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final String value;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
