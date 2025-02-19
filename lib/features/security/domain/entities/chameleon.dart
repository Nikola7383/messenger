import 'package:equatable/equatable.dart';

enum ChameleonMode {
  decoy,    // Lažni mod pre događaja
  real,     // Pravi mod tokom događaja
  transition // Mod tokom prelaska
}

enum CamouflageTechnique {
  codeObfuscation,    // Obfuskacija koda
  trafficMasking,     // Maskiranje saobraćaja
  dataHiding,         // Skrivanje podataka
  networkSpoofing,    // Lažiranje mreže
  behaviorMimicking,  // Imitiranje ponašanja
}

class ChameleonConfig extends Equatable {
  final bool enableAntiDebug;
  final bool enableAntiTampering;
  final bool enableSteganography;
  final bool enableHoneypots;
  final Duration decoyModeInterval;
  final Duration transitionDuration;
  final Map<String, dynamic> decoyBehavior;
  final Map<String, dynamic> networkSignature;
  final List<CamouflageTechnique> activeTechniques;

  const ChameleonConfig({
    this.enableAntiDebug = true,
    this.enableAntiTampering = true,
    this.enableSteganography = true,
    this.enableHoneypots = true,
    this.decoyModeInterval = const Duration(hours: 12),
    this.transitionDuration = const Duration(minutes: 5),
    this.decoyBehavior = const {},
    this.networkSignature = const {},
    this.activeTechniques = const [],
  });

  @override
  List<Object?> get props => [
    enableAntiDebug,
    enableAntiTampering,
    enableSteganography,
    enableHoneypots,
    decoyModeInterval,
    transitionDuration,
    decoyBehavior,
    networkSignature,
    activeTechniques,
  ];
}

class Chameleon extends Equatable {
  final String id;
  final ChameleonMode mode;
  final ChameleonConfig config;
  final DateTime createdAt;
  final DateTime? lastModeChange;
  final Map<String, dynamic> currentState;
  final Map<String, dynamic> decoyRoutes;
  final Map<String, dynamic> securityMetrics;
  final List<Map<String, dynamic>> detectedThreats;
  final bool isCompromised;

  const Chameleon({
    required this.id,
    required this.mode,
    required this.config,
    required this.createdAt,
    this.lastModeChange,
    this.currentState = const {},
    this.decoyRoutes = const {},
    this.securityMetrics = const {},
    this.detectedThreats = const [],
    this.isCompromised = false,
  });

  bool get isInDecoyMode => mode == ChameleonMode.decoy;
  bool get isInRealMode => mode == ChameleonMode.real;
  bool get isInTransition => mode == ChameleonMode.transition;
  
  Duration get timeSinceLastModeChange => 
    lastModeChange != null ? DateTime.now().difference(lastModeChange!) : Duration.zero;

  bool get shouldTransition => 
    isInDecoyMode && timeSinceLastModeChange >= config.decoyModeInterval;

  Chameleon copyWith({
    String? id,
    ChameleonMode? mode,
    ChameleonConfig? config,
    DateTime? createdAt,
    DateTime? lastModeChange,
    Map<String, dynamic>? currentState,
    Map<String, dynamic>? decoyRoutes,
    Map<String, dynamic>? securityMetrics,
    List<Map<String, dynamic>>? detectedThreats,
    bool? isCompromised,
  }) {
    return Chameleon(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
      lastModeChange: lastModeChange ?? this.lastModeChange,
      currentState: currentState ?? this.currentState,
      decoyRoutes: decoyRoutes ?? this.decoyRoutes,
      securityMetrics: securityMetrics ?? this.securityMetrics,
      detectedThreats: detectedThreats ?? this.detectedThreats,
      isCompromised: isCompromised ?? this.isCompromised,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mode': mode.toString(),
      'config': {
        'enableAntiDebug': config.enableAntiDebug,
        'enableAntiTampering': config.enableAntiTampering,
        'enableSteganography': config.enableSteganography,
        'enableHoneypots': config.enableHoneypots,
        'decoyModeInterval': config.decoyModeInterval.inMilliseconds,
        'transitionDuration': config.transitionDuration.inMilliseconds,
        'decoyBehavior': config.decoyBehavior,
        'networkSignature': config.networkSignature,
        'activeTechniques': config.activeTechniques.map((t) => t.toString()).toList(),
      },
      'createdAt': createdAt.toIso8601String(),
      'lastModeChange': lastModeChange?.toIso8601String(),
      'currentState': currentState,
      'decoyRoutes': decoyRoutes,
      'securityMetrics': securityMetrics,
      'detectedThreats': detectedThreats,
      'isCompromised': isCompromised,
    };
  }

  factory Chameleon.fromJson(Map<String, dynamic> json) {
    return Chameleon(
      id: json['id'],
      mode: ChameleonMode.values.firstWhere(
        (e) => e.toString() == json['mode'],
      ),
      config: ChameleonConfig(
        enableAntiDebug: json['config']['enableAntiDebug'],
        enableAntiTampering: json['config']['enableAntiTampering'],
        enableSteganography: json['config']['enableSteganography'],
        enableHoneypots: json['config']['enableHoneypots'],
        decoyModeInterval: Duration(
          milliseconds: json['config']['decoyModeInterval'],
        ),
        transitionDuration: Duration(
          milliseconds: json['config']['transitionDuration'],
        ),
        decoyBehavior: json['config']['decoyBehavior'],
        networkSignature: json['config']['networkSignature'],
        activeTechniques: (json['config']['activeTechniques'] as List)
          .map((t) => CamouflageTechnique.values.firstWhere(
            (e) => e.toString() == t,
          ))
          .toList(),
      ),
      createdAt: DateTime.parse(json['createdAt']),
      lastModeChange: json['lastModeChange'] != null
        ? DateTime.parse(json['lastModeChange'])
        : null,
      currentState: json['currentState'],
      decoyRoutes: json['decoyRoutes'],
      securityMetrics: json['securityMetrics'],
      detectedThreats: List<Map<String, dynamic>>.from(json['detectedThreats']),
      isCompromised: json['isCompromised'],
    );
  }

  @override
  List<Object?> get props => [
    id,
    mode,
    config,
    createdAt,
    lastModeChange,
    currentState,
    decoyRoutes,
    securityMetrics,
    detectedThreats,
    isCompromised,
  ];
} 