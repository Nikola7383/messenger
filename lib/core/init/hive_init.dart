import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:glasnik/features/security/utils/crypto_utils.dart';

class HiveInit {
  static const _secureBoxName = 'secure_storage';
  static const _encryptionKeyName = 'hive_encryption_key';
  
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Inicijalizuj secure storage za čuvanje Hive enkripcijskog ključa
    const secureStorage = FlutterSecureStorage();
    
    // Učitaj ili generiši Hive enkripcijski ključ
    String? encryptionKey = await secureStorage.read(key: _encryptionKeyName);
    if (encryptionKey == null) {
      encryptionKey = CryptoUtils.generateSecureRandomString(32);
      await secureStorage.write(
        key: _encryptionKeyName,
        value: encryptionKey,
      );
    }

    // Otvori enkriptovani box
    await Hive.openBox(
      _secureBoxName,
      encryptionCipher: HiveAesCipher(
        List<int>.from(encryptionKey.codeUnits),
      ),
    );
  }

  static Box getSecureBox() {
    return Hive.box(_secureBoxName);
  }

  static Future<void> clearSecureBox() async {
    final box = getSecureBox();
    await box.clear();
  }
} 