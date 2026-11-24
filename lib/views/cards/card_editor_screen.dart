import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/card_icon.dart';
import '../../models/digital_card.dart';
import '../../services/digital_card_service.dart';
import '../../view_models/auth_controller.dart';
import '../../view_models/digital_card_view_model.dart';
import 'digital_card_view.dart';

class CardEditorScreen extends StatelessWidget {
  const CardEditorScreen({super.key, this.card});

  final DigitalCard? card;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => DigitalCardViewModel(
            card: card,
            service: context.read<DigitalCardService>(),
          ),
      child: _CardEditorBody(card: card),
    );
  }
}

class _CardEditorBody extends StatefulWidget {
  const _CardEditorBody({required this.card});

  final DigitalCard? card;

  @override
  State<_CardEditorBody> createState() => _CardEditorBodyState();
}

class _CardEditorBodyState extends State<_CardEditorBody> {
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _line = Color(0xFFE2E8F0);

  late final DigitalCardViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = context.read<DigitalCardViewModel>();
    _vm.bindNotice(_showNotice);
  }

  void _showNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _field(
    DigitalCardViewModel vm,
    String key,
    String label,
    IconData icon, {
    Color accent = const Color(0xFF2E6AE6),
    TextInputType? keyboardType,
    int maxLines = 1,
    String? helper,
    ValueChanged<String>? onChanged,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _line),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: vm.controller(key),
        keyboardType: keyboardType,
        maxLines: maxLines,
        autocorrect: false,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 2,
          prefixIcon: Icon(icon, size: 20, color: accent),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: accent, width: 1.6),
          ),
        ),
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color accent,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 12, color: _muted),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _imageTile({
    required DigitalCardViewModel vm,
    required String fieldKey,
    required String title,
    required String hint,
    required IconData icon,
    required bool isLogo,
    required bool uploading,
    required Color accent,
    required String uid,
  }) {
    final url = vm.controller(fieldKey).text.trim();
    final preview =
        isLogo
            ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 64,
                height: 64,
                color: accent.withValues(alpha: 0.10),
                child:
                    url.isEmpty
                        ? Icon(icon, color: accent, size: 26)
                        : Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (_, __, ___) =>
                                  Icon(icon, color: accent, size: 26),
                        ),
              ),
            )
            : CircleAvatar(
              radius: 32,
              backgroundColor: accent.withValues(alpha: 0.12),
              child:
                  url.isEmpty
                      ? Icon(icon, color: accent, size: 26)
                      : ClipOval(
                        child: Image.network(
                          url,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) =>
                                  Icon(icon, color: accent, size: 26),
                        ),
                      ),
            );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          preview,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  url.isEmpty ? hint : 'Image ready to publish',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: _muted),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed:
                          uploading
                              ? null
                              : () {
                                if (uid.isEmpty) {
                                  _showNotice(
                                    'Please sign in to upload images.',
                                  );
                                  return;
                                }
                                vm.uploadImage(fieldKey, uid: uid);
                              },
                      icon:
                          uploading
                              ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: accent,
                                ),
                              )
                              : Icon(Icons.upload_rounded, size: 16),
                      label: Text(
                        uploading
                            ? 'Uploading…'
                            : url.isEmpty
                            ? 'Upload'
                            : 'Change',
                      ),
                    ),
                    if (url.isNotEmpty)
                      TextButton.icon(
                        onPressed:
                            uploading ? null : () => vm.removeImage(fieldKey),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                        ),
                        label: const Text('Remove'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconPicker({
    required DigitalCardViewModel vm,
    required Color accent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Card icon',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              CardIcons.options.map((option) {
                final selected = vm.iconName == option.name;
                return ChoiceChip(
                  avatar: Icon(
                    option.icon,
                    size: 17,
                    color: selected ? Colors.white : accent,
                  ),
                  label: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                  selected: selected,
                  showCheckmark: false,
                  backgroundColor: const Color(0xFFF1F5F9),
                  selectedColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: selected ? accent : _line),
                  ),
                  onSelected: (_) => vm.selectIcon(option.name),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _colorPicker({
    required DigitalCardViewModel vm,
    required Color accent,
  }) {
    const presets = <Color>[
      Color(0xFF2E6AE6),
      Color(0xFF7C3AED),
      Color(0xFF0EA5E9),
      Color(0xFF059669),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFFEC4899),
      Color(0xFF111827),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Brand colour',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              presets.map((color) {
                final selected =
                    (color.toARGB32() & 0xFFFFFF) ==
                    (accent.toARGB32() & 0xFFFFFF);
                return GestureDetector(
                  onTap: () => vm.setBrandColor(color),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? _ink : Colors.transparent,
                        width: selected ? 2 : 1,
                      ),
                      boxShadow:
                          selected
                              ? const [
                                BoxShadow(
                                  color: Color(0x330F172A),
                                  blurRadius: 8,
                                ),
                              ]
                              : null,
                    ),
                    child:
                        selected
                            ? const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Colors.white,
                            )
                            : null,
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 14),
        _field(
          vm,
          'brandColor',
          'Hex colour (#RRGGBB)',
          Icons.palette_outlined,
          accent: accent,
          helper: 'Choose a swatch above or type any hex colour.',
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Future<void> _save(DigitalCardViewModel vm, {required bool publish}) async {
    final uid = context.read<AuthController>().user?.uid;
    if (uid == null) {
      _showNotice('Please sign in before saving a card.');
      return;
    }

    final slug = await vm.save(uid: uid, publish: publish);
    if (!mounted) return;

    if (slug == null && vm.error != null) {
      await showDialog<void>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Save failed'),
              content: SelectableText(vm.error!),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    if (publish && slug != null) {
      final url = DigitalCardService.cardUrl(slug);
      final copy = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Card published'),
              content: SelectableText(url),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Close'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy link'),
                ),
              ],
            ),
      );
      if (copy == true) {
        try {
          await Clipboard.setData(ClipboardData(text: url));
          if (mounted) _showNotice('Card link copied');
        } catch (e) {
          if (mounted) _showNotice('Could not copy link: $e');
        }
      }
    }
  }

  void _preview(DigitalCardViewModel vm) {
    final uid = context.read<AuthController>().user?.uid ?? '';
    final card = vm.buildCard(uid);
    showDialog<void>(
      context: context,
      builder:
          (_) => Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 420,
              height: 680,
              child: SingleChildScrollView(
                child: DigitalCardView(card: card, showActions: false),
              ),
            ),
          ),
    );
  }

  @override
  void dispose() {
    _vm.unbindNotice();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DigitalCardViewModel>(
      builder: (context, vm, _) {
        final brand = Color(
          DigitalCardViewModel.parseColor(vm.controller('brandColor').text) ??
              0xFF2E6AE6,
        );
        final dark = Color.lerp(brand, Colors.black, 0.25) ?? brand;
        final uid = context.read<AuthController>().user?.uid ?? '';
        final locked = vm.busy || vm.isUploadingImage;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FB),
          appBar: AppBar(
            title: Text(
              widget.card == null ? 'New digital card' : 'Edit digital card',
            ),
            actions: [
              IconButton(
                tooltip: 'Preview public card',
                icon: const Icon(Icons.visibility_outlined),
                onPressed: () => _preview(vm),
              ),
              const SizedBox(width: 4),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 20,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed:
                            locked ? null : () => _save(vm, publish: false),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save draft'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: brand,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed:
                            locked ? null : () => _save(vm, publish: true),
                        icon:
                            locked
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(Icons.rocket_launch_outlined),
                        label: Text(
                          vm.isPublished ? 'Update live card' : 'Publish card',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [dark, brand],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              CardIcons.iconFor(vm.iconName),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Digital business card',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Upload a photo, pick your icon and brand colour. '
                                  'Everything updates on the public card instantly.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (vm.error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(vm.error!),
                      ),
                    _section(
                      icon: Icons.badge_outlined,
                      title: 'Profile & media',
                      subtitle: 'Photos are uploaded — no links needed.',
                      accent: brand,
                      children: [
                        _imageTile(
                          vm: vm,
                          fieldKey: 'photoUrl',
                          title: 'Profile photo',
                          hint: 'Square image, JPG/PNG/WEBP, max 5 MB',
                          icon: Icons.person_outline,
                          isLogo: false,
                          uploading: vm.uploadingPhoto,
                          accent: brand,
                          uid: uid,
                        ),
                        _imageTile(
                          vm: vm,
                          fieldKey: 'logoUrl',
                          title: 'Company logo',
                          hint: 'Transparent PNG or WEBP works best',
                          icon: Icons.business_outlined,
                          isLogo: true,
                          uploading: vm.uploadingLogo,
                          accent: brand,
                          uid: uid,
                        ),
                        _field(
                          vm,
                          'fullName',
                          'Full name',
                          Icons.person_outline,
                          accent: brand,
                        ),
                        _field(
                          vm,
                          'jobTitle',
                          'Job title',
                          Icons.work_outline_rounded,
                          accent: brand,
                        ),
                        _field(
                          vm,
                          'companyName',
                          'Company name',
                          Icons.business_outlined,
                          accent: brand,
                        ),
                        _field(
                          vm,
                          'companyWebsite',
                          'Company website',
                          Icons.public_outlined,
                          accent: brand,
                          keyboardType: TextInputType.url,
                        ),
                      ],
                    ),
                    _section(
                      icon: Icons.call_outlined,
                      title: 'Contact details',
                      subtitle: 'Shown as tappable actions on the card.',
                      accent: brand,
                      children: [
                        _field(
                          vm,
                          'primaryPhone',
                          'Primary number',
                          Icons.phone_outlined,
                          accent: brand,
                          keyboardType: TextInputType.phone,
                        ),
                        _field(
                          vm,
                          'secondaryPhone',
                          'Other number',
                          Icons.phone_iphone_outlined,
                          accent: brand,
                          keyboardType: TextInputType.phone,
                        ),
                        _field(
                          vm,
                          'whatsapp',
                          'WhatsApp number (with country code)',
                          Icons.chat_bubble_outline_rounded,
                          accent: brand,
                          keyboardType: TextInputType.phone,
                        ),
                        _field(
                          vm,
                          'primaryEmail',
                          'Primary email',
                          Icons.email_outlined,
                          accent: brand,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        _field(
                          vm,
                          'secondaryEmail',
                          'Other email',
                          Icons.alternate_email_rounded,
                          accent: brand,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                    _section(
                      icon: Icons.location_on_outlined,
                      title: 'Address',
                      subtitle: 'Adds a “View on map” action.',
                      accent: brand,
                      children: [
                        _field(
                          vm,
                          'street',
                          'Street address',
                          Icons.streetview_outlined,
                          accent: brand,
                        ),
                        _field(
                          vm,
                          'city',
                          'City',
                          Icons.location_city_outlined,
                          accent: brand,
                        ),
                        _field(
                          vm,
                          'state',
                          'State / region',
                          Icons.map_outlined,
                          accent: brand,
                        ),
                        _field(
                          vm,
                          'postalCode',
                          'Postal code',
                          Icons.markunread_mailbox_outlined,
                          accent: brand,
                        ),
                        _field(
                          vm,
                          'country',
                          'Country',
                          Icons.flag_outlined,
                          accent: brand,
                        ),
                      ],
                    ),
                    _section(
                      icon: Icons.link_rounded,
                      title: 'Links & socials',
                      subtitle: 'Each link becomes an icon tile.',
                      accent: brand,
                      children: [
                        _field(
                          vm,
                          'website',
                          'Website / portfolio',
                          Icons.language_outlined,
                          accent: brand,
                          keyboardType: TextInputType.url,
                        ),
                        _field(
                          vm,
                          'linkedin',
                          'LinkedIn URL',
                          Icons.business_center_outlined,
                          accent: brand,
                          keyboardType: TextInputType.url,
                        ),
                        _field(
                          vm,
                          'instagram',
                          'Instagram URL',
                          Icons.camera_alt_outlined,
                          accent: brand,
                          keyboardType: TextInputType.url,
                        ),
                        _field(
                          vm,
                          'twitter',
                          'X (Twitter) URL',
                          Icons.alternate_email_rounded,
                          accent: brand,
                          keyboardType: TextInputType.url,
                        ),
                        _field(
                          vm,
                          'facebook',
                          'Facebook URL',
                          Icons.facebook_outlined,
                          accent: brand,
                          keyboardType: TextInputType.url,
                        ),
                      ],
                    ),
                    _section(
                      icon: Icons.auto_awesome_outlined,
                      title: 'About & appearance',
                      subtitle: 'Make the card feel like your brand.',
                      accent: brand,
                      children: [
                        _field(
                          vm,
                          'summary',
                          'Short bio',
                          Icons.notes_outlined,
                          accent: brand,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 4),
                        _iconPicker(vm: vm, accent: brand),
                        const SizedBox(height: 18),
                        _colorPicker(vm: vm, accent: brand),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
