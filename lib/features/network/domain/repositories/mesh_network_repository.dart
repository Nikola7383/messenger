import 'package:glasnik/features/network/domain/entities/peer.dart';
import 'package:glasnik/features/network/domain/entities/message.dart';

abstract class IMeshNetworkRepository {
  /// Započinje mesh networking servis
  Future<void> startMeshNetwork();

  /// Zaustavlja mesh networking servis
  Future<void> stopMeshNetwork();

  /// Započinje discovery drugih uređaja
  Future<void> startDiscovery();

  /// Zaustavlja discovery
  Future<void> stopDiscovery();

  /// Stream aktivnih peer-ova
  Stream<List<Peer>> get activeNodes;

  /// Stream dolazećih poruka
  Stream<NetworkMessage> get incomingMessages;

  /// Šalje poruku specifičnom peer-u
  Future<void> sendMessage(String peerId, NetworkMessage message);

  /// Šalje broadcast poruku svim dostupnim peer-ovima
  Future<void> broadcastMessage(NetworkMessage message);

  /// Proverava da li je mesh mreža aktivna
  Future<bool> isMeshActive();

  /// Vraća listu trenutno povezanih peer-ova
  Future<List<Peer>> getConnectedPeers();

  /// Povezuje se sa specifičnim peer-om
  Future<void> connectToPeer(String peerId);

  /// Prekida vezu sa peer-om
  Future<void> disconnectFromPeer(String peerId);
} 