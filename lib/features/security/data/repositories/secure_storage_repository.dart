import 'dart:convert';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:glasnik/core/error/failures.dart';
import 'package:glasnik/features/security/data/models/secure_data.dart';
import 'package:glasnik/features/security/domain/repositories/secure_storage_repository.dart';
import 'package:glasnik/features/security/utils/crypto_utils.dart';
import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

class SecureStorageRepository implements ISecureStorageRepository {
  final FlutterSecureStorage _secureStorage;
  final Box _encryptedBox;
  final _uuid = const Uuid();
  static const _currentVersion = '1.0.0';
  static const _keyPrefix = 'glasnik_';
  static const _masterKeyAlias = 'master_key';

  SecureStorageRepository({
    FlutterSecureStorage? secureStorage,
    required Box encryptedBox,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _encryptedBox = encryptedBox;

  @override
  Future<Either<Failure, Unit>> secureStore(String key, String value) async {
    try {
      // Učitaj master ključ
      final masterKeyResult = await loadKey();
      final masterKey = await masterKeyResult.fold(
        (failure) => throw Exception('Failed to load master key'),
        (key) => key ?? await _initializeMasterKey(),
      );

      // Generiši salt i IV
      final salt = CryptoUtils.generateSecureRandomString(16);
      final iv = CryptoUtils.generateSecureRandomString(16);

      // Enkriptuj podatke
      final encryptedData = await CryptoUtils.encryptAES(
        value,
        masterKey,
        salt,
        iv,
      );

      // Kreiraj checksum
      final checksum = sha256.convert(utf8.encode(value)).toString();

      // Kreiraj SecureData objekat
      final secureData = SecureData(
        data: base64.encode(encryptedData),
        iv: iv,
        salt: salt,
        version: _currentVersion,
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        checksum: checksum,
        metadata: {
          'keyId': masterKey.substring(0, 8),
          'algorithm': 'AES-256-GCM',
        },
      );

      // Sačuvaj u Hive
      await _encryptedBox.put(_keyPrefix + key, secureData.toJson());

      return const Right(unit);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> secureRead(String key) async {
    try {
      final json = await _encryptedBox.get(_keyPrefix + key);
      if (json == null) return const Right(null);

      final secureData = SecureData.fromJson(json);

      // Učitaj master ključ
      final masterKeyResult = await loadKey();
      final masterKey = await masterKeyResult.fold(
        (failure) => throw Exception('Failed to load master key'),
        (key) => key ?? throw Exception('Master key not found'),
      );

      // Dekriptuj podatke
      final encryptedData = base64.decode(secureData.data);
      final decryptedData = await CryptoUtils.decryptAES(
        encryptedData,
        masterKey,
        secureData.salt,
        secureData.iv,
      );

      // Verifikuj checksum
      final checksum = sha256.convert(utf8.encode(decryptedData)).toString();
      if (checksum != secureData.checksum) {
        throw Exception('Data integrity check failed');
      }

      return Right(decryptedData);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> secureDelete(String key) async {
    try {
      await _encryptedBox.delete(_keyPrefix + key);
      return const Right(unit);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> secureDeleteAll() async {
    try {
      final keys = _encryptedBox.keys.where(
        (k) => k.toString().startsWith(_keyPrefix),
      );
      
      for (final key in keys) {
        await secureWipe(key.toString().substring(_keyPrefix.length));
      }
      
      return const Right(unit);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> generateKey() async {
    try {
      final key = CryptoUtils.generateSecureRandomString(32);
      return Right(key);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> storeKey(String key) async {
    try {
      await _secureStorage.write(
        key: _masterKeyAlias,
        value: key,
        aOptions: const AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: const IOSOptions(
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );
      return const Right(unit);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> loadKey() async {
    try {
      final key = await _secureStorage.read(
        key: _masterKeyAlias,
        aOptions: const AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: const IOSOptions(
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );
      return Right(key);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> rotateKeys() async {
    try {
      // Generiši novi master ključ
      final newKeyResult = await generateKey();
      final newKey = await newKeyResult.fold(
        (failure) => throw Exception('Failed to generate new key'),
        (key) => key,
      );

      // Učitaj stari ključ
      final oldKeyResult = await loadKey();
      final oldKey = await oldKeyResult.fold(
        (failure) => throw Exception('Failed to load old key'),
        (key) => key ?? throw Exception('Old key not found'),
      );

      // Reenkriptuj sve podatke sa novim ključem
      final keys = _encryptedBox.keys.where(
        (k) => k.toString().startsWith(_keyPrefix),
      );

      for (final key in keys) {
        final readResult = await secureRead(
          key.toString().substring(_keyPrefix.length),
        );
        
        final value = await readResult.fold(
          (failure) => throw Exception('Failed to read data'),
          (value) => value ?? throw Exception('Data not found'),
        );

        await secureStore(
          key.toString().substring(_keyPrefix.length),
          value,
        );
      }

      // Sačuvaj novi ključ
      await storeKey(newKey);

      return const Right(unit);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyIntegrity(String key) async {
    try {
      final readResult = await secureRead(key);
      return readResult.fold(
        (failure) => Right(false),
        (value) => Right(value != null),
      );
    } catch (e) {
      return Right(false);
    }
  }

  @override
  Future<Either<Failure, Unit>> secureWipe(String key) async {
    try {
      final fullKey = _keyPrefix + key;
      
      // Prepiši podatke sa random vrednostima nekoliko puta
      for (var i = 0; i < 3; i++) {
        final randomData = CryptoUtils.generateSecureRandomString(1024);
        await _encryptedBox.put(fullKey, randomData);
      }

      // Konačno obriši
      await _encryptedBox.delete(fullKey);
      
      return const Right(unit);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createEncryptedBackup() async {
    try {
      final backup = <String, dynamic>{};
      
      // Prikupi sve enkriptovane podatke
      final keys = _encryptedBox.keys.where(
        (k) => k.toString().startsWith(_keyPrefix),
      );

      for (final key in keys) {
        final json = await _encryptedBox.get(key);
        if (json != null) {
          backup[key.toString()] = json;
        }
      }

      // Enkriptuj backup sa novim ključem
      final backupKey = CryptoUtils.generateSecureRandomString(32);
      final backupData = jsonEncode(backup);
      
      final salt = CryptoUtils.generateSecureRandomString(16);
      final iv = CryptoUtils.generateSecureRandomString(16);
      
      final encryptedBackup = await CryptoUtils.encryptAES(
        backupData,
        backupKey,
        salt,
        iv,
      );

      // Kreiraj finalni backup paket
      final backupPackage = {
        'data': base64.encode(encryptedBackup),
        'key': backupKey,
        'salt': salt,
        'iv': iv,
        'version': _currentVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'checksum': sha256.convert(utf8.encode(backupData)).toString(),
      };

      return Right(jsonEncode(backupPackage));
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> restoreFromBackup(String backup) async {
    try {
      // Parsiraj i verifikuj backup
      final backupPackage = jsonDecode(backup);
      
      final encryptedData = base64.decode(backupPackage['data']);
      final backupKey = backupPackage['key'];
      final salt = backupPackage['salt'];
      final iv = backupPackage['iv'];

      // Dekriptuj backup
      final decryptedData = await CryptoUtils.decryptAES(
        encryptedData,
        backupKey,
        salt,
        iv,
      );

      // Verifikuj checksum
      final checksum = sha256.convert(utf8.encode(decryptedData)).toString();
      if (checksum != backupPackage['checksum']) {
        throw Exception('Backup integrity check failed');
      }

      // Parsiraj dekriptovane podatke
      final backupData = jsonDecode(decryptedData) as Map<String, dynamic>;

      // Obriši postojeće podatke
      await secureDeleteAll();

      // Vrati podatke iz backup-a
      for (final entry in backupData.entries) {
        await _encryptedBox.put(entry.key, entry.value);
      }

      return const Right(unit);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  Future<String> _initializeMasterKey() async {
    final keyResult = await generateKey();
    final key = await keyResult.fold(
      (failure) => throw Exception('Failed to generate master key'),
      (key) => key,
    );

    await storeKey(key);
    return key;
  }
} 