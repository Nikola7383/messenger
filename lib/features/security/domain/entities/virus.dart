import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum VirusType {
  probe,    // Za testiranje mreže
  guardian, // Za odbranu
  mutant,   // Mutirani virus
}

enum VirusState {
  dormant,  // Neaktivan
  active,   // Aktivan
  mutating, // U procesu mutacije
  dead,     // Završio životni ciklus
}

enum VirusCapability {
  networkScanning,    // Skeniranje mreže
  trafficAnalysis,    // Analiza saobraćaja
  patternRecognition, // Prepoznavanje obrazaca
  codeModification,   // Modifikacija koda
  selfReplication,    // Samo-repliciranje
  mutation,           // Sposobnost mutacije
}

class Virus extends Equatable {
  final String id;
  final VirusType type;
  final VirusState state;
  final Set<VirusCapability> capabilities;
  final String signature;
  final String? parentId;
  final int generation;
  final DateTime createdAt;
  final DateTime? activatedAt;
  final DateTime? lastMutatedAt;
  final Map<String, dynamic> behavior;
  final Map<String, dynamic>? mutationRules;
  final Map<String, dynamic> detectionPatterns;
  final Map<String, int> resourceUsage;

  const Virus({
    String? id,
    required this.type,
    this.state = VirusState.dormant,
    required this.capabilities,
    required this.signature,
    this.parentId,
    this.generation = 0,
    DateTime? createdAt,
    this.activatedAt,
    this.lastMutatedAt,
    required this.behavior,
    this.mutationRules,
    required this.detectionPatterns,
    required this.resourceUsage,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  bool get canMutate => capabilities.contains(VirusCapability.mutation);
  bool get isActive => state == VirusState.active;
  bool get isMutating => state == VirusState.mutating;
  bool get isDead => state == VirusState.dead;
  
  Duration get age => DateTime.now().difference(createdAt);
  Duration? get activeTime => activatedAt != null 
    ? DateTime.now().difference(activatedAt!) 
    : null;

  Virus copyWith({
    String? id,
    VirusType? type,
    VirusState? state,
    Set<VirusCapability>? capabilities,
    String? signature,
    String? parentId,
    int? generation,
    DateTime? createdAt,
    DateTime? activatedAt,
    DateTime? lastMutatedAt,
    Map<String, dynamic>? behavior,
    Map<String, dynamic>? mutationRules,
    Map<String, dynamic>? detectionPatterns,
    Map<String, int>? resourceUsage,
  }) {
    return Virus(
      id: id ?? this.id,
      type: type ?? this.type,
      state: state ?? this.state,
      capabilities: capabilities ?? this.capabilities,
      signature: signature ?? this.signature,
      parentId: parentId ?? this.parentId,
      generation: generation ?? this.generation,
      createdAt: createdAt ?? this.createdAt,
      activatedAt: activatedAt ?? this.activatedAt,
      lastMutatedAt: lastMutatedAt ?? this.lastMutatedAt,
      behavior: behavior ?? this.behavior,
      mutationRules: mutationRules ?? this.mutationRules,
      detectionPatterns: detectionPatterns ?? this.detectionPatterns,
      resourceUsage: resourceUsage ?? this.resourceUsage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'state': state.toString(),
      'capabilities': capabilities.map((c) => c.toString()).toList(),
      'signature': signature,
      'parentId': parentId,
      'generation': generation,
      'createdAt': createdAt.toIso8601String(),
      'activatedAt': activatedAt?.toIso8601String(),
      'lastMutatedAt': lastMutatedAt?.toIso8601String(),
      'behavior': behavior,
      'mutationRules': mutationRules,
      'detectionPatterns': detectionPatterns,
      'resourceUsage': resourceUsage,
    };
  }

  factory Virus.fromJson(Map<String, dynamic> json) {
    return Virus(
      id: json['id'],
      type: VirusType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      state: VirusState.values.firstWhere(
        (e) => e.toString() == json['state'],
      ),
      capabilities: (json['capabilities'] as List)
        .map((c) => VirusCapability.values.firstWhere(
          (e) => e.toString() == c,
        ))
        .toSet(),
      signature: json['signature'],
      parentId: json['parentId'],
      generation: json['generation'],
      createdAt: DateTime.parse(json['createdAt']),
      activatedAt: json['activatedAt'] != null 
        ? DateTime.parse(json['activatedAt'])
        : null,
      lastMutatedAt: json['lastMutatedAt'] != null
        ? DateTime.parse(json['lastMutatedAt'])
        : null,
      behavior: json['behavior'],
      mutationRules: json['mutationRules'],
      detectionPatterns: json['detectionPatterns'],
      resourceUsage: Map<String, int>.from(json['resourceUsage']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    state,
    capabilities,
    signature,
    parentId,
    generation,
    createdAt,
    activatedAt,
    lastMutatedAt,
    behavior,
    mutationRules,
    detectionPatterns,
    resourceUsage,
  ];
} 