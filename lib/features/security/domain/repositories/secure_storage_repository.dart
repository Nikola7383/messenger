import 'package:dartz/dartz.dart';
import 'package:glasnik/core/error/failures.dart';

abstract class ISecureStorageRepository {
  /// Enkriptuje i čuva podatke
  Future<Either<Failure, Unit>> secureStore(String key, String value);

  /// Čita i dekriptuje podatke
  Future<Either<Failure, String?>> secureRead(String key);

  /// Briše podatke za dati ključ
  Future<Either<Failure, Unit>> secureDelete(String key);

  /// Briše sve podatke
  Future<Either<Failure, Unit>> secureDeleteAll();

  /// Generiše novi enkripcijski ključ
  Future<Either<Failure, String>> generateKey();

  /// Čuva enkripcijski ključ u secure enclavu
  Future<Either<Failure, Unit>> storeKey(String key);

  /// Učitava enkripcijski ključ iz secure enclava
  Future<Either<Failure, String?>> loadKey();

  /// Rotira enkripcijske ključeve i reenkriptuje podatke
  Future<Either<Failure, Unit>> rotateKeys();

  /// Proverava integritet podataka
  Future<Either<Failure, bool>> verifyIntegrity(String key);

  /// Sigurno briše podatke (overwrite sa random podacima pre brisanja)
  Future<Either<Failure, Unit>> secureWipe(String key);

  /// Kreira backup enkriptovanih podataka
  Future<Either<Failure, String>> createEncryptedBackup();

  /// Vraća podatke iz backup-a
  Future<Either<Failure, Unit>> restoreFromBackup(String backup);
} 