# Firebase Remote Config setup

The live app loads Supabase settings from Firebase Remote Config at startup. This keeps the values out of the compiled JavaScript bundle and removes the need to edit `.env` on the deployed site.

> Use a **publishable** (`sb_publishable_…`) or legacy **anon** key only. Never put a Supabase `service_role` key in Remote Config — it bypasses Row Level Security and is a secret.

## Steps

1. Firebase Console → **Build** → **Remote Config**.
2. Add these parameters:

| Parameter | Value |
| --- | --- |
| `SUPABASE_URL` | `https://<your-project>.supabase.co` |
| `SUPABASE_PUBLISHABLE_KEY` | Your `sb_publishable_…` key |
| `SUPABASE_ANON_KEY` | Optional fallback if you use a legacy anon JWT |
| `SUPABASE_STORAGE_BUCKET` | `QR-bucket` |
| `SUPABASE_CARD_ASSETS_BUCKET` | `card-assets` |

3. Click **Publish changes**.
4. Run `supabase/storage_setup.sql` and `supabase/card_assets_setup.sql` in the Supabase SQL Editor. `QR-bucket` stays private for expiring signed URLs; `card-assets` is public for card photos/logos.
5. Rebuild and redeploy the Flutter web app.

## Resolution order

The app resolves each value in this order:

1. Firebase Remote Config
2. `--dart-define=...` build arguments
3. Local `.env` asset (development fallback)

If Remote Config is empty or unreachable, the app falls back to the other sources and remains usable.
