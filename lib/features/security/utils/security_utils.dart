import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:glasnik/features/security/utils/crypto_utils.dart';

class SecurityUtils {
  static final Random _random = Random.secure();

  /// Generiše sigurni random string određene dužine
  static String generateSecureRandomString(int length) {
    const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (_) => charset[_random.nextInt(charset.length)]).join();
  }

  /// Generiše salt za hashing
  static String generateSalt([int length = 16]) {
    final bytes = List<int>.generate(length, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Kreira hash password-a sa salt-om
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifikuje password
  static bool verifyPassword(String password, String salt, String hash) {
    final computedHash = hashPassword(password, salt);
    return computedHash == hash;
  }

  /// Generiše verifikacioni izazov
  static Map<String, String> generateVerificationChallenge() {
    final challenge = CryptoUtils.generateChallenge();
    final solution = _generateChallengeSolution(challenge);
    
    return {
      'challenge': challenge,
      'solution': solution,
    };
  }

  /// Verifikuje odgovor na izazov
  static bool verifyChallenge(String challenge, String response) {
    final expectedSolution = _generateChallengeSolution(challenge);
    return response == expectedSolution;
  }

  /// Interno generisanje rešenja izazova
  static String _generateChallengeSolution(String challenge) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final data = challenge + timestamp;
    return CryptoUtils.hashData(data);
  }

  /// Provera jačine lozinke
  static bool isStrongPassword(String password) {
    if (password.length < 8) return false;
    
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasNumbers = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    return hasUppercase && hasLowercase && hasNumbers && hasSpecialChars;
  }

  /// Sanitizacija korisničkog unosa
  static String sanitizeInput(String input) {
    // Ukloni potencijalno opasne karaktere
    return input.replaceAll(RegExp(r'[<>"\']'), '');
  }

  /// Enkripcija osetljivih podataka
  static String encryptSensitiveData(String data, String key) {
    // TODO: Implementirati AES enkripciju
    return data;
  }

  /// Dekripcija osetljivih podataka
  static String decryptSensitiveData(String encryptedData, String key) {
    // TODO: Implementirati AES dekripciju
    return encryptedData;
  }

  /// Generisanje sigurnog seed-a
  static List<int> generateSecureSeed([int length = 32]) {
    return List<int>.generate(length, (_) => _random.nextInt(256));
  }

  /// Provera integriteta podataka
  static bool verifyDataIntegrity(List<int> data, String checksum) {
    final computedChecksum = sha256.convert(data).toString();
    return computedChecksum == checksum;
  }

  /// Generisanje checksum-a
  static String generateChecksum(List<int> data) {
    return sha256.convert(data).toString();
  }

  /// Obfuskacija podataka
  static String obfuscateData(String data) {
    final bytes = utf8.encode(data);
    final obfuscated = bytes.map((b) => b ^ 0x42).toList(); // XOR sa ključem
    return base64Url.encode(obfuscated);
  }

  /// Deobfuskacija podataka
  static String deobfuscateData(String obfuscatedData) {
    final bytes = base64Url.decode(obfuscatedData);
    final deobfuscated = bytes.map((b) => b ^ 0x42).toList(); // XOR sa istim ključem
    return utf8.decode(deobfuscated);
  }

  /// Generisanje sigurnog tokena
  static String generateSecureToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = generateSecureRandomString(32);
    return CryptoUtils.hashData('$timestamp:$random');
  }

  /// Provera da li je token istekao
  static bool isTokenExpired(String token, DateTime issuedAt, Duration validity) {
    final now = DateTime.now();
    return now.difference(issuedAt) > validity;
  }

  /// Generisanje anti-tamper pečata
  static String generateTamperSeal(Map<String, dynamic> data) {
    final sortedKeys = data.keys.toList()..sort();
    final normalizedData = sortedKeys.map((k) => '$k=${data[k]}').join('&');
    return CryptoUtils.hashData(normalizedData);
  }

  /// Provera anti-tamper pečata
  static bool verifyTamperSeal(Map<String, dynamic> data, String seal) {
    final computedSeal = generateTamperSeal(data);
    return computedSeal == seal;
  }
} 