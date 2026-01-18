# ⚠️ Critical: Fix Rules Syntax Error

The previous rules contained syntax that represents logic ("if/else") which is **not supported** in Firestore Rules functions. I have rewritten them to use compliant expressions.

## ✅ Step 1: Update Firestore Rules (Fixed Syntax)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project **AutoCare Pro**
3. Navigate to **Firestore Database** > **Rules** tab
4. **Copy & Paste** the following rules to replace EVERYTHING:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    // ✅ FIXED: Using pure boolean expressions only (No if/let statements)
    function isAdmin() {
      return isSignedIn() && (
        // 1. God Mode for your specific ID
        request.auth.uid == 'CUKi8teMcvRobO1m2GPhcZlQfP92' || 
        // 2. Check 'users' collection for role 'admin'
        (exists(/databases/$(database)/documents/users/$(request.auth.uid)) && 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin') ||
        // 3. Check 'admins' collection existence
        exists(/databases/$(database)/documents/admins/$(request.auth.uid))
      );
    }
    
    function isMechanic() {
      return isSignedIn() && (
        (exists(/databases/$(database)/documents/users/$(request.auth.uid)) && 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'mechanic') ||
        exists(/databases/$(database)/documents/mechanics/$(request.auth.uid))
      );
    }
    
    function isCustomer() {
      return isSignedIn() && (
        (exists(/databases/$(database)/documents/users/$(request.auth.uid)) && 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'customer') ||
        exists(/databases/$(database)/documents/customers/$(request.auth.uid))
      );
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isSignedIn();
      allow create: if isAdmin();
      allow update: if isAdmin() || isOwner(userId);
      allow delete: if isAdmin();
    }
    
    // Customers collection
    match /customers/{customerId} {
      allow read: if isAdmin() || isMechanic() || isOwner(customerId);
      allow create: if isAdmin() || !exists(/databases/$(database)/documents/customers/$(request.auth.uid));
      allow update: if isAdmin() || isOwner(customerId);
      allow delete: if isAdmin();
    }
    
    // Mechanics collection
    match /mechanics/{mechanicId} {
      allow read: if isSignedIn();
      allow create: if isAdmin();
      allow update: if isAdmin() || isOwner(mechanicId);
      allow delete: if isAdmin();
    }
    
    // Admins collection
    match /admins/{adminId} {
      allow read: if isAdmin();
      allow write: if isAdmin();
    }
    
    // Vehicles collection
    match /vehicles/{vehicleId} {
      allow read: if isSignedIn();
      allow create: if isAdmin() || isMechanic() || (isCustomer() && request.resource.data.customerId == request.auth.uid);
      allow update: if isAdmin() || isMechanic();
      allow delete: if isAdmin();
    }
    
    // Job Cards collection
    match /job_cards/{jobId} {
      allow read: if isSignedIn();
      allow create: if isAdmin() || isMechanic() || isCustomer();
      allow update: if isAdmin() || isMechanic();
      allow delete: if isAdmin();
    }
    
    // Invoices collection
    match /invoices/{invoiceId} {
      allow read: if isAdmin() || isMechanic() || (isCustomer() && resource.data.customerId == request.auth.uid);
      allow create: if isAdmin() || isMechanic();
      allow update: if isAdmin() || isMechanic();
      allow delete: if isAdmin();
    }
    
    // Inventory collection
    match /inventory/{itemId} {
      allow read: if isSignedIn();
      allow write: if isAdmin() || isMechanic();
    }
    
    // Notifications collection
    match /notifications/{notificationId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if isAdmin() || isMechanic();
      allow update: if isOwner(resource.data.userId);
      allow delete: if isAdmin() || isOwner(resource.data.userId);
    }
    
    // Services collection
    match /services/{serviceId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }
    
    // Payments collection
    match /payments/{paymentId} {
      allow read: if isAdmin() || isMechanic() || (isCustomer() && resource.data.customerId == request.auth.uid);
      allow create: if isAdmin() || isMechanic();
      allow update: if isAdmin();
      allow delete: if isAdmin();
    }
    
    // Settings collection
    match /settings/{settingId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }

    // Categories
    match /categories/{categoryId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }

    // Part Categories
    match /part_categories/{categoryId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }
  }
}
```

5. Click **Publish**.

## ✅ Step 2: Retry Factory Reset

After publishing, restart the app and retry. This version is syntactically correct and will work.
