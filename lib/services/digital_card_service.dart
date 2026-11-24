import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/digital_card.dart';

class CardSaveResult {
  const CardSaveResult({required this.id, required this.slug});

  final String id;
  final String slug;
}

/// Persists private card drafts and public, published card snapshots.
class DigitalCardService {
  DigitalCardService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  /// Fallback origin for QR codes generated from a desktop/mobile app.
  static const String fallbackOrigin = 'https://wbc-qr.web.app';

  static const Set<String> _allowedEventTypes = <String>{
    'view',
    'save',
    'share',
  };

  FirebaseFirestore? _store() {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static String cardUrl(String slug) {
    final origin = kIsWeb ? Uri.base.origin : fallbackOrigin;
    return '$origin/c/${Uri.encodeComponent(slug)}';
  }

  static String makeSlug(String fullName) {
    final slug = fullName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    if (slug.isEmpty) return 'card';
    return slug.length > 40
        ? slug.substring(0, 40).replaceAll(RegExp(r'-$'), '')
        : slug;
  }

  /// Deterministic slug: the unique Firestore id prevents cross-user races
  /// without a check-then-write window.
  static String slugForCard(String fullName, String cardId) {
    final tokenSource =
        cardId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    final token =
        tokenSource.isEmpty
            ? 'card'
            : tokenSource.substring(
              tokenSource.length > 6 ? tokenSource.length - 6 : 0,
            );
    final base = makeSlug(fullName);
    final maxBase = 40 - token.length - 1;
    final trimmedBase =
        base.length > maxBase
            ? base.substring(0, maxBase).replaceAll(RegExp(r'-$'), '')
            : base;
    return '$trimmedBase-$token';
  }

  /// Last-resort deterministic slug that is independent of the display name.
  /// Firestore ids are unique enough that this cannot normally collide.
  static String stableFallbackSlug(String cardId) {
    final token = cardId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final short =
        token.length > 32 ? token.substring(token.length - 32) : token;
    return short.isEmpty ? 'card' : 'card-$short';
  }

  // Legacy published cards can contain uppercase id tokens, so accept both
  // cases when reading/validating existing links. New slugs are lowercased.
  static bool _validSlug(String value) =>
      RegExp(r'^[a-zA-Z0-9-]{1,40}$').hasMatch(value);

  DocumentReference<Map<String, dynamic>> _privateRef(
    String uid,
    String cardId,
  ) {
    return _store()!
        .collection('users')
        .doc(uid)
        .collection('cards')
        .doc(cardId);
  }

  DocumentReference<Map<String, dynamic>> _publicRef(String slug) {
    return _store()!.collection('publicCards').doc(slug);
  }

  /// Kept for compatibility with older callers. Publishes now use deterministic
  /// slugs, but this still re-checks the final candidate.
  Future<String> uniqueSlug(String desired) async {
    final fs = _store();
    if (fs == null) return _validSlug(desired) ? desired : 'card';

    var candidate = _validSlug(desired) ? desired : 'card';
    for (var attempt = 2; attempt < 100; attempt++) {
      final snap = await fs.collection('publicCards').doc(candidate).get();
      if (!snap.exists) return candidate;
      final suffix = '-$attempt';
      final base =
          candidate.length + suffix.length > 40
              ? candidate.substring(0, 40 - suffix.length)
              : candidate;
      candidate = '$base$suffix';
    }
    return stableFallbackSlug(DateTime.now().microsecondsSinceEpoch.toString());
  }

  bool _publicDocMatches({
    required Map<String, dynamic>? data,
    required String uid,
    required String cardId,
    required String slug,
  }) {
    if (data == null || data['ownerId'] != uid || data['isPublished'] != true) {
      return false;
    }
    final storedId = data['id'];
    return storedId == null || storedId == cardId || storedId == slug;
  }

  /// Reuses a legacy/custom slug only when it already points to this card.
  Future<String?> _reusableSlug({
    required String preferred,
    required String uid,
    required String cardId,
  }) async {
    if (!_validSlug(preferred)) return null;
    final snap = await _publicRef(preferred).get();
    if (!snap.exists) return null;
    return _publicDocMatches(
          data: snap.data(),
          uid: uid,
          cardId: cardId,
          slug: preferred,
        )
        ? preferred
        : null;
  }

  Future<String> _resolvePublishSlug({
    required String uid,
    required String cardId,
    required String fullName,
    required String preferred,
  }) async {
    final reusable = await _reusableSlug(
      preferred: preferred,
      uid: uid,
      cardId: cardId,
    );
    if (reusable != null) return reusable;

    final generated = <String>[
      slugForCard(fullName, cardId),
      stableFallbackSlug(cardId),
    ];
    for (final candidate in generated) {
      final snap = await _publicRef(candidate).get();
      if (!snap.exists) return candidate;
      if (_publicDocMatches(
        data: snap.data(),
        uid: uid,
        cardId: cardId,
        slug: candidate,
      )) {
        return candidate;
      }
    }

    // Only reachable if somebody pre-created every deterministic candidate.
    for (var attempt = 0; attempt < 5; attempt++) {
      final candidate = slugForCard(
        'card-${DateTime.now().microsecondsSinceEpoch}-$attempt',
        cardId,
      );
      final snap = await _publicRef(candidate).get();
      if (!snap.exists) return candidate;
    }
    return slugForCard('card-${DateTime.now().microsecondsSinceEpoch}', cardId);
  }

  Future<List<DocumentReference<Map<String, dynamic>>>> _ownedPublicRefs({
    required String uid,
    required String cardId,
    required String fullName,
    Iterable<String> extraSlugs = const <String>[],
  }) async {
    final refs = <DocumentReference<Map<String, dynamic>>>[];
    final seen = <String>{};
    final candidates = <String>[
      ...extraSlugs,
      slugForCard(fullName, cardId),
      stableFallbackSlug(cardId),
    ];

    for (final slug in candidates) {
      if (!_validSlug(slug) || !seen.add(slug)) continue;
      final ref = _publicRef(slug);
      final snap = await ref.get();
      if (!snap.exists || snap.data()?['ownerId'] != uid) continue;
      final storedId = snap.data()?['id'];
      if (storedId is String &&
          storedId.isNotEmpty &&
          storedId != cardId &&
          storedId != slug) {
        continue;
      }
      refs.add(ref);
    }
    return refs;
  }

  static DateTime _sortTime(DigitalCard card) =>
      card.updatedAt ??
      card.createdAt ??
      DateTime.fromMillisecondsSinceEpoch(0);

  Stream<List<DigitalCard>> watchCards(String uid) {
    final fs = _store();
    if (fs == null) return Stream<List<DigitalCard>>.value(<DigitalCard>[]);
    return fs.collection('users').doc(uid).collection('cards').snapshots().map((
      snap,
    ) {
      // Do not use orderBy('updatedAt'): legacy documents without that field
      // are silently excluded by Firestore and would vanish from the list.
      final cards = snap.docs
          .map(DigitalCard.fromFirestore)
          .toList(growable: false)
        ..sort((a, b) => _sortTime(b).compareTo(_sortTime(a)));
      return cards;
    });
  }

  Future<DigitalCard?> getCard(String uid, String cardId) async {
    final fs = _store();
    if (fs == null) return null;
    final snap = await _privateRef(uid, cardId).get();
    if (!snap.exists) return null;
    return DigitalCard.fromFirestore(snap);
  }

  /// Saves a draft and returns its document id (generating one if needed).
  ///
  /// Editing an already-published card also refreshes its public snapshot, so
  /// the private document can never claim to be published while the live page
  /// still serves stale content.
  Future<String> saveCard({
    required String uid,
    required DigitalCard card,
  }) async {
    if (card.isPublished) {
      final result = await publish(uid: uid, card: card);
      return result.id;
    }

    final fs = _store();
    if (fs == null) throw StateError('Firestore is not available.');

    final isNew = card.id.isEmpty;
    final newId = fs.collection('users').doc(uid).collection('cards').doc().id;
    final ref = _privateRef(uid, isNew ? newId : card.id);
    final data = card.copyWith(ownerId: uid).toMap();

    final existing = await ref.get();
    if (!existing.exists || existing.data()?['createdAt'] == null) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    await ref.set(data, SetOptions(merge: true));
    return ref.id;
  }

  /// Publishes a card to the public snapshot used by `/c/{slug}`.
  Future<CardSaveResult> publish({
    required String uid,
    required DigitalCard card,
  }) async {
    final fs = _store();
    if (fs == null) throw StateError('Firestore is not available.');

    final id =
        card.id.isNotEmpty
            ? card.id
            : fs.collection('users').doc(uid).collection('cards').doc().id;

    final slug = await _resolvePublishSlug(
      uid: uid,
      cardId: id,
      fullName: card.fullName,
      preferred: card.slug,
    );

    final published = card.copyWith(
      id: id,
      ownerId: uid,
      slug: slug,
      isPublished: true,
    );

    final privateRef = _privateRef(uid, id);
    final privateSnap = await privateRef.get();
    final privateData = published.toMap();
    if (!privateSnap.exists || privateSnap.data()?['createdAt'] == null) {
      privateData['createdAt'] = FieldValue.serverTimestamp();
    }

    final publicRef = _publicRef(slug);
    final publicSnap = await publicRef.get();
    final publicData = published.toMap();
    if (publicSnap.exists && publicSnap.data()?['createdAt'] != null) {
      publicData['createdAt'] = publicSnap.data()!['createdAt'];
    } else {
      publicData['createdAt'] = FieldValue.serverTimestamp();
    }

    // One atomic batch. A failed public write must not leave a private draft
    // falsely marked as published.
    final batch =
        fs.batch()
          ..set(privateRef, privateData, SetOptions(merge: true))
          ..set(publicRef, publicData);
    await batch.commit();

    return CardSaveResult(id: id, slug: slug);
  }

  Future<void> unpublish({
    required String uid,
    required String cardId,
    required String slug,
    String? fullName,
  }) async {
    final fs = _store();
    if (fs == null) return;

    final privateRef = _privateRef(uid, cardId);
    final privateSnap = await privateRef.get();
    final storedSlug = _slugFromData(privateSnap.data());
    final publicRefs = await _ownedPublicRefs(
      uid: uid,
      cardId: cardId,
      fullName: fullName ?? _stringFromData(privateSnap.data(), 'fullName'),
      extraSlugs: <String>[storedSlug, slug],
    );

    final batch =
        fs.batch()..set(privateRef, <String, dynamic>{
          'isPublished': false,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    for (final ref in publicRefs) {
      batch.delete(ref);
    }
    await batch.commit();
  }

  Future<void> deleteCard({
    required String uid,
    required String cardId,
    String? slug,
    String? fullName,
  }) async {
    final fs = _store();
    if (fs == null) return;

    final privateRef = _privateRef(uid, cardId);
    final privateSnap = await privateRef.get();
    final storedSlug = _slugFromData(privateSnap.data());
    final publicRefs = await _ownedPublicRefs(
      uid: uid,
      cardId: cardId,
      fullName: fullName ?? _stringFromData(privateSnap.data(), 'fullName'),
      extraSlugs: <String>[storedSlug, slug ?? ''],
    );

    final batch = fs.batch()..delete(privateRef);
    for (final ref in publicRefs) {
      batch.delete(ref);
    }
    await batch.commit();
  }

  static String _stringFromData(Map<String, dynamic>? data, String key) {
    final value = data?[key];
    return value is String ? value : '';
  }

  static String _slugFromData(Map<String, dynamic>? data) {
    final value = data?['slug'];
    return value is String && _validSlug(value) ? value : '';
  }

  Future<DigitalCard?> getPublicCard(String slug) async {
    final fs = _store();
    if (fs == null || !_validSlug(slug)) return null;
    final snap = await _publicRef(slug).get();
    if (!snap.exists) return null;
    final card = DigitalCard.fromFirestore(snap);
    return card.isPublished ? card : null;
  }

  /// Best-effort analytics. Never let analytics break the card view.
  Future<void> logEvent(String slug, String type) async {
    final fs = _store();
    if (fs == null || !_validSlug(slug) || !_allowedEventTypes.contains(type)) {
      return;
    }
    try {
      await _publicRef(slug).collection('events').add(<String, dynamic>{
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}
