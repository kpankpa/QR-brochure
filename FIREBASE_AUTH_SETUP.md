# 🔐 Firebase Auth Setup Guide

**Authentication**: Firebase only (no Supabase auth required)  
**Storage**: Supabase (public upload, Firebase tracks ownership)

---

## ✅ Step 1: Enable Firebase Anonymous Authentication

**Required** - Allows users to upload files without email/password

1. Go to [Firebase Console](https://console.firebase.google.com/project/wbc-qr/authentication/providers)

2. Click **"Anonymous"** provider

3. Toggle **"Enable"** → Click **"Save"**

   ✅ **This fixes the "restricted to administrators only" error**

---

## ✅ Step 2: (Optional) Enable Firebase Email/Password

**Optional** - For users who want to sign in with email

1. In the same [Authentication Providers](https://console.firebase.google.com/project/wbc-qr/authentication/providers) page

2. Click **"Email/Password"** provider

3. Toggle **"Enable"** → Click **"Save"**

---

## ✅ Step 3: Deploy Firestore Rules

**Required** - Secures your database

### Option A: Firebase CLI (Recommended)
```bash
firebase deploy --only firestore:rules
```

### Option B: Firebase Console
1. Go to [Firestore Rules](https://console.firebase.google.com/project/wbc-qr/firestore/rules)
2. Copy content from [firestore.rules](firestore.rules)
3. Paste and click **"Publish"**

---

## ✅ Step 4: Configure Supabase Storage (No Auth)

**Required** - Allows file uploads using Firebase auth only

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard/project/qjaavrisvfiqhqklfebn)

2. Navigate to **SQL Editor**

3. Click **"New query"**

4. Copy the entire content from [supabase/storage_policies_PUBLIC.sql](supabase/storage_policies_PUBLIC.sql)

5. Paste and click **"Run"**

   ✅ **This removes Supabase authentication requirement**

6. Go to **Storage** → Verify **"QR-bucket"** is marked as **Public**

---

## ✅ Step 5: Test the App

```bash
# Clean rebuild
flutter clean
flutter pub get
flutter run
```

### Test Flow:
1. ✅ App launches
2. ✅ Switch to **"File"** tab
3. ✅ Pick a PDF or image
4. ✅ Click **"Upload & Generate QR"**
5. ✅ QR code appears (using Firebase auth, no Supabase auth!)
6. ✅ Check history drawer

---

## 🎯 What Changed

### Before:
- ❌ Required both Firebase AND Supabase authentication
- ❌ "Supabase anonymous sign-in failed" errors
- ❌ Complex dual-auth setup

### After:
- ✅ **Firebase Auth only** (anonymous + email/password)
- ✅ Supabase Storage with public upload policies
- ✅ Files organized by Firebase user ID
- ✅ Simple, single authentication system

---

## 📋 Rules Summary

### Firestore Rules ([firestore.rules](firestore.rules))
```
✅ Users can only read/write their own brochure history
✅ Validates data structure (downloadUrl, fileName required)
✅ Denies all other access by default
```

### Supabase Storage Policies ([supabase/storage_policies_PUBLIC.sql](supabase/storage_policies_PUBLIC.sql))
```
✅ Public read (QR codes work without login)
✅ Public upload (no Supabase auth needed)
✅ Files organized by Firebase user ID
```

### Firebase Storage Rules ([storage.rules](storage.rules))
```
📌 Optional - if you want to use Firebase Storage instead
✅ Public read for QR codes
✅ Users upload to /users/{userId}/ folder
✅ File size limit: 10MB
✅ Allowed types: images and PDFs
```

---

## 🔄 Alternative: Switch to Firebase Storage

If you prefer Firebase Storage instead of Supabase:

1. Deploy storage rules:
   ```bash
   firebase deploy --only storage
   ```

2. Update `.env` to use Firebase Storage (requires code changes)

**Current setup uses Supabase Storage** (simpler, already configured)

---

## 🐛 Troubleshooting

### "Firebase sign-in failed: This operation is restricted to administrators only"
**Fix**: Enable Anonymous Authentication in Firebase Console (Step 1)

### "Supabase upload failed"
**Fix**: Run the SQL from `storage_policies_PUBLIC.sql` in Supabase (Step 4)

### Upload works but history doesn't show
**Fix**: Deploy Firestore rules (Step 3)

### Need to clear and rebuild
```bash
flutter clean
flutter pub get
flutter run
```

---

## ✅ Checklist

- [ ] Firebase Anonymous Auth enabled
- [ ] Firebase Email/Password Auth enabled (optional)
- [ ] Firestore rules deployed
- [ ] Supabase storage policies executed
- [ ] App rebuilt and tested
- [ ] File upload works
- [ ] QR code generates
- [ ] History shows uploads

---

## 🎉 Done!

Your app now uses:
- **Firebase** for all authentication
- **Supabase** for file storage (no auth required)
- **Firestore** for tracking upload history

No more Supabase authentication errors! 🚀
