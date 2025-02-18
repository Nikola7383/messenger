import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:glasnik/features/network/domain/repositories/mesh_network_repository.dart';
import 'package:glasnik/features/network/domain/entities/peer.dart';
import 'package:glasnik/features/network/domain/entities/message.dart';

// Events
abstract class NetworkEvent extends Equatable {
  const NetworkEvent();

  @override
  List<Object?> get props => [];
}

class NetworkStartRequested extends NetworkEvent {}
class NetworkStopRequested extends NetworkEvent {}
class NetworkDiscoveryStartRequested extends NetworkEvent {}
class NetworkDiscoveryStopRequested extends NetworkEvent {}
class NetworkMessageSent extends NetworkEvent {
  final NetworkMessage message;
  final String? targetPeerId;

  const NetworkMessageSent({
    required this.message,
    this.targetPeerId,
  });

  @override
  List<Object?> get props => [message, targetPeerId];
}

class NetworkPeerConnected extends NetworkEvent {
  final String peerId;

  const NetworkPeerConnected(this.peerId);

  @override
  List<Object?> get props => [peerId];
}

class NetworkPeerDisconnected extends NetworkEvent {
  final String peerId;

  const NetworkPeerDisconnected(this.peerId);

  @override
  List<Object?> get props => [peerId];
}

// State
class NetworkState extends Equatable {
  final bool isRunning;
  final bool isDiscovering;
  final List<Peer> connectedPeers;
  final List<NetworkMessage> messages;
  final String? error;
  final bool isLoading;

  const NetworkState({
    this.isRunning = false,
    this.isDiscovering = false,
    this.connectedPeers = const [],
    this.messages = const [],
    this.error,
    this.isLoading = false,
  });

  NetworkState copyWith({
    bool? isRunning,
    bool? isDiscovering,
    List<Peer>? connectedPeers,
    List<NetworkMessage>? messages,
    String? error,
    bool? isLoading,
  }) {
    return NetworkState(
      isRunning: isRunning ?? this.isRunning,
      isDiscovering: isDiscovering ?? this.isDiscovering,
      connectedPeers: connectedPeers ?? this.connectedPeers,
      messages: messages ?? this.messages,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        isRunning,
        isDiscovering,
        connectedPeers,
        messages,
        error,
        isLoading,
      ];
}

// Bloc
class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  final IMeshNetworkRepository _networkRepository;
  StreamSubscription<List<Peer>>? _peersSubscription;
  StreamSubscription<NetworkMessage>? _messagesSubscription;

  NetworkBloc({
    required IMeshNetworkRepository networkRepository,
  })  : _networkRepository = networkRepository,
        super(const NetworkState()) {
    on<NetworkStartRequested>(_onNetworkStartRequested);
    on<NetworkStopRequested>(_onNetworkStopRequested);
    on<NetworkDiscoveryStartRequested>(_onDiscoveryStartRequested);
    on<NetworkDiscoveryStopRequested>(_onDiscoveryStopRequested);
    on<NetworkMessageSent>(_onMessageSent);
    on<NetworkPeerConnected>(_onPeerConnected);
    on<NetworkPeerDisconnected>(_onPeerDisconnected);

    // Pretplati se na promene peer-ova i poruka
    _peersSubscription = _networkRepository.activeNodes.listen(
      (peers) {
        emit(state.copyWith(connectedPeers: peers));
      },
    );

    _messagesSubscription = _networkRepository.incomingMessages.listen(
      (message) {
        final updatedMessages = List<NetworkMessage>.from(state.messages)
          ..add(message);
        emit(state.copyWith(messages: updatedMessages));
      },
    );
  }

  Future<void> _onNetworkStartRequested(
    NetworkStartRequested event,
    Emitter<NetworkState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      await _networkRepository.startMeshNetwork();
      emit(state.copyWith(
        isRunning: true,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onNetworkStopRequested(
    NetworkStopRequested event,
    Emitter<NetworkState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      await _networkRepository.stopMeshNetwork();
      emit(state.copyWith(
        isRunning: false,
        isDiscovering: false,
        connectedPeers: [],
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onDiscoveryStartRequested(
    NetworkDiscoveryStartRequested event,
    Emitter<NetworkState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      await _networkRepository.startDiscovery();
      emit(state.copyWith(
        isDiscovering: true,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onDiscoveryStopRequested(
    NetworkDiscoveryStopRequested event,
    Emitter<NetworkState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      await _networkRepository.stopDiscovery();
      emit(state.copyWith(
        isDiscovering: false,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onMessageSent(
    NetworkMessageSent event,
    Emitter<NetworkState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      
      if (event.targetPeerId != null) {
        await _networkRepository.sendMessage(
          event.targetPeerId!,
          event.message,
        );
      } else {
        await _networkRepository.broadcastMessage(event.message);
      }

      final updatedMessages = List<NetworkMessage>.from(state.messages)
        ..add(event.message);
      
      emit(state.copyWith(
        messages: updatedMessages,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onPeerConnected(
    NetworkPeerConnected event,
    Emitter<NetworkState> emit,
  ) async {
    try {
      await _networkRepository.connectToPeer(event.peerId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onPeerDisconnected(
    NetworkPeerDisconnected event,
    Emitter<NetworkState> emit,
  ) async {
    try {
      await _networkRepository.disconnectFromPeer(event.peerId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _peersSubscription?.cancel();
    _messagesSubscription?.cancel();
    return super.close();
  }
} 