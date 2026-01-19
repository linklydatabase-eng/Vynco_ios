// Firestore Security Rules for Vynco App
// Copy and paste this into Firebase Console > Firestore Database > Rules

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to read/write posts
    match /posts/{postId} {
      allow read, write: if request.auth != null;
    }
    
    // Allow authenticated users to read/write connections
    match /connections/{connectionId} {
      allow read, write: if request.auth != null;
    }
    
    // Allow authenticated users to read/write messages
    match /messages/{messageId} {
      allow read, write: if request.auth != null;
    }
    
    // Allow authenticated users to read/write profiles
    match /profiles/{profileId} {
      allow read, write: if request.auth != null;
    }
    
    // Allow authenticated users to read/write groups
    match /groups/{groupId} {
      allow read, write: if request.auth != null;
    }
    
    // Allow authenticated users to read/write notifications
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null;
    }
    
    // Allow authenticated users to read/write status updates
    match /status/{statusId} {
      allow read, write: if request.auth != null;
    }
    
    // Allow authenticated users to read/write analytics data
    match /analytics/{analyticsId} {
      allow read, write: if request.auth != null;
    }
  }
}
