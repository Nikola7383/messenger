abstract class INetworkRepository {
  /// Stream koji emituje metrike mreže
  Stream<Map<String, dynamic>> get networkMetrics;

  /// Stream koji emituje detektovane pretnje
  Stream<Map<String, dynamic>> get threatDetection;

  /// Pokreće analizu mreže
  Future<void> startNetworkAnalysis();

  /// Zaustavlja analizu mreže
  Future<void> stopNetworkAnalysis();

  /// Primenjuje odbrambene mere za date pretnje
  Future<void> applyDefenseMeasures(List<Map<String, dynamic>> threats);
} 