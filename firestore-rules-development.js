// Development Firestore Rules - More Permissive for Testing
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow all authenticated users to read/write for development
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Specific rules for better security in production
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /posts/{postId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    match /comments/{commentId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    match /groups/{groupId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    match /analytics/{document=**} {
      allow read, write: if request.auth != null;
    }

    match /notifications/{notificationId} {
      allow read, write: if request.auth != null;
    }
  }
}
