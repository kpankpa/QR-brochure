# 📋 Security Rules Quick Reference

## Firebase Firestore Rules

**File**: [firestore.rules](firestore.rules)

**Deploy**: `firebase deploy --only firestore:rules`

```javascript
// Users can only access their own brochure history
match /users/{userId}/brochures/{docId} {
  allow read: if authenticated && request.auth.uid == userId;
  allow create: if authenticated && request.auth.uid == userId;
  allow update: if authenticated && request.auth.uid == userId;
  allow delete: if authenticated && request.auth.uid == userId;
}
```

**Key Points**:
- ✅ Requires Firebase authentication
- ✅ Users can only see their own uploads
- ✅ Validates data structure on create

---

## Firebase Storage Rules (Optional)

**File**: [storage.rules](storage.rules)

**Deploy**: `firebase deploy --only storage`

```javascript
// Public read, authenticated write to own folder
match /users/{userId}/{allPaths=**} {
  allow read: if true;  // Public (for QR codes)
  allow write: if request.auth.uid == userId;  // Own folder only
}
```

**Key Points**:
- ✅ Anyone can read (needed for QR codes)
- ✅ Only owner can upload to their folder
- ✅ 10MB file size limit
- ✅ Only images and PDFs allowed

**Note**: Currently using Supabase Storage, not Firebase Storage

---

## Supabase Storage Policies

**File**: [supabase/storage_policies_PUBLIC.sql](supabase/storage_policies_PUBLIC.sql)

**Deploy**: Run in Supabase SQL Editor

```sql
-- Public read (QR codes work without login)
create policy "QR-bucket public read"
on storage.objects for select
using (bucket_id = 'QR-bucket');

-- Public upload (no Supabase auth needed)
create policy "QR-bucket public insert"
on storage.objects for insert
with check (bucket_id = 'QR-bucket');
```

**Key Points**:
- ✅ No Supabase authentication required
- ✅ Firebase Auth handles user tracking
- ✅ Files organized by Firebase user ID
- ✅ Public read for QR code access

**Security Note**: For production, consider:
- Rate limiting in Supabase dashboard
- Server-side validation with Cloud Functions
- Or switch to Firebase Storage with stricter rules

---

## Authentication Setup

### Firebase Console

**Enable Anonymous Auth**:
1. Firebase Console → Authentication → Sign-in method
2. Click "Anonymous"
3. Enable → Save

**Enable Email/Password** (optional):
1. Same location
2. Click "Email/Password"
3. Enable → Save

### Supabase Console

**No auth needed** - Public storage policies handle access

---

## Deployment Commands

```bash
# Deploy all Firebase rules
firebase deploy --only firestore:rules,storage:rules

# Deploy Firestore only
firebase deploy --only firestore:rules

# Deploy Storage only (if using Firebase Storage)
firebase deploy --only storage:rules

# Deploy web app
flutter build web
firebase deploy --only hosting
```

---

## Data Flow

```
User Action: Upload File
     ↓
1. Firebase Auth (anonymous/email)
     ↓
2. Supabase Storage (public upload)
     ↓
3. Firestore (save metadata: downloadUrl, fileName)
     ↓
4. Generate QR Code → Public URL
```

**Authentication**: Firebase only ✅  
**Storage**: Supabase (no auth) ✅  
**Metadata**: Firestore (Firebase auth) ✅

---

## Security Model

### What's Protected:
- ✅ Brochure history (Firestore) - User can only see their own
- ✅ File organization - Files stored under Firebase user ID
- ✅ Data validation - Required fields enforced

### What's Public:
- ✅ File uploads to Supabase Storage
- ✅ File downloads (needed for QR codes)

### Why This Works:
- Files are public by nature (QR codes need public URLs)
- User history is private (protected by Firestore rules)
- Firebase tracks ownership (Supabase just stores files)

---

## Testing Security

### Test Firestore Rules:
```bash
firebase emulators:start --only firestore
```

### Manual Tests:
1. ✅ Anonymous user can upload
2. ✅ User can see own history
3. ✅ User cannot see other users' history
4. ✅ QR codes work without login
5. ✅ Unauthenticated users cannot access Firestore

---

## Quick Fix Commands

```bash
# Firebase rules not working?
firebase deploy --only firestore:rules

# Supabase policies not working?
# Run storage_policies_PUBLIC.sql in Supabase SQL Editor

# App not recognizing changes?
flutter clean
flutter pub get
flutter run
```
