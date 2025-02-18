import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:glasnik/core/error/failures.dart';
import 'package:glasnik/features/network/domain/entities/peer.dart';
import 'package:glasnik/features/messaging/domain/entities/message.dart';
import 'package:glasnik/features/network/domain/repositories/bluetooth_repository.dart';
import 'package:glasnik/features/auth/domain/entities/user.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:battery/battery.dart';

class BluetoothRepository implements IBluetoothRepository {
  final FlutterBluePlus _flutterBlue;
  final _uuid = const Uuid();
  
  // Stream kontroleri
  final _discoveredPeersController = StreamController<List<Peer>>.broadcast();
  final _incomingMessagesController = StreamController<Message>.broadcast();
  final _signalStrengthsController = StreamController<Map<String, int>>.broadcast();
  final _batteryLevelController = StreamController<int>.broadcast();
  final _connectionQualityController = StreamController<Map<String, ConnectionQuality>>.broadcast();
  
  // Keširanje
  final Map<String, Peer> _connectedPeers = {};
  final Map<String, List<int>> _messageBuffer = {}; // Za velike poruke
  final Map<String, DateTime> _lastSeen = {}; // Za praćenje peer-ova
  final Map<String, List<String>> _routingTable = {}; // Za mesh networking
  
  // Konfiguracione vrednosti
  Duration _scanInterval = const Duration(seconds: 30);
  Duration _advertiseInterval = const Duration(seconds: 30);
  bool _lowPowerMode = false;
  int _maxRetries = 3;
  
  // Sigurnosni ključevi
  String? _localPrivateKey;
  final Map<String, String> _peerPublicKeys = {};

  // Dodaj nove propertije
  int _batteryLevel = 100;
  final Map<String, ConnectionQuality> _connectionQualities = {};
  Timer? _batteryMonitorTimer;
  Timer? _connectionQualityTimer;

  // Dodaj nove propertije za power management
  PowerMode _currentPowerMode = PowerMode.balanced;
  bool _isCharging = false;
  int _networkLoad = 0; // 0-100%
  final Map<String, int> _peerImportance = {}; // 0-100%

  BluetoothRepository({
    FlutterBluePlus? flutterBlue,
  }) : _flutterBlue = flutterBlue ?? FlutterBluePlus.instance {
    _initializeSecurity();
    _startPeriodicTasks();
    _startBatteryMonitoring();
    _startConnectionQualityMonitoring();
  }

  void _initializeSecurity() {
    // TODO: Implementirati generisanje i čuvanje ključeva
    _localPrivateKey = _generatePrivateKey();
  }

  void _startPeriodicTasks() {
    // Periodično skeniranje
    Timer.periodic(_scanInterval, (_) {
      if (!_lowPowerMode) {
        startScanning();
      }
    });

    // Periodično oglašavanje
    Timer.periodic(_advertiseInterval, (_) {
      if (!_lowPowerMode) {
        _advertise();
      }
    });

    // Čišćenje starih podataka
    Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupOldData();
    });
  }

  void _startBatteryMonitoring() {
    _batteryMonitorTimer?.cancel();
    _batteryMonitorTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updateBatteryLevel(),
    );
  }

  void _startConnectionQualityMonitoring() {
    _connectionQualityTimer?.cancel();
    _connectionQualityTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _updateConnectionQualities(),
    );
  }

  Future<void> _updateBatteryLevel() async {
    try {
      // Pokušaj dobiti nivo baterije od sistema
      final battery = await Battery().batteryLevel;
      _batteryLevel = battery;
      _batteryLevelController.add(battery);

      // Ažuriraj advertisement data sa novim nivoom baterije
      if (_flutterBlue.isAdvertising) {
        await _updateAdvertisementData();
      }
    } catch (e) {
      // Ignoriši greške - koristi poslednju poznatu vrednost
    }
  }

  Future<void> _updateConnectionQualities() async {
    for (final peer in _connectedPeers.values) {
      try {
        // Izračunaj kvalitet konekcije bazirano na više faktora
        final quality = await _calculateConnectionQuality(peer);
        _connectionQualities[peer.id] = quality;
      } catch (e) {
        // Ignoriši greške pojedinačnih peer-ova
        continue;
      }
    }

    _connectionQualityController.add(_connectionQualities);
  }

  Future<ConnectionQuality> _calculateConnectionQuality(Peer peer) async {
    final rssi = peer.signalStrength;
    final latency = await getEstimatedLatency(peer.id);
    final errorRate = _calculateErrorRate(peer.id);
    
    // Izračunaj score bazirano na više faktora
    int score = 0;
    
    // RSSI score (0-40)
    if (rssi >= -60) score += 40;
    else if (rssi >= -70) score += 30;
    else if (rssi >= -80) score += 20;
    else if (rssi >= -90) score += 10;
    
    // Latency score (0-30)
    if (latency <= 50) score += 30;
    else if (latency <= 100) score += 20;
    else if (latency <= 200) score += 10;
    
    // Error rate score (0-30)
    if (errorRate <= 0.01) score += 30;
    else if (errorRate <= 0.05) score += 20;
    else if (errorRate <= 0.10) score += 10;

    // Odredi kvalitet bazirano na ukupnom score-u
    if (score >= 80) return ConnectionQuality.excellent;
    if (score >= 60) return ConnectionQuality.good;
    if (score >= 40) return ConnectionQuality.fair;
    return ConnectionQuality.poor;
  }

  double _calculateErrorRate(String peerId) {
    // TODO: Implementirati praćenje grešaka u prenosu
    return 0.01; // Trenutno vraćamo fiksnu vrednost
  }

  Future<void> _updateAdvertisementData() async {
    final advertisementData = AdvertisementData(
      localName: 'Glasnik Node',
      txPowerLevel: _lowPowerMode ? -80 : -59,
      connectable: true,
      manufacturerData: {
        0x0001: Uint8List.fromList([
          0x01, // Protocol version
          0x00, // Node type
          _batteryLevel, // Battery level
          0x00, // Network status
        ]),
      },
      serviceUuids: [_serviceUuid.toString()],
    );

    await _flutterBlue.startAdvertising(
      advertisementData: advertisementData,
      timeout: _lowPowerMode 
        ? const Duration(minutes: 5)
        : const Duration(seconds: 30),
    );
  }

  @override
  Future<bool> isBluetoothEnabled() async {
    return await _flutterBlue.isOn;
  }

  @override
  Future<bool> requestBluetoothPermission() async {
    // TODO: Implementirati proveru i zahtevanje dozvola
    return true;
  }

  @override
  Future<Either<Failure, Unit>> enableBluetooth() async {
    try {
      // Na Android-u ne možemo programski uključiti Bluetooth
      // Možemo samo prikazati sistemski dijalog
      return const Right(unit);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> startAdvertising({
    required String deviceName,
    required String deviceId,
    required Map<String, dynamic> serviceData,
  }) async {
    try {
      await _advertise();
      return const Right(unit);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }

  Future<void> _advertise() async {
    // Kreiraj advertisement data
    final serviceUuid = Guid('6E400001-B5A3-F393-E0A9-E50E24DCCA9E'); // Glasnik service UUID
    final advertisementData = AdvertisementData(
      localName: 'Glasnik Node',
      txPowerLevel: -59, // Optimizovano za srednji domet
      connectable: true,
      manufacturerData: {
        0x0001: Uint8List.fromList([
          0x01, // Protocol version
          0x00, // Node type
          0x00, // Battery level
          0x00, // Network status
        ]),
      },
      serviceUuids: [serviceUuid.toString()],
    );

    // Kreiraj GATT servis
    final service = BluetoothService(
      uuid: serviceUuid,
      characteristics: [
        BluetoothCharacteristic(
          uuid: Guid('6E400002-B5A3-F393-E0A9-E50E24DCCA9E'),
          properties: CharacteristicProperties(
            write: true,
            writeWithoutResponse: true,
          ),
        ),
        BluetoothCharacteristic(
          uuid: Guid('6E400003-B5A3-F393-E0A9-E50E24DCCA9E'),
          properties: CharacteristicProperties(
            read: true,
            notify: true,
          ),
        ),
      ],
    );

    // Započni advertising
    await _flutterBlue.startAdvertising(
      advertisementData: advertisementData,
      timeout: _lowPowerMode 
        ? const Duration(minutes: 5)
        : const Duration(seconds: 30),
    );
  }

  @override
  Future<Either<Failure, Unit>> stopAdvertising() async {
    try {
      // TODO: Implementirati zaustavljanje advertisinga
      return const Right(unit);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> startScanning({
    Duration? scanDuration,
    List<String>? filterServiceUuids,
  }) async {
    try {
      await _flutterBlue.startScan(
        timeout: scanDuration ?? const Duration(seconds: 10),
        withServices: filterServiceUuids?.map((uuid) => Guid(uuid)).toList() ?? [],
      );

      _flutterBlue.scanResults.listen((results) {
        final peers = results.map((result) => _scanResultToPeer(result)).toList();
        _discoveredPeersController.add(peers);
        
        // Ažuriraj RSSI vrednosti
        final signalStrengths = {
          for (var result in results)
            result.device.id.toString(): result.rssi
        };
        _signalStrengthsController.add(signalStrengths);
      });

      return const Right(unit);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }

  Peer _scanResultToPeer(ScanResult result) {
    final deviceId = result.device.id.toString();
    final now = DateTime.now();
    _lastSeen[deviceId] = now;

    return Peer(
      id: deviceId,
      deviceName: result.device.name.isNotEmpty 
        ? result.device.name 
        : 'Unknown Device',
      role: UserRole.regular, // Biće ažurirano kroz handshake
      isConnected: _connectedPeers.containsKey(deviceId),
      lastSeen: now,
      signalStrength: result.rssi,
      capabilities: _parseAdvertisementData(result.advertisementData),
      verificationChain: '', // Biće ažurirano kroz handshake
    );
  }

  Map<String, dynamic> _parseAdvertisementData(AdvertisementData data) {
    // TODO: Implementirati parsiranje advertisement podataka
    return {
      'canRelay': true,
      'supportsAudio': true,
      'supportsQr': true,
    };
  }

  @override
  Future<Either<Failure, Unit>> stopScanning() async {
    try {
      await _flutterBlue.stopScan();
      return const Right(unit);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> connectToPeer(String peerId) async {
    try {
      final device = (await _flutterBlue.connectedDevices)
        .firstWhere((d) => d.id.toString() == peerId);
      
      await device.connect(
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );

      // Handshake i razmena ključeva
      await _performHandshake(device);
      
      return const Right(unit);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }

  Future<void> _performHandshake(BluetoothDevice device) async {
    // 1. Pronađi servis i karakteristike
    final services = await device.discoverServices();
    final service = services.firstWhere(
      (s) => s.uuid.toString() == '6E400001-B5A3-F393-E0A9-E50E24DCCA9E'
    );
    
    final txCharacteristic = service.characteristics.firstWhere(
      (c) => c.uuid.toString() == '6E400002-B5A3-F393-E0A9-E50E24DCCA9E'
    );
    
    final rxCharacteristic = service.characteristics.firstWhere(
      (c) => c.uuid.toString() == '6E400003-B5A3-F393-E0A9-E50E24DCCA9E'
    );

    // 2. Generiši ključeve za sesiju
    final sessionKey = _generatePrivateKey();
    final publicKey = sha256.convert(utf8.encode(sessionKey)).toString();

    // 3. Pripremi handshake podatke
    final handshakeData = {
      'version': '1.0',
      'publicKey': publicKey,
      'nodeType': 'regular',
      'timestamp': DateTime.now().toIso8601String(),
      'capabilities': {
        'maxMessageSize': 1024 * 1024, // 1MB
        'supportedTypes': ['text', 'system', 'verification'],
        'protocolVersion': '1.0',
        'canRelay': true,
      },
    };

    // 4. Potpiši handshake
    final signature = _generateHandshakeSignature(handshakeData);
    handshakeData['signature'] = signature;

    // 5. Pošalji handshake
    final encodedData = jsonEncode(handshakeData);
    await txCharacteristic.write(utf8.encode(encodedData));

    // 6. Čekaj odgovor
    final completer = Completer<void>();
    StreamSubscription? subscription;

    subscription = rxCharacteristic.value.listen((response) async {
      try {
        final responseData = jsonDecode(utf8.decode(response));
        
        // Verifikuj potpis odgovora
        if (!_verifyHandshakeSignature(responseData)) {
          throw Exception('Invalid handshake signature');
        }

        // Sačuvaj informacije o peer-u
        final peer = Peer(
          id: device.id.toString(),
          deviceName: device.name,
          role: UserRole.regular, // Biće ažurirano iz responseData
          isConnected: true,
          lastSeen: DateTime.now(),
          signalStrength: -60, // Biće ažurirano kasnije
          capabilities: responseData['capabilities'],
          verificationChain: responseData['verificationChain'],
        );

        _connectedPeers[peer.id] = peer;
        _peerPublicKeys[peer.id] = responseData['publicKey'];

        // Uspešan handshake
        subscription?.cancel();
        completer.complete();
      } catch (e) {
        subscription?.cancel();
        completer.completeError(e);
      }
    });

    // Postavi timeout
    Timer(const Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        subscription?.cancel();
        completer.completeError('Handshake timeout');
      }
    });

    await completer.future;
  }

  String _generateHandshakeSignature(Map<String, dynamic> data) {
    final message = jsonEncode(data);
    final key = utf8.encode(_localPrivateKey!);
    final bytes = utf8.encode(message);
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString();
  }

  bool _verifyHandshakeSignature(Map<String, dynamic> data) {
    if (!data.containsKey('signature')) return false;
    
    final signature = data.remove('signature');
    final message = jsonEncode(data);
    final key = utf8.encode(_localPrivateKey!);
    final bytes = utf8.encode(message);
    final hmac = Hmac(sha256, key);
    final expectedSignature = hmac.convert(bytes).toString();
    
    return signature == expectedSignature;
  }

  @override
  Future<Either<Failure, Unit>> sendMessage(String peerId, Message message) async {
    try {
      if (!message.isValidForTransmission()) {
        return Left(MessageFailure('Poruka nije validna za prenos'));
      }

      final device = _connectedPeers[peerId]?.deviceName;
      if (device == null) {
        return Left(BluetoothFailure('Peer nije povezan'));
      }

      // Enkodiraj i enkriptuj poruku
      final data = await _prepareMessageForTransmission(message);
      
      // Podeli velike poruke na manje delove ako je potrebno
      final chunks = _splitIntoChunks(data);
      
      // Pošalji svaki deo
      for (var i = 0; i < chunks.length; i++) {
        await _sendChunk(peerId, chunks[i], i, chunks.length);
      }

      return const Right(unit);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }

  Future<List<int>> _prepareMessageForTransmission(Message message) async {
    final json = message.toJson();
    final data = jsonEncode(json);
    
    if (message.isEncrypted) {
      // TODO: Implementirati enkripciju
      return utf8.encode(data);
    } else {
      return utf8.encode(data);
    }
  }

  List<List<int>> _splitIntoChunks(List<int> data) {
    const chunkSize = 512; // Bluetooth MTU je obično 512 bajtova
    final chunks = <List<int>>[];
    
    for (var i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      chunks.add(data.sublist(i, end));
    }
    
    return chunks;
  }

  Future<void> _sendChunk(String deviceId, List<int> chunk, int index, int total) async {
    final device = (await _flutterBlue.connectedDevices)
      .firstWhere((d) => d.id.toString() == deviceId);

    // Pronađi TX karakteristiku
    final service = await device.discoverServices()
      .then((services) => services.firstWhere(
        (s) => s.uuid.toString() == '6E400001-B5A3-F393-E0A9-E50E24DCCA9E'
      ));
    
    final characteristic = service.characteristics.firstWhere(
      (c) => c.uuid.toString() == '6E400002-B5A3-F393-E0A9-E50E24DCCA9E'
    );

    // Dodaj header sa informacijama o chunk-u
    final header = Uint8List.fromList([
      index, // Chunk index
      total, // Total chunks
      chunk.length >> 8, // Size high byte
      chunk.length & 0xFF, // Size low byte
    ]);

    // Kombinuj header i podatke
    final data = Uint8List(header.length + chunk.length);
    data.setAll(0, header);
    data.setAll(header.length, chunk);

    // Pošalji podatke
    await characteristic.write(
      data,
      withoutResponse: true,
    );

    // Sačekaj malo između chunk-ova da ne preopteretimo vezu
    if (index < total - 1) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Future<Either<Failure, Unit>> broadcastMessage(Message message) async {
    try {
      if (!message.isValidForTransmission()) {
        return Left(MessageFailure('Poruka nije validna za prenos'));
      }

      final connectedPeers = await getConnectedPeers();
      
      for (final peer in connectedPeers) {
        // Pošalji poruku svim povezanim peer-ovima
        await sendMessage(peer.id, message);
      }

      return const Right(unit);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setLowPowerMode(bool enabled) async {
    try {
      _lowPowerMode = enabled;
      
      if (enabled) {
        _scanInterval = const Duration(minutes: 5);
        _advertiseInterval = const Duration(minutes: 5);
        _maxRetries = 1;
      } else {
        _scanInterval = const Duration(seconds: 30);
        _advertiseInterval = const Duration(seconds: 30);
        _maxRetries = 3;
      }

      return const Right(unit);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> generatePairingKey() async {
    try {
      final key = _generatePrivateKey();
      return Right(key);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  String _generatePrivateKey() {
    final random = _uuid.v4();
    return sha256.convert(utf8.encode(random)).toString();
  }

  @override
  Future<Either<Failure, Unit>> verifyPairingKey(String peerId, String key) async {
    try {
      // TODO: Implementirati verifikaciju ključa
      return const Right(unit);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Stream<List<Peer>> get discoveredPeers => _discoveredPeersController.stream;

  @override
  Stream<Message> get incomingMessages => _incomingMessagesController.stream;

  @override
  Stream<Map<String, int>> get signalStrengths => _signalStrengthsController.stream;

  @override
  Stream<int> get batteryLevel => _batteryLevelController.stream;

  @override
  Stream<Map<String, ConnectionQuality>> get connectionQualities => _connectionQualityController.stream;

  void _cleanupOldData() {
    final now = DateTime.now();
    
    // Očisti stare last seen zapise
    _lastSeen.removeWhere((_, time) => 
      now.difference(time) > const Duration(hours: 1));
    
    // Očisti stare message buffer-e
    _messageBuffer.removeWhere((_, _) => 
      now.difference(_lastSeen[_] ?? now) > const Duration(minutes: 5));
    
    // Ažuriraj routing tabelu
    _updateRoutingTable();
  }

  Future<void> _updateRoutingTable() async {
    // 1. Prikupi informacije o svim dostupnim peer-ovima
    final allPeers = <String, PeerInfo>{};
    
    // Direktno povezani peer-ovi
    for (final peer in _connectedPeers.values) {
      allPeers[peer.id] = PeerInfo(
        distance: 1,
        nextHop: peer.id,
        lastSeen: peer.lastSeen,
        signalStrength: peer.signalStrength,
      );
    }

    // 2. Razmeni routing informacije sa susedima
    for (final peer in _connectedPeers.values) {
      try {
        // Zatraži routing tabelu od peer-a
        final message = Message(
          senderId: 'local_device',
          receiverId: peer.id,
          type: MessageType.command,
          content: {
            'command': 'get_routing_table',
          },
          priority: 100, // Visok prioritet za routing
        );

        final result = await sendMessage(peer.id, message);
        result.fold(
          (failure) => null, // Ignoriši greške pojedinačnih peer-ova
          (response) {
            final peerRoutes = response as Map<String, dynamic>;
            
            // Ažuriraj routing tabelu sa informacijama od peer-a
            for (final entry in peerRoutes.entries) {
              final peerId = entry.key;
              final info = entry.value as Map<String, dynamic>;
              
              final distance = info['distance'] as int;
              if (distance < 3) { // Maksimalno 3 hopa
                final existingInfo = allPeers[peerId];
                if (existingInfo == null || distance < existingInfo.distance) {
                  allPeers[peerId] = PeerInfo(
                    distance: distance + 1,
                    nextHop: peer.id,
                    lastSeen: DateTime.parse(info['lastSeen']),
                    signalStrength: info['signalStrength'],
                  );
                }
              }
            }
          },
        );
      } catch (e) {
        // Ignoriši greške pojedinačnih peer-ova
        continue;
      }
    }

    // 3. Primeni Dijkstra algoritam za optimalne rute
    final routes = _calculateOptimalRoutes(allPeers);

    // 4. Ažuriraj routing tabelu
    _routingTable.clear();
    for (final entry in routes.entries) {
      _routingTable[entry.key] = entry.value.path;
    }

    // 5. Očisti stare rute
    _routingTable.removeWhere((peerId, _) {
      final info = allPeers[peerId];
      if (info == null) return true;
      return DateTime.now().difference(info.lastSeen) > const Duration(hours: 1);
    });
  }

  Map<String, RouteInfo> _calculateOptimalRoutes(Map<String, PeerInfo> peers) {
    final routes = <String, RouteInfo>{};
    final unvisited = Set<String>.from(peers.keys);
    
    // Inicijalizuj distance
    final distances = <String, int>{};
    final previousNodes = <String, String>{};
    for (final peerId in peers.keys) {
      distances[peerId] = peerId == 'local_device' ? 0 : 999999;
    }

    while (unvisited.isNotEmpty) {
      // Pronađi čvor sa najmanjom distancom
      String? current;
      var minDistance = 999999;
      for (final node in unvisited) {
        final distance = distances[node] ?? 999999;
        if (distance < minDistance) {
          minDistance = distance;
          current = node;
        }
      }

      if (current == null) break;
      unvisited.remove(current);

      // Ažuriraj distance do suseda
      for (final neighbor in peers.keys) {
        if (!unvisited.contains(neighbor)) continue;

        final info = peers[neighbor]!;
        final newDistance = distances[current]! + info.distance;
        
        if (newDistance < (distances[neighbor] ?? 999999)) {
          distances[neighbor] = newDistance;
          previousNodes[neighbor] = current;
        }
      }
    }

    // Konstruiši rute
    for (final peerId in peers.keys) {
      if (peerId == 'local_device') continue;

      final path = <String>[];
      var current = peerId;
      
      while (previousNodes.containsKey(current)) {
        path.insert(0, current);
        current = previousNodes[current]!;
      }

      if (path.isNotEmpty) {
        routes[peerId] = RouteInfo(
          distance: distances[peerId] ?? 999999,
          path: path,
        );
      }
    }

    return routes;
  }

  class PeerInfo {
    final int distance;
    final String nextHop;
    final DateTime lastSeen;
    final int signalStrength;

    PeerInfo({
      required this.distance,
      required this.nextHop,
      required this.lastSeen,
      required this.signalStrength,
    });
  }

  class RouteInfo {
    final int distance;
    final List<String> path;

    RouteInfo({
      required this.distance,
      required this.path,
    });
  }

  @override
  Future<void> dispose() async {
    _batteryMonitorTimer?.cancel();
    _connectionQualityTimer?.cancel();
    await _discoveredPeersController.close();
    await _incomingMessagesController.close();
    await _signalStrengthsController.close();
    await _batteryLevelController.close();
    await _connectionQualityController.close();
    await super.dispose();
  }

  @override
  Future<Either<Failure, Unit>> setPowerMode(PowerMode mode) async {
    try {
      _currentPowerMode = mode;
      await _applyPowerSettings();
      return const Right(unit);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }

  Future<void> _applyPowerSettings() async {
    switch (_currentPowerMode) {
      case PowerMode.performance:
        _scanInterval = const Duration(seconds: 15);
        _advertiseInterval = const Duration(seconds: 15);
        _maxRetries = 5;
        break;
      case PowerMode.balanced:
        _scanInterval = const Duration(seconds: 30);
        _advertiseInterval = const Duration(seconds: 30);
        _maxRetries = 3;
        break;
      case PowerMode.powerSaver:
        _scanInterval = const Duration(minutes: 1);
        _advertiseInterval = const Duration(minutes: 1);
        _maxRetries = 2;
        break;
      case PowerMode.adaptive:
        await _updateAdaptivePowerSettings();
        break;
    }

    // Primeni nove postavke
    await _updateAdvertisementData();
    if (_flutterBlue.isScanning) {
      await _flutterBlue.stopScan();
      await startScanning();
    }
  }

  Future<void> _updateAdaptivePowerSettings() async {
    // 1. Proveri nivo baterije i da li se uređaj puni
    final battery = await Battery();
    _batteryLevel = await battery.batteryLevel;
    _isCharging = await battery.batteryState == BatteryState.charging;

    // 2. Izračunaj network load
    _updateNetworkLoad();

    // 3. Ažuriraj važnost peer-ova
    _updatePeerImportance();

    // 4. Prilagodi postavke bazirano na trenutnom stanju
    if (_isCharging) {
      // Kada se uređaj puni, koristi aggressive postavke
      _scanInterval = const Duration(seconds: 15);
      _advertiseInterval = const Duration(seconds: 15);
      _maxRetries = 5;
    } else {
      // Prilagodi postavke bazirano na nivou baterije i network load-u
      if (_batteryLevel <= 20) {
        // Critical battery mode
        _scanInterval = const Duration(minutes: 2);
        _advertiseInterval = const Duration(minutes: 2);
        _maxRetries = 1;
      } else if (_batteryLevel <= 50) {
        // Low battery mode
        _scanInterval = const Duration(minutes: 1);
        _advertiseInterval = const Duration(minutes: 1);
        _maxRetries = 2;
      } else {
        // Normal battery mode
        final baseInterval = _networkLoad < 50 
          ? const Duration(seconds: 30)
          : const Duration(seconds: 45);
        
        _scanInterval = baseInterval;
        _advertiseInterval = baseInterval;
        _maxRetries = 3;
      }
    }

    // 5. Prilagodi TX power bazirano na peer-ovima
    int txPower = -80; // Default low power
    for (final peer in _connectedPeers.values) {
      final importance = _peerImportance[peer.id] ?? 0;
      if (importance > 80) {
        txPower = -59; // High power za važne peer-ove
        break;
      }
    }

    // 6. Ažuriraj advertisement data sa novim TX power-om
    final advertisementData = AdvertisementData(
      localName: 'Glasnik Node',
      txPowerLevel: txPower,
      connectable: true,
      manufacturerData: {
        0x0001: Uint8List.fromList([
          0x01, // Protocol version
          0x00, // Node type
          _batteryLevel, // Battery level
          _networkLoad, // Network load
        ]),
      },
      serviceUuids: [_serviceUuid.toString()],
    );

    await _flutterBlue.startAdvertising(
      advertisementData: advertisementData,
      timeout: _scanInterval,
    );
  }

  void _updateNetworkLoad() {
    // Izračunaj prosečan network load u poslednjih 5 minuta
    int totalMessages = 0;
    int totalBytes = 0;
    final now = DateTime.now();
    final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

    for (final message in _recentMessages) {
      if (message.timestamp.isAfter(fiveMinutesAgo)) {
        totalMessages++;
        totalBytes += message.sizeInBytes;
      }
    }

    // Normalizuj load na skalu 0-100%
    const maxBytesPerMinute = 1024 * 1024; // 1MB po minutu
    final bytesPerMinute = totalBytes / 5;
    _networkLoad = ((bytesPerMinute / maxBytesPerMinute) * 100).clamp(0, 100).toInt();
  }

  void _updatePeerImportance() {
    for (final peer in _connectedPeers.values) {
      int importance = 0;

      // Faktori koji utiču na važnost peer-a:
      // 1. Uloga peer-a
      switch (peer.role) {
        case UserRole.secretMaster:
        case UserRole.masterAdmin:
          importance += 50;
          break;
        case UserRole.seed:
          importance += 40;
          break;
        case UserRole.glasnik:
          importance += 30;
          break;
        default:
          importance += 10;
      }

      // 2. Aktivnost u poslednje vreme
      final messageCount = _getRecentMessageCount(peer.id);
      importance += (messageCount * 2).clamp(0, 30);

      // 3. Kvalitet konekcije
      final quality = _connectionQualities[peer.id] ?? ConnectionQuality.poor;
      switch (quality) {
        case ConnectionQuality.excellent:
          importance += 20;
          break;
        case ConnectionQuality.good:
          importance += 15;
          break;
        case ConnectionQuality.fair:
          importance += 10;
          break;
        case ConnectionQuality.poor:
          importance += 5;
          break;
      }

      _peerImportance[peer.id] = importance.clamp(0, 100);
    }
  }

  int _getRecentMessageCount(String peerId) {
    final now = DateTime.now();
    final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
    
    return _recentMessages.where((m) => 
      (m.senderId == peerId || m.receiverId == peerId) &&
      m.timestamp.isAfter(fiveMinutesAgo)
    ).length;
  }
}

enum ConnectionQuality {
  excellent,
  good,
  fair,
  poor,
}

class ConnectionStats {
  final int rssi;
  final int latency;
  final double errorRate;
  final int packetsReceived;
  final int packetsSent;
  final DateTime lastUpdated;

  ConnectionStats({
    required this.rssi,
    required this.latency,
    required this.errorRate,
    required this.packetsReceived,
    required this.packetsSent,
    required this.lastUpdated,
  });
}

enum PowerMode {
  performance,
  balanced,
  powerSaver,
  adaptive,
} 