import 'dart:async';
import 'package:glasnik/features/network/domain/entities/peer.dart';
import 'package:glasnik/features/network/domain/entities/message.dart';

class NetworkOptimizer {
  // Maksimalan broj istovremenih konekcija po nodu
  static const int maxConnectionsPerNode = 10;
  
  // Maksimalna veličina batch-a za poruke
  static const int maxBatchSize = 50;
  
  // Interval za batch processing (ms)
  static const int batchInterval = 100;
  
  // Cache za optimizovane rute
  static final Map<String, List<String>> _routeCache = {};
  
  // Queue za batch processing poruka
  static final Map<String, List<NetworkMessage>> _messageQueue = {};
  
  // Aktivne batch operacije
  static final Map<String, Timer> _batchTimers = {};

  /// Optimizuje listu peer-ova za mesh networking
  static List<Peer> optimizePeerConnections(List<Peer> peers) {
    // Sortiraj peer-ove po signal strength i relay capability
    final sortedPeers = List<Peer>.from(peers)
      ..sort((a, b) {
        if (a.isRelay != b.isRelay) {
          return a.isRelay ? -1 : 1;
        }
        return b.signalStrength.compareTo(a.signalStrength);
      });

    // Ograniči broj konekcija po nodu
    if (sortedPeers.length > maxConnectionsPerNode) {
      return sortedPeers.sublist(0, maxConnectionsPerNode);
    }

    return sortedPeers;
  }

  /// Optimizuje rutu za poruku
  static List<String> getOptimizedRoute(
    String targetId,
    List<Peer> availablePeers,
  ) {
    // Proveri cache
    if (_routeCache.containsKey(targetId)) {
      return _routeCache[targetId]!;
    }

    // Nađi najbolju rutu (prioritet: relay nodes -> signal strength)
    final route = _calculateOptimalRoute(targetId, availablePeers);
    
    // Cachiranje rute
    _routeCache[targetId] = route;
    
    return route;
  }

  /// Batch processing za poruke
  static Future<void> queueMessageForBatch(
    String peerId,
    NetworkMessage message,
    Future<void> Function(List<NetworkMessage>) sendBatch,
  ) async {
    if (!_messageQueue.containsKey(peerId)) {
      _messageQueue[peerId] = [];
    }

    _messageQueue[peerId]!.add(message);

    // Ako već postoji timer za ovaj peer, resetuj ga
    _batchTimers[peerId]?.cancel();

    // Kreiraj novi timer
    _batchTimers[peerId] = Timer(
      Duration(milliseconds: batchInterval),
      () => _processBatch(peerId, sendBatch),
    );
  }

  /// Optimizuje message payload
  static Map<String, dynamic> optimizeMessagePayload(
    Map<String, dynamic> payload,
  ) {
    final optimizedPayload = Map<String, dynamic>.from(payload);
    
    // Ukloni null vrednosti
    optimizedPayload.removeWhere((key, value) => value == null);
    
    // Optimizuj stringove (ukloni whitespace gde nije potreban)
    optimizedPayload.forEach((key, value) {
      if (value is String) {
        optimizedPayload[key] = value.trim();
      }
    });

    return optimizedPayload;
  }

  /// Invalidira cache za rutu
  static void invalidateRouteCache(String targetId) {
    _routeCache.remove(targetId);
  }

  /// Čisti sve cache-ove
  static void clearCaches() {
    _routeCache.clear();
    _messageQueue.clear();
    _batchTimers.forEach((_, timer) => timer.cancel());
    _batchTimers.clear();
  }

  // Private helpers

  static List<String> _calculateOptimalRoute(
    String targetId,
    List<Peer> availablePeers,
  ) {
    final route = <String>[];
    
    // Prvo dodaj relay nodove sa jakim signalom
    final relayPeers = availablePeers
      .where((p) => p.isRelay && p.signalStrength > -70)
      .toList();

    if (relayPeers.isNotEmpty) {
      route.add(relayPeers.first.id);
    }

    // Dodaj peer-ove sa najboljim signal strength
    final strongPeers = availablePeers
      .where((p) => p.signalStrength > -80)
      .toList()
      ..sort((a, b) => b.signalStrength.compareTo(a.signalStrength));

    if (strongPeers.isNotEmpty) {
      route.add(strongPeers.first.id);
    }

    return route;
  }

  static Future<void> _processBatch(
    String peerId,
    Future<void> Function(List<NetworkMessage>) sendBatch,
  ) async {
    final messages = _messageQueue[peerId];
    if (messages == null || messages.isEmpty) return;

    // Uzmi batch
    final batch = messages.length > maxBatchSize
        ? messages.sublist(0, maxBatchSize)
        : messages;

    // Očisti queue
    _messageQueue[peerId] = messages.length > maxBatchSize
        ? messages.sublist(maxBatchSize)
        : [];

    // Pošalji batch
    await sendBatch(batch);

    // Ako ima još poruka, nastavi sa batch processing
    if (_messageQueue[peerId]!.isNotEmpty) {
      queueMessageForBatch(peerId, _messageQueue[peerId]!.first, sendBatch);
    }
  }
} 