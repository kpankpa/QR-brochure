# Digital vCard / Business Card Feature — Phased Plan

Goal: when someone scans a QR generated in WBC-QR, they see a professional, branded digital business card with phone numbers, email, address + View on map, website, socials, company and colleagues — and can save everything to their contacts in one tap.

## Recommended architecture

The QR encodes a hosted card URL (`https://wbc-qr.web.app/c/{slug}`), not raw vCard text. The hosted page is public, mobile-first and editable without reprinting. A **Save contact** button generates a `.vcf` (vCard 3.0) on the device. An optional static vCard QR can be added later for offline use.

Reference analysis: HiHello's editor requires login, so their public FAQ/feature pages were reviewed. `qr.com` was unreachable; GetQR's vCard documentation was used for standard vCard field behaviour.

---

## Phase 1 — MVP (implemented in this repo)

- [x] `DigitalCard` model + Firestore mapping (private drafts and public snapshot).
- [x] `DigitalCardService` for create/update/publish/delete/watch + public fetch + scan events.
- [x] Unique vanity slug generation (`/c/{slug}`).
- [x] Multi-section card editor (name, title, company, 2 phones, WhatsApp, 2 emails, address, website, socials, summary, brand colour, photo/logo uploads).
- [x] Cards tab in the dashboard (create, edit, preview, copy link, download QR, publish/unpublish, delete).
- [x] Public `/c/{slug}` page that bypasses Firebase Auth gate.
- [x] `VcardService` — vCard 3.0 generation with escaping and line folding.
- [x] `.vcf` download on web and desktop/mobile via platform downloaders.
- [x] Third QR source: **Contact** (reuses the existing QR preview/download pipeline).
- [x] Firestore rules for private cards, public published snapshots and anonymous scan events.

### Phase 1 verification checklist (run when Flutter SDK is available)

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build web`
- Manual: sign in → Cards → New card → fill → Publish → copy link → open `/c/{slug}` in a private window → Save contact → verify `.vcf` opens in Contacts.
- Manual: Upload tab → Contact → choose published card → QR scans to `/c/{slug}`.
- Deploy rules: `firebase deploy --only firestore:rules`

---

## Phase 2 — Company + staff + editor upgrade (in progress)

- [x] Image uploads for photo/logo into a dedicated public `card-assets` Supabase bucket (the `QR-bucket` is private + signed/expiring, unsuitable for public card images).
- [x] Icon picker stored on the card (`iconName`) and rendered on the public card.
- [x] Brand colour picker with preset swatches + custom hex value.
- [x] Modern editor UI: grouped sections, upload tiles, helper text, live preview and sticky actions.
- [x] Public card shows logo, photo, company icon, both numbers, both emails, address + View on map, website, company website and social quick actions.
- [x] Real brand icons for website, map pin, LinkedIn, Instagram, X, Facebook and WhatsApp on the final card.
- [ ] `companies/{companyId}` profile: name, logo, brand kit, website, address, about.
- [ ] Reusable company template applied to member cards (brand lock for teams).
- [ ] “Other staff” / team section on the public card, linking to colleagues' cards.
- [ ] Company directory route `/company/{companyId}` with searchable member cards.

### Required live setup for uploads

- Add `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` (or `SUPABASE_ANON_KEY`) as Firebase Remote Config parameters. See `REMOTE_CONFIG_SETUP.md`.
- Run `supabase/card_assets_setup.sql` in the Supabase SQL Editor to create the public `card-assets` bucket and policies.
- Rebuild web and redeploy Hosting after credentials are published. `.env` and `--dart-define` remain fallback sources for local development.

---

## Phase 3 — Insights + polish

- [ ] Scan analytics dashboard (views, saves, taps per card) from `publicCards/{slug}/events`.
- [ ] Firebase App Check enforcement on card writes/events.
- [ ] Static vCard QR export option (offline, no updates) as an explicit user choice.
- [ ] Custom domain / prettier vanity URLs + social share metadata.
- [x] Reliable QR renderer: classic square modules by default, optional modern rounded style, four-module quiet zone, single-pass rendering, and centred logo plate with adaptive error correction.
- [x] Exported PNGs include 300 DPI pHYs metadata so they open at a sensible physical size in Word, WhatsApp, email and print dialogs.
- [x] Preview and download use the same renderer, style and selected resolution (512 / 1024 / 2048 px), so the image matches exactly.
- [x] Adjustable logo-size slider (16–32%) with a live preview.
- [x] Fixed blank “New digital card” screen caused by notifying provider listeners during the provider's first build.
- [x] Added a visible error boundary and hardened the public card's “Create your card” / vCard save paths so failures show a message instead of a blank screen.
- [x] Disabled Flutter's web service worker and added a one-time cleanup script so stale cached builds cannot keep showing the old blank card editor.
- [x] Publish reliability fix: force `ownerId` from the signed-in user, show detailed publish errors, and fall back to sequential writes if a batch is rejected.
- [x] Supabase config loaded from Firebase Remote Config on the live app.
- [ ] Multiple cards per user (already data-model ready), card templates, QR styling presets.

---

## Files touched in Phase 1

New:
- `lib/models/digital_card.dart`
- `lib/services/digital_card_service.dart`
- `lib/services/vcard_service.dart`
- `lib/view_models/digital_card_view_model.dart`
- `lib/views/cards/cards_tab.dart`
- `lib/views/cards/card_editor_screen.dart`
- `lib/views/cards/digital_card_view.dart`
- `lib/views/public/public_card_screen.dart`
- `lib/views/qr_brochure/contact_source_panel.dart`

Modified:
- `lib/main.dart`
- `lib/models/source_kind.dart`
- `lib/screens/home_screen.dart`
- `lib/view_models/qr_brochure_view_model.dart`
- `lib/views/qr_brochure/qr_brochure_view.dart`
- `lib/views/qr_brochure/qr_preview_card.dart`
- `lib/services/qr_downloader_{io,web,stub}.dart`
- `firestore.rules`
