import 'package:dartz/dartz.dart';
import 'package:glasnik/core/error/failures.dart';
import 'package:glasnik/features/admin/domain/entities/user_management.dart';
import 'package:glasnik/features/auth/domain/entities/user.dart';

abstract class IUserManagementRepository {
  /// Vraća listu svih korisnika sa njihovim statusima
  Future<Either<Failure, List<UserManagementEntry>>> getAllUsers();

  /// Vraća listu korisnika koji čekaju verifikaciju
  Future<Either<Failure, List<UserManagementEntry>>> getPendingUsers();

  /// Vraća listu korisnika koji zahtevaju pažnju (kompromitovani, anomalije)
  Future<Either<Failure, List<UserManagementEntry>>> getUsersRequiringAttention();

  /// Verifikuje korisnika
  Future<Either<Failure, UserManagementEntry>> verifyUser({
    required String userId,
    required String verifierUserId,
    required List<String> verificationChain,
  });

  /// Suspenduje korisnika
  Future<Either<Failure, UserManagementEntry>> suspendUser(String userId);

  /// Revokuje korisnika
  Future<Either<Failure, UserManagementEntry>> revokeUser(String userId);

  /// Aktivira suspendovanog korisnika
  Future<Either<Failure, UserManagementEntry>> activateUser(String userId);

  /// Ažurira dozvole korisnika
  Future<Either<Failure, UserManagementEntry>> updateUserPermissions({
    required String userId,
    required Map<String, dynamic> permissions,
  });

  /// Dodaje aktivnost u log korisnika
  Future<Either<Failure, UserManagementEntry>> logUserActivity({
    required String userId,
    required Map<String, dynamic> activity,
  });

  /// Ažurira security metrike korisnika
  Future<Either<Failure, UserManagementEntry>> updateSecurityMetrics({
    required String userId,
    required Map<String, dynamic> metrics,
  });

  /// Označava korisnika kao kompromitovanog
  Future<Either<Failure, UserManagementEntry>> markUserAsCompromised(
    String userId,
  );

  /// Vraća istoriju verifikacionog lanca za korisnika
  Future<Either<Failure, List<User>>> getVerificationChainHistory(
    String userId,
  );

  /// Generiše izveštaj o aktivnostima korisnika
  Future<Either<Failure, Map<String, dynamic>>> generateUserReport(
    String userId,
  );

  /// Stream za praćenje promena statusa korisnika
  Stream<List<UserManagementEntry>> watchUserStatusChanges();

  /// Stream za praćenje security metrika
  Stream<Map<String, List<UserManagementEntry>>> watchSecurityMetrics();

  /// Stream za praćenje anomalija u ponašanju korisnika
  Stream<List<Map<String, dynamic>>> watchUserAnomalies();
} 