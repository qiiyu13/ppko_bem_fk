import 'package:firebase_auth/firebase_auth.dart';

import 'platform_util.dart';

class OtpService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? _verificationId;
  static int? _resendToken;

  static Future<void> sendOTP({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    required void Function() onAutoVerify,
  }) async {
    if (!PlatformUtil.firebaseAvailable) {
      onError('OTP tidak tersedia di platform ini');
      return;
    }

    String formattedPhone = phoneNumber;
    if (!phoneNumber.startsWith('+')) {
      formattedPhone = '+62${phoneNumber.replaceFirst(RegExp(r'^0'), '')}';
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      forceResendingToken: _resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        onAutoVerify();
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(_mapFirebaseError(e));
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
      timeout: const Duration(seconds: 60),
    );
  }

  static Future<String?> verifyOTP(String smsCode) async {
    if (!PlatformUtil.firebaseAvailable) return null;
    if (_verificationId == null) throw Exception('No verification in progress');

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final idToken = await userCredential.user?.getIdToken();

    _verificationId = null;
    _resendToken = null;

    return idToken;
  }

  static String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Nomor telepon tidak valid';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'quota-exceeded':
        return 'Kuota SMS habis. Hubungi admin.';
      default:
        return 'Gagal mengirim OTP: ${e.message}';
    }
  }
}
