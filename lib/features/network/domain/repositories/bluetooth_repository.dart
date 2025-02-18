import 'package:dartz/dartz.dart';
import 'package:glasnik/core/error/failures.dart';
import 'package:glasnik/features/network/domain/entities/peer.dart';
import 'package:glasnik/features/messaging/domain/entities/message.dart';

abstract class IBluetoothRepository {
  // Bluetooth stanje
  Future<bool> isBluetoothEnabled();
  Future<bool> requestBluetoothPermission();
  Future<Either<Failure, Unit>> enableBluetooth();
  
  // Advertising
  Future<Either<Failure, Unit>> startAdvertising({
    required String deviceName,
    required String deviceId,
    required Map<String, dynamic> serviceData,
  });
  Future<Either<Failure, Unit>> stopAdvertising();
  
  // Scanning
  Future<Either<Failure, Unit>> startScanning({
    Duration? scanDuration,
    List<String>? filterServiceUuids,
  });
  Future<Either<Failure, Unit>> stopScanning();
  
  // Povezivanje
  Future<Either<Failure, Unit>> connectToPeer(String peerId);
  Future<Either<Failure, Unit>> disconnectFromPeer(String peerId);
  Future<List<Peer>> getConnectedPeers();
  
  // Prenos podataka
  Future<Either<Failure, Unit>> sendMessage(String peerId, Message message);
  Future<Either<Failure, Unit>> broadcastMessage(Message message);
  
  // Optimizacija baterije
  Future<Either<Failure, Unit>> setLowPowerMode(bool enabled);
  Future<Either<Failure, Unit>> setScanInterval(Duration interval);
  Future<Either<Failure, Unit>> setAdvertiseInterval(Duration interval);
  
  // Sigurnost
  Future<Either<Failure, String>> generatePairingKey();
  Future<Either<Failure, Unit>> verifyPairingKey(String peerId, String key);
  Future<Either<Failure, Unit>> encryptConnection(String peerId);
  
  // Monitoring
  Stream<List<Peer>> get discoveredPeers;
  Stream<Message> get incomingMessages;
  Stream<Map<String, int>> get signalStrengths; // RSSI vrednosti za peer-ove
  
  // Mesh networking
  Future<Either<Failure, List<String>>> getOptimalRoute(String targetPeerId);
  Future<Either<Failure, Unit>> relayMessage(Message message);
  Future<Either<Failure, Unit>> updateRoutingTable();
  
  // Dijagnostika
  Future<Map<String, dynamic>> getConnectionStats(String peerId);
  Future<List<String>> getReachablePeers();
  Future<int> getEstimatedLatency(String peerId);
} 