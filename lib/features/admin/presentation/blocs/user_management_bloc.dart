import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:glasnik/features/admin/domain/entities/user_management.dart';
import 'package:glasnik/features/admin/domain/repositories/user_management_repository.dart';
import 'package:glasnik/features/auth/domain/entities/user.dart';

// Events
abstract class UserManagementEvent extends Equatable {
  const UserManagementEvent();

  @override
  List<Object?> get props => [];
}

class LoadUsersRequested extends UserManagementEvent {}

class LoadPendingUsersRequested extends UserManagementEvent {}

class LoadUsersRequiringAttentionRequested extends UserManagementEvent {}

class VerifyUserRequested extends UserManagementEvent {
  final String userId;
  final String verifierUserId;
  final List<String> verificationChain;

  const VerifyUserRequested({
    required this.userId,
    required this.verifierUserId,
    required this.verificationChain,
  });

  @override
  List<Object?> get props => [userId, verifierUserId, verificationChain];
}

class SuspendUserRequested extends UserManagementEvent {
  final String userId;

  const SuspendUserRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class RevokeUserRequested extends UserManagementEvent {
  final String userId;

  const RevokeUserRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ActivateUserRequested extends UserManagementEvent {
  final String userId;

  const ActivateUserRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateUserPermissionsRequested extends UserManagementEvent {
  final String userId;
  final Map<String, dynamic> permissions;

  const UpdateUserPermissionsRequested({
    required this.userId,
    required this.permissions,
  });

  @override
  List<Object?> get props => [userId, permissions];
}

class UserActivityLogged extends UserManagementEvent {
  final String userId;
  final Map<String, dynamic> activity;

  const UserActivityLogged({
    required this.userId,
    required this.activity,
  });

  @override
  List<Object?> get props => [userId, activity];
}

class SecurityMetricsUpdated extends UserManagementEvent {
  final String userId;
  final Map<String, dynamic> metrics;

  const SecurityMetricsUpdated({
    required this.userId,
    required this.metrics,
  });

  @override
  List<Object?> get props => [userId, metrics];
}

class UserCompromiseDetected extends UserManagementEvent {
  final String userId;

  const UserCompromiseDetected(this.userId);

  @override
  List<Object?> get props => [userId];
}

class GenerateUserReportRequested extends UserManagementEvent {
  final String userId;

  const GenerateUserReportRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

// State
class UserManagementState extends Equatable {
  final List<UserManagementEntry> users;
  final List<UserManagementEntry> pendingUsers;
  final List<UserManagementEntry> usersRequiringAttention;
  final Map<String, List<User>> verificationChainHistory;
  final Map<String, Map<String, dynamic>> userReports;
  final Map<String, List<UserManagementEntry>> securityMetrics;
  final List<Map<String, dynamic>> anomalies;
  final bool isLoading;
  final String? error;

  const UserManagementState({
    this.users = const [],
    this.pendingUsers = const [],
    this.usersRequiringAttention = const [],
    this.verificationChainHistory = const {},
    this.userReports = const {},
    this.securityMetrics = const {},
    this.anomalies = const [],
    this.isLoading = false,
    this.error,
  });

  UserManagementState copyWith({
    List<UserManagementEntry>? users,
    List<UserManagementEntry>? pendingUsers,
    List<UserManagementEntry>? usersRequiringAttention,
    Map<String, List<User>>? verificationChainHistory,
    Map<String, Map<String, dynamic>>? userReports,
    Map<String, List<UserManagementEntry>>? securityMetrics,
    List<Map<String, dynamic>>? anomalies,
    bool? isLoading,
    String? error,
  }) {
    return UserManagementState(
      users: users ?? this.users,
      pendingUsers: pendingUsers ?? this.pendingUsers,
      usersRequiringAttention: usersRequiringAttention ?? this.usersRequiringAttention,
      verificationChainHistory: verificationChainHistory ?? this.verificationChainHistory,
      userReports: userReports ?? this.userReports,
      securityMetrics: securityMetrics ?? this.securityMetrics,
      anomalies: anomalies ?? this.anomalies,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    users,
    pendingUsers,
    usersRequiringAttention,
    verificationChainHistory,
    userReports,
    securityMetrics,
    anomalies,
    isLoading,
    error,
  ];
}

// Bloc
class UserManagementBloc extends Bloc<UserManagementEvent, UserManagementState> {
  final IUserManagementRepository _repository;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _metricsSubscription;
  StreamSubscription? _anomaliesSubscription;

  UserManagementBloc({
    required IUserManagementRepository repository,
  }) : _repository = repository,
       super(const UserManagementState()) {
    on<LoadUsersRequested>(_onLoadUsersRequested);
    on<LoadPendingUsersRequested>(_onLoadPendingUsersRequested);
    on<LoadUsersRequiringAttentionRequested>(_onLoadUsersRequiringAttentionRequested);
    on<VerifyUserRequested>(_onVerifyUserRequested);
    on<SuspendUserRequested>(_onSuspendUserRequested);
    on<RevokeUserRequested>(_onRevokeUserRequested);
    on<ActivateUserRequested>(_onActivateUserRequested);
    on<UpdateUserPermissionsRequested>(_onUpdateUserPermissionsRequested);
    on<UserActivityLogged>(_onUserActivityLogged);
    on<SecurityMetricsUpdated>(_onSecurityMetricsUpdated);
    on<UserCompromiseDetected>(_onUserCompromiseDetected);
    on<GenerateUserReportRequested>(_onGenerateUserReportRequested);

    _setupSubscriptions();
  }

  void _setupSubscriptions() {
    _statusSubscription?.cancel();
    _statusSubscription = _repository.watchUserStatusChanges().listen(
      (users) {
        add(LoadUsersRequested());
      },
    );

    _metricsSubscription?.cancel();
    _metricsSubscription = _repository.watchSecurityMetrics().listen(
      (metrics) {
        emit(state.copyWith(securityMetrics: metrics));
      },
    );

    _anomaliesSubscription?.cancel();
    _anomaliesSubscription = _repository.watchUserAnomalies().listen(
      (anomalies) {
        emit(state.copyWith(anomalies: anomalies));
      },
    );
  }

  Future<void> _onLoadUsersRequested(
    LoadUsersRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      
      final result = await _repository.getAllUsers();
      
      result.fold(
        (failure) => emit(state.copyWith(
          error: failure.toString(),
          isLoading: false,
        )),
        (users) => emit(state.copyWith(
          users: users,
          isLoading: false,
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onLoadPendingUsersRequested(
    LoadPendingUsersRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      
      final result = await _repository.getPendingUsers();
      
      result.fold(
        (failure) => emit(state.copyWith(
          error: failure.toString(),
          isLoading: false,
        )),
        (users) => emit(state.copyWith(
          pendingUsers: users,
          isLoading: false,
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onLoadUsersRequiringAttentionRequested(
    LoadUsersRequiringAttentionRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      
      final result = await _repository.getUsersRequiringAttention();
      
      result.fold(
        (failure) => emit(state.copyWith(
          error: failure.toString(),
          isLoading: false,
        )),
        (users) => emit(state.copyWith(
          usersRequiringAttention: users,
          isLoading: false,
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onVerifyUserRequested(
    VerifyUserRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      
      final result = await _repository.verifyUser(
        userId: event.userId,
        verifierUserId: event.verifierUserId,
        verificationChain: event.verificationChain,
      );
      
      result.fold(
        (failure) => emit(state.copyWith(
          error: failure.toString(),
          isLoading: false,
        )),
        (user) {
          final updatedUsers = List<UserManagementEntry>.from(state.users);
          final index = updatedUsers.indexWhere((u) => u.user.id == user.user.id);
          if (index != -1) {
            updatedUsers[index] = user;
          }
          
          emit(state.copyWith(
            users: updatedUsers,
            isLoading: false,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onSuspendUserRequested(
    SuspendUserRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      
      final result = await _repository.suspendUser(event.userId);
      
      result.fold(
        (failure) => emit(state.copyWith(
          error: failure.toString(),
          isLoading: false,
        )),
        (user) {
          final updatedUsers = List<UserManagementEntry>.from(state.users);
          final index = updatedUsers.indexWhere((u) => u.user.id == user.user.id);
          if (index != -1) {
            updatedUsers[index] = user;
          }
          
          emit(state.copyWith(
            users: updatedUsers,
            isLoading: false,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onRevokeUserRequested(
    RevokeUserRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      
      final result = await _repository.revokeUser(event.userId);
      
      result.fold(
        (failure) => emit(state.copyWith(
          error: failure.toString(),
          isLoading: false,
        )),
        (user) {
          final updatedUsers = List<UserManagementEntry>.from(state.users);
          final index = updatedUsers.indexWhere((u) => u.user.id == user.user.id);
          if (index != -1) {
            updatedUsers[index] = user;
          }
          
          emit(state.copyWith(
            users: updatedUsers,
            isLoading: false,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onActivateUserRequested(
    ActivateUserRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      
      final result = await _repository.activateUser(event.userId);
      
      result.fold(
        (failure) => emit(state.copyWith(
          error: failure.toString(),
          isLoading: false,
        )),
        (user) {
          final updatedUsers = List<UserManagementEntry>.from(state.users);
          final index = updatedUsers.indexWhere((u) => u.user.id == user.user.id);
          if (index != -1) {
            updatedUsers[index] = user;
          }
          
          emit(state.copyWith(
            users: updatedUsers,
            isLoading: false,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onUpdateUserPermissionsRequested(
    UpdateUserPermissionsRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      
      final result = await _repository.updateUserPermissions(
        userId: event.userId,
        permissions: event.permissions,
      );
      
      result.fold(
        (failure) => emit(state.copyWith(
          error: failure.toString(),
          isLoading: false,
        )),
        (user) {
          final updatedUsers = List<UserManagementEntry>.from(state.users);
          final index = updatedUsers.indexWhere((u) => u.user.id == user.user.id);
          if (index != -1) {
            updatedUsers[index] = user;
          }
          
          emit(state.copyWith(
            users: updatedUsers,
            isLoading: false,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onUserActivityLogged(
    UserActivityLogged event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      
      final result = await _repository.logUserActivity(
        userId: event.userId,
        activity: event.activity,
      );
      
      result.fold(
        (failure) => emit(state.copyWith(
          error: failure.toString(),
          isLoading: false,
        )),
        (user) {
          final updatedUsers = List<UserManagementEntry>.from(state.users);
          final index = updatedUsers.indexWhere((u) => u.user.id == user.user.id);
          if (index != -1) {
            updatedUsers[index] = user;
          }
          
          emit(state.copyWith(
            users: updatedUsers,
            isLoading: false,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onSecurityMetricsUpdated(
    SecurityMetricsUpdated event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      
      final result = await _repository.updateSecurityMetrics(
        userId: event.userId,
        metrics: event.metrics,
      );
      
      result.fold(
        (failure) => emit(state.copyWith(
          error: failure.toString(),
          isLoading: false,
        )),
        (user) {
          final updatedUsers = List<UserManagementEntry>.from(state.users);
          final index = updatedUsers.indexWhere((u) => u.user.id == user.user.id);
          if (index != -1) {
            updatedUsers[index] = user;
          }
          
          emit(state.copyWith(
            users: updatedUsers,
            isLoading: false,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onUserCompromiseDetected(
    UserCompromiseDetected event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      
      final result = await _repository.markUserAsCompromised(event.userId);
      
      result.fold(
        (failure) => emit(state.copyWith(
          error: failure.toString(),
          isLoading: false,
        )),
        (user) {
          final updatedUsers = List<UserManagementEntry>.from(state.users);
          final index = updatedUsers.indexWhere((u) => u.user.id == user.user.id);
          if (index != -1) {
            updatedUsers[index] = user;
          }
          
          emit(state.copyWith(
            users: updatedUsers,
            isLoading: false,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onGenerateUserReportRequested(
    GenerateUserReportRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      
      final result = await _repository.generateUserReport(event.userId);
      
      result.fold(
        (failure) => emit(state.copyWith(
          error: failure.toString(),
          isLoading: false,
        )),
        (report) {
          final updatedReports = Map<String, Map<String, dynamic>>.from(state.userReports);
          updatedReports[event.userId] = report;
          
          emit(state.copyWith(
            userReports: updatedReports,
            isLoading: false,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    _metricsSubscription?.cancel();
    _anomaliesSubscription?.cancel();
    return super.close();
  }
} 