import 'package:share_plus/share_plus.dart';

import '../models/digital_card.dart';
import 'digital_card_service.dart';

/// Opens the platform share sheet so the user can choose WhatsApp, social
/// apps, email, messages, or any other app installed on the phone.
class CardShareService {
  CardShareService({SharePlus? share, DigitalCardService? analytics})
    : _share = share ?? SharePlus.instance,
      _analytics = analytics ?? DigitalCardService();

  final SharePlus _share;
  final DigitalCardService _analytics;

  static String buildShareText(DigitalCard card) {
    final lines = <String>[card.displayName];

    final role = [
      card.jobTitle.trim(),
      card.companyName.trim(),
    ].where((value) => value.isNotEmpty).join(' · ');
    if (role.isNotEmpty) lines.add(role);

    final phone = [
      card.primaryPhone.trim(),
      card.secondaryPhone.trim(),
    ].where((value) => value.isNotEmpty).join(' / ');
    if (phone.isNotEmpty) lines.add('Phone: $phone');

    final email = [
      card.primaryEmail.trim(),
      card.secondaryEmail.trim(),
    ].where((value) => value.isNotEmpty).join(' / ');
    if (email.isNotEmpty) lines.add('Email: $email');

    final website =
        card.website.trim().isNotEmpty
            ? card.website.trim()
            : card.companyWebsite.trim();
    if (website.isNotEmpty) lines.add('Website: $website');

    if (card.publicSlug.isNotEmpty) {
      lines
        ..add('')
        ..add(DigitalCardService.cardUrl(card.publicSlug));
    }

    return lines.join('\n');
  }

  Future<ShareResult> shareCard(DigitalCard card) async {
    final result = await _share.share(
      ShareParams(
        text: buildShareText(card),
        title: 'Share ${card.displayName}',
        subject: '${card.displayName} digital card',
      ),
    );

    final slug = card.publicSlug;
    if (slug.isNotEmpty) {
      await _analytics.logEvent(slug, 'share');
    }
    return result;
  }
}
