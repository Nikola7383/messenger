import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:glasnik/features/network/domain/repositories/bluetooth_repository.dart';
import 'package:glasnik/features/network/domain/entities/peer.dart';
import 'package:glasnik/features/messaging/domain/entities/message.dart';
import 'package:glasnik/features/auth/domain/entities/user.dart';

// Events
abstract class BluetoothEvent extends Equatable {
  const BluetoothEvent();

  @override
  List<Object?> get props => [];
}

class BluetoothStarted extends BluetoothEvent {}
class BluetoothStopped extends BluetoothEvent {}
class BluetoothPermissionRequested extends BluetoothEvent {}
class BluetoothScanStarted extends BluetoothEvent {}
class BluetoothScanStopped extends BluetoothEvent {}
class BluetoothMessageSent extends BluetoothEvent {
  final Message message;
  final String? targetPeerId;

  const BluetoothMessageSent({
    required this.message,
    this.targetPeerId,
  });

  @override
  List<Object?> get props => [message, targetPeerId];
}

class BluetoothPeerSelected extends BluetoothEvent {
  final String peerId;

  const BluetoothPeerSelected(this.peerId);

  @override
  List<Object?> get props => [peerId];
}

class BluetoothLowPowerModeToggled extends BluetoothEvent {
  final bool enabled;

  const BluetoothLowPowerModeToggled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

// State
class BluetoothState extends Equatable {
  final bool isEnabled;
  final bool isScanning;
  final bool hasPermission;
  final bool isLowPowerMode;
  final List<Peer> discoveredPeers;
  final List<Peer> connectedPeers;
  final Map<String, int> signalStrengths;
  final String? selectedPeerId;
  final String? error;
  final bool isLoading;

  const BluetoothState({
    this.isEnabled = false,
    this.isScanning = false,
    this.hasPermission = false,
    this.isLowPowerMode = false,
    this.discoveredPeers = const [],
    this.connectedPeers = const [],
    this.signalStrengths = const {},
    this.selectedPeerId,
    this.error,
    this.isLoading = false,
  });

  BluetoothState copyWith({
    bool? isEnabled,
    bool? isScanning,
    bool? hasPermission,
    bool? isLowPowerMode,
    List<Peer>? discoveredPeers,
    List<Peer>? connectedPeers,
    Map<String, int>? signalStrengths,
    String? selectedPeerId,
    String? error,
    bool? isLoading,
  }) {
    return BluetoothState(
      isEnabled: isEnabled ?? this.isEnabled,
      isScanning: isScanning ?? this.isScanning,
      hasPermission: hasPermission ?? this.hasPermission,
      isLowPowerMode: isLowPowerMode ?? this.isLowPowerMode,
      discoveredPeers: discoveredPeers ?? this.discoveredPeers,
      connectedPeers: connectedPeers ?? this.connectedPeers,
      signalStrengths: signalStrengths ?? this.signalStrengths,
      selectedPeerId: selectedPeerId ?? this.selectedPeerId,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
    isEnabled,
    isScanning,
    hasPermission,
    isLowPowerMode,
    discoveredPeers,
    connectedPeers,
    signalStrengths,
    selectedPeerId,
    error,
    isLoading,
  ];
}

// Bloc
class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothState> {
  final IBluetoothRepository _repository;
  final UserRole _currentUserRole;
  StreamSubscription? _discoveredPeersSubscription;
  StreamSubscription? _signalStrengthsSubscription;
  StreamSubscription? _incomingMessagesSubscription;

  BluetoothBloc({
    required IBluetoothRepository repository,
    required UserRole currentUserRole,
  }) : _repository = repository,
       _currentUserRole = currentUserRole,
       super(const BluetoothState()) {
    on<BluetoothStarted>(_onBluetoothStarted);
    on<BluetoothStopped>(_onBluetoothStopped);
    on<BluetoothPermissionRequested>(_onBluetoothPermissionRequested);
    on<BluetoothScanStarted>(_onBluetoothScanStarted);
    on<BluetoothScanStopped>(_onBluetoothScanStopped);
    on<BluetoothMessageSent>(_onBluetoothMessageSent);
    on<BluetoothPeerSelected>(_onBluetoothPeerSelected);
    on<BluetoothLowPowerModeToggled>(_onBluetoothLowPowerModeToggled);

    // Inicijalno proveri stanje
    add(BluetoothStarted());
  }

  Future<void> _onBluetoothStarted(
    BluetoothStarted event,
    Emitter<BluetoothState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final isEnabled = await _repository.isBluetoothEnabled();
      if (!isEnabled) {
        final result = await _repository.enableBluetooth();
        result.fold(
          (failure) => emit(state.copyWith(
            error: failure.toString(),
            isLoading: false,
          )),
          (_) async {
            // Bluetooth je uključen, nastavi sa inicijalizacijom
            await _initializeSubscriptions();
            emit(state.copyWith(
              isEnabled: true,
              isLoading: false,
              error: null,
            ));
          },
        );
      } else {
        // Bluetooth je već uključen
        await _initializeSubscriptions();
        emit(state.copyWith(
          isEnabled: true,
          isLoading: false,
          error: null,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _initializeSubscriptions() async {
    // Otkaži postojeće pretplate
    await _discoveredPeersSubscription?.cancel();
    await _signalStrengthsSubscription?.cancel();
    await _incomingMessagesSubscription?.cancel();

    // Pretplati se na discovered peers
    _discoveredPeersSubscription = _repository.discoveredPeers.listen(
      (peers) {
        add(BluetoothPeersUpdated(peers));
      },
    );

    // Pretplati se na signal strengths
    _signalStrengthsSubscription = _repository.signalStrengths.listen(
      (strengths) {
        add(BluetoothSignalStrengthsUpdated(strengths));
      },
    );

    // Pretplati se na incoming messages
    _incomingMessagesSubscription = _repository.incomingMessages.listen(
      (message) {
        add(BluetoothMessageReceived(message));
      },
    );
  }

  Future<void> _onBluetoothStopped(
    BluetoothStopped event,
    Emitter<BluetoothState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      await _repository.stopScanning();
      await _repository.stopAdvertising();
      
      // Otkaži pretplate
      await _discoveredPeersSubscription?.cancel();
      await _signalStrengthsSubscription?.cancel();
      await _incomingMessagesSubscription?.cancel();

      emit(state.copyWith(
        isEnabled: false,
        isScanning: false,
        discoveredPeers: [],
        connectedPeers: [],
        signalStrengths: {},
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onBluetoothPermissionRequested(
    BluetoothPermissionRequested event,
    Emitter<BluetoothState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final hasPermission = await _repository.requestBluetoothPermission();
      emit(state.copyWith(
        hasPermission: hasPermission,
        isLoading: false,
        error: hasPermission ? null : 'Bluetooth dozvole nisu odobrene',
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onBluetoothScanStarted(
    BluetoothScanStarted event,
    Emitter<BluetoothState> emit,
  ) async {
    if (!state.isEnabled || !state.hasPermission) {
      emit(state.copyWith(
        error: 'Bluetooth nije omogućen ili nema dozvole',
      ));
      return;
    }

    emit(state.copyWith(isLoading: true));

    try {
      final result = await _repository.startScanning();
      result.fold(
        (failure) => emit(state.copyWith(
          error: failure.toString(),
          isLoading: false,
        )),
        (_) => emit(state.copyWith(
          isScanning: true,
          isLoading: false,
          error: null,
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onBluetoothScanStopped(
    BluetoothScanStopped event,
    Emitter<BluetoothState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final result = await _repository.stopScanning();
      result.fold(
        (failure) => emit(state.copyWith(
          error: failure.toString(),
          isLoading: false,
        )),
        (_) => emit(state.copyWith(
          isScanning: false,
          isLoading: false,
          error: null,
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onBluetoothMessageSent(
    BluetoothMessageSent event,
    Emitter<BluetoothState> emit,
  ) async {
    // Proveri da li korisnik ima dozvolu za slanje ovog tipa poruke
    if (!event.message.canUserSend(_currentUserRole)) {
      emit(state.copyWith(
        error: 'Nemate dozvolu za slanje ovog tipa poruke',
      ));
      return;
    }

    emit(state.copyWith(isLoading: true));

    try {
      final result = event.targetPeerId != null
        ? await _repository.sendMessage(event.targetPeerId!, event.message)
        : await _repository.broadcastMessage(event.message);

      result.fold(
        (failure) => emit(state.copyWith(
          error: failure.toString(),
          isLoading: false,
        )),
        (_) => emit(state.copyWith(
          isLoading: false,
          error: null,
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onBluetoothPeerSelected(
    BluetoothPeerSelected event,
    Emitter<BluetoothState> emit,
  ) async {
    emit(state.copyWith(
      selectedPeerId: event.peerId,
      error: null,
    ));
  }

  Future<void> _onBluetoothLowPowerModeToggled(
    BluetoothLowPowerModeToggled event,
    Emitter<BluetoothState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final result = await _repository.setLowPowerMode(event.enabled);
      result.fold(
        (failure) => emit(state.copyWith(
          error: failure.toString(),
          isLoading: false,
        )),
        (_) => emit(state.copyWith(
          isLowPowerMode: event.enabled,
          isLoading: false,
          error: null,
        )),
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
    _discoveredPeersSubscription?.cancel();
    _signalStrengthsSubscription?.cancel();
    _incomingMessagesSubscription?.cancel();
    return super.close();
  }
} 