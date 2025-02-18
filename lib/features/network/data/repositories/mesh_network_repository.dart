import 'dart:async';
import 'dart:convert';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:glasnik/features/network/domain/repositories/mesh_network_repository.dart';
import 'package:glasnik/features/network/domain/entities/peer.dart';
import 'package:glasnik/features/network/domain/entities/message.dart';
import 'package:glasnik/features/auth/domain/entities/user.dart';
import 'package:uuid/uuid.dart';

class MeshNetworkRepository implements IMeshNetworkRepository {
  final Nearby _nearby = Nearby();
  final StreamController<List<Peer>> _peersController = StreamController<List<Peer>>.broadcast();
  final StreamController<NetworkMessage> _messagesController = StreamController<NetworkMessage>.broadcast();
  final Map<String, Peer> _connectedPeers = {};
  final String _deviceId = const Uuid().v4();
  bool _isRunning = false;

  static const Strategy strategy = Strategy.P2P_CLUSTER;

  @override
  Stream<List<Peer>> get activeNodes => _peersController.stream;

  @override
  Stream<NetworkMessage> get incomingMessages => _messagesController.stream;

  @override
  Future<void> startMeshNetwork() async {
    if (_isRunning) return;

    final permission = await _nearby.askLocationPermission();
    if (!permission) {
      throw Exception('Lokacijske dozvole su neophodne za mesh networking');
    }

    await _nearby.enableLocationServices();
    _isRunning = true;
    
    // Započni advertising
    try {
      await _nearby.startAdvertising(
        _deviceId,
        strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (e) {
      _isRunning = false;
      rethrow;
    }
  }

  @override
  Future<void> stopMeshNetwork() async {
    if (!_isRunning) return;

    await _nearby.stopAdvertising();
    await _nearby.stopDiscovery();
    _connectedPeers.clear();
    _peersController.add([]);
    _isRunning = false;
  }

  @override
  Future<void> startDiscovery() async {
    if (!_isRunning) {
      throw Exception('Mesh mreža nije pokrenuta');
    }

    try {
      await _nearby.startDiscovery(
        _deviceId,
        strategy,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> stopDiscovery() async {
    await _nearby.stopDiscovery();
  }

  @override
  Future<void> sendMessage(String peerId, NetworkMessage message) async {
    if (!_connectedPeers.containsKey(peerId)) {
      throw Exception('Peer nije povezan');
    }

    final messageJson = json.encode(message.toJson());
    await _nearby.sendBytesPayload(
      peerId,
      Uint8List.fromList(messageJson.codeUnits),
    );
  }

  @override
  Future<void> broadcastMessage(NetworkMessage message) async {
    final messageJson = json.encode(message.toJson());
    final payload = Uint8List.fromList(messageJson.codeUnits);
    
    for (final peerId in _connectedPeers.keys) {
      try {
        await _nearby.sendBytesPayload(peerId, payload);
      } catch (e) {
        // Nastavi sa slanjem ostalim peer-ovima čak i ako jedan fail-uje
        continue;
      }
    }
  }

  @override
  Future<bool> isMeshActive() async {
    return _isRunning;
  }

  @override
  Future<List<Peer>> getConnectedPeers() async {
    return _connectedPeers.values.toList();
  }

  @override
  Future<void> connectToPeer(String peerId) async {
    if (!_isRunning) {
      throw Exception('Mesh mreža nije pokrenuta');
    }

    await _nearby.requestConnection(
      _deviceId,
      peerId,
      onConnectionInitiated: _onConnectionInitiated,
      onConnectionResult: _onConnectionResult,
      onDisconnected: _onDisconnected,
    );
  }

  @override
  Future<void> disconnectFromPeer(String peerId) async {
    await _nearby.disconnectFromEndpoint(peerId);
    _connectedPeers.remove(peerId);
    _peersController.add(_connectedPeers.values.toList());
  }

  // Callback handlers
  void _onConnectionInitiated(String endpointId, ConnectionInfo connectionInfo) {
    // Automatski prihvati konekciju
    _nearby.acceptConnection(
      endpointId,
      onPayLoadReceived: _onPayloadReceived,
      onPayloadTransferUpdate: _onPayloadTransferUpdate,
    );
  }

  void _onConnectionResult(String endpointId, Status status) {
    if (status == Status.CONNECTED) {
      // Dodaj peer u listu povezanih
      final newPeer = Peer(
        id: endpointId,
        deviceName: 'Unknown Device', // Ovo će biti ažurirano kroz handshake
        role: UserRole.regular, // Ovo će biti ažurirano kroz handshake
        isConnected: true,
        lastSeen: DateTime.now(),
        signalStrength: -50, // Ovo će biti ažurirano kroz merenja
        capabilities: {}, // Ovo će biti ažurirano kroz handshake
        verificationChain: '', // Ovo će biti ažurirano kroz handshake
      );
      
      _connectedPeers[endpointId] = newPeer;
      _peersController.add(_connectedPeers.values.toList());
      
      // Pošalji handshake poruku
      _sendHandshake(endpointId);
    }
  }

  void _onDisconnected(String endpointId) {
    _connectedPeers.remove(endpointId);
    _peersController.add(_connectedPeers.values.toList());
  }

  void _onEndpointFound(String endpointId, String deviceId, String serviceId) {
    // Automatski se poveži sa pronađenim peer-om
    connectToPeer(endpointId);
  }

  void _onEndpointLost(String endpointId) {
    _connectedPeers.remove(endpointId);
    _peersController.add(_connectedPeers.values.toList());
  }

  void _onPayloadReceived(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES) {
      final String messageJson = String.fromCharCodes(payload.bytes!);
      try {
        final message = NetworkMessage.fromJson(json.decode(messageJson));
        _messagesController.add(message);
        
        // Ako je handshake poruka, ažuriraj informacije o peer-u
        if (message.type == MessageType.command && 
            message.payload['command'] == 'handshake') {
          _handleHandshake(endpointId, message);
        }
      } catch (e) {
        // Ignoriši nevalidne poruke
      }
    }
  }

  void _onPayloadTransferUpdate(String endpointId, PayloadTransferUpdate update) {
    // Implementiraj ako je potrebno pratiti progress transfera
  }

  void _sendHandshake(String endpointId) {
    final handshakeMessage = NetworkMessage(
      senderId: _deviceId,
      targetId: endpointId,
      type: MessageType.command,
      payload: {
        'command': 'handshake',
        'deviceName': 'My Device', // TODO: Implementirati stvarno ime uređaja
        'role': UserRole.regular.toString(), // TODO: Implementirati stvarnu ulogu
        'capabilities': {
          'canRelay': true,
          'supportsAudio': true,
          'supportsQr': true,
        },
        'verificationChain': 'TODO', // TODO: Implementirati stvarni lanac
      },
    );

    sendMessage(endpointId, handshakeMessage);
  }

  void _handleHandshake(String endpointId, NetworkMessage message) {
    if (_connectedPeers.containsKey(endpointId)) {
      final updatedPeer = _connectedPeers[endpointId]!.copyWith(
        deviceName: message.payload['deviceName'],
        role: UserRole.values.firstWhere(
          (e) => e.toString() == message.payload['role'],
        ),
        capabilities: message.payload['capabilities'],
        verificationChain: message.payload['verificationChain'],
        lastSeen: DateTime.now(),
      );

      _connectedPeers[endpointId] = updatedPeer;
      _peersController.add(_connectedPeers.values.toList());
    }
  }

  // Cleanup
  void dispose() {
    _peersController.close();
    _messagesController.close();
    stopMeshNetwork();
  }
} 