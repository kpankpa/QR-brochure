# 🚀 Setup Checklist

## ✅ Completed
- [x] Flutter project structure
- [x] Dependencies installed
- [x] Firebase configuration
- [x] Supabase configuration
- [x] `.env` file configured

## ⚠️ Required Setup Steps

### 1. Firebase Console Setup
**URL**: https://console.firebase.google.com/project/wbc-qr

#### Enable Authentication:
1. Go to **Authentication** → **Sign-in method**
2. Enable **Anonymous** ✅ **(REQUIRED for file uploads)**
   - Click "Anonymous" provider
   - Toggle to **Enabled**
   - Click Save
3. Enable **Email/Password** (optional but recommended)
   - Click "Email/Password" provider
   - Toggle to **Enabled**
   - Click Save

#### Deploy Firestore Rules:
```bash
firebase deploy --only firestore:rules
```

Or manually copy rules from [firestore.rules](firestore.rules) to Firebase Console → Firestore Database → Rules

---

### 2. Supabase Dashboard Setup
**URL**: https://supabase.com/dashboard/project/qjaavrisvfiqhqklfebn

#### Enable Anonymous Sign-in:
1. Go to **Authentication** → **Providers**
2. Find **Anonymous sign-in**
3. Toggle to **ON** ✅
4. Save

#### Setup Storage Policies:
1. Go to **SQL Editor**
2. Click **New query**
3. Copy contents from [supabase/storage_policies_QR_bucket.sql](supabase/storage_policies_QR_bucket.sql)
4. Click **Run**

#### Verify Bucket:
1. Go to **Storage**
2. Confirm bucket **QR-bucket** exists and is **public**
3. If not, create it:
   - Name: `QR-bucket`
   - Public: ✅ YES

---

### 3. Test the App

After completing Firebase & Supabase setup:

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

**Test Flow:**
1. ✅ App launches without errors
2. ✅ Click "File" tab
3. ✅ Pick a PDF or image
4. ✅ Click "Upload & Generate QR"
5. ✅ QR code appears
6. ✅ Click history drawer to see uploaded files

---

## 🐛 Troubleshooting

### "Firebase sign-in failed: This operation is restricted to administrators only"
**Fix**: Enable Anonymous Authentication in Firebase Console (see Step 1 above)

### "Supabase is not configured"
**Fix**: Restart app after editing `.env` file:
```bash
flutter clean
flutter run
```

### "Supabase anonymous sign-in failed"
**Fix**: Enable Anonymous sign-in in Supabase Dashboard (see Step 2 above)

### QR code shows but upload fails
**Fix**: Run storage policies SQL in Supabase SQL Editor (see Step 2 above)

---

## 📝 Environment Variables

Your [.env](.env) file should contain:
```env
SUPABASE_URL=https://qjaavrisvfiqhqklfebn.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_Y-zIzF5O5gqjlucX80md3w_r7tGfSio
SUPABASE_STORAGE_BUCKET=QR-bucket
```

✅ Already configured!

---

## 🎯 Current Status

**What works:**
- ✅ App launches
- ✅ UI displays correctly
- ✅ Link QR codes work (no auth needed)

**What needs setup:**
- ⚠️ Firebase Anonymous Auth (for file uploads)
- ⚠️ Supabase Anonymous Auth (for storage)
- ⚠️ Supabase Storage Policies (for security)

**Once setup is complete:**
- ✅ File uploads to Supabase Storage
- ✅ QR codes for uploaded files
- ✅ Upload history tracking
- ✅ Multi-user support

---

## 📞 Quick Links

- [Firebase Console](https://console.firebase.google.com/project/wbc-qr)
- [Supabase Dashboard](https://supabase.com/dashboard/project/qjaavrisvfiqhqklfebn)
- [Firebase Auth Docs](https://firebase.google.com/docs/auth/web/anonymous-auth)
- [Supabase Storage Docs](https://supabase.com/docs/guides/storage)
