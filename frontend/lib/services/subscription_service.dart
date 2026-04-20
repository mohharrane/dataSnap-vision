import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Check limits before scanning
  Future<bool> canScan() async {
    if (_userId == null) return false;

    DocumentSnapshot doc = await _firestore.collection('users').doc(_userId).get();
    
    int scansUsed = 0;
    bool isPremium = false;

    if (doc.exists && doc.data() != null) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      scansUsed = data['scans_used'] ?? 0;
      isPremium = data['is_premium'] ?? false;
    }

    if (isPremium) return true;
    return scansUsed < 5;
  }

  // Increment scan count after successful scan
  Future<void> incrementScanCount() async {
    if (_userId == null) return;
    
    DocumentReference userRef = _firestore.collection('users').doc(_userId);
    
    await userRef.set({
      'scans_used': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // Check remaining free scans (for UI)
  Future<int> getRemainingScans() async {
    if (_userId == null) return 0;

    DocumentSnapshot doc = await _firestore.collection('users').doc(_userId).get();
    if (!doc.exists || doc.data() == null) return 5;

    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isPremium = data['is_premium'] ?? false;
    if (isPremium) return 9999; // unlimited
    
    int scansUsed = data['scans_used'] ?? 0;
    int remaining = 5 - scansUsed;
    return remaining > 0 ? remaining : 0;
  }
  
  // Apply Activation Code securely via Firestore Transactions
  Future<String> applyActivationCode(String code) async {
    if (_userId == null) return "User not logged in";

    try {
      DocumentReference codeRef = _firestore.collection('activation_codes').doc(code);
      
      return await _firestore.runTransaction((transaction) async {
        DocumentSnapshot codeSnapshot = await transaction.get(codeRef);

        if (!codeSnapshot.exists) {
          return "Invalid code";
        }

        Map<String, dynamic> data = codeSnapshot.data() as Map<String, dynamic>;
        bool isUsed = data['is_used'] ?? true;

        if (isUsed) {
          return "Code has already been used";
        }

        // Mark code as used globally
        transaction.update(codeRef, {'is_used': true, 'used_by': _userId, 'used_at': FieldValue.serverTimestamp()});
        
        // Upgrade User to Premium
        DocumentReference userRef = _firestore.collection('users').doc(_userId);
        transaction.set(userRef, {'is_premium': true}, SetOptions(merge: true));

        return "SUCCESS";
      });
    } catch (e) {
      return "Error: Could not verify code. Please check internet.";
    }
  }
}
