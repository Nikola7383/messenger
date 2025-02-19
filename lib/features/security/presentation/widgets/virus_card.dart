import 'package:flutter/material.dart';
import 'package:glasnik/features/security/domain/entities/virus.dart';

class VirusCard extends StatelessWidget {
  final Virus virus;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;
  final VoidCallback onMutate;
  final VoidCallback onReplicate;

  const VirusCard({
    super.key,
    required this.virus,
    required this.onActivate,
    required this.onDeactivate,
    required this.onMutate,
    required this.onReplicate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTypeIcon(),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Virus ${virus.id.substring(0, 8)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Tip: ${virus.type.toString().split('.').last}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _buildStateChip(),
              ],
            ),
            const Divider(),
            // Capabilities
            Wrap(
              spacing: 8,
              children: virus.capabilities.map((capability) {
                return Chip(
                  label: Text(
                    capability.toString().split('.').last,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: _getCapabilityColor(capability),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // Resource Usage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildResourceIndicator(
                  'CPU',
                  virus.resourceUsage['cpu'] ?? 0,
                  Colors.blue,
                ),
                _buildResourceIndicator(
                  'MEM',
                  virus.resourceUsage['memory'] ?? 0,
                  Colors.green,
                ),
                _buildResourceIndicator(
                  'NET',
                  virus.resourceUsage['network'] ?? 0,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (virus.canMutate)
                  TextButton.icon(
                    icon: const Icon(Icons.change_circle),
                    label: const Text('Mutiraj'),
                    onPressed: onMutate,
                  ),
                if (virus.capabilities.contains(VirusCapability.selfReplication))
                  TextButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('Repliciraj'),
                    onPressed: onReplicate,
                  ),
                const SizedBox(width: 8),
                if (virus.isActive)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.stop),
                    label: const Text('Deaktiviraj'),
                    onPressed: onDeactivate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Aktiviraj'),
                    onPressed: onActivate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    IconData iconData;
    Color color;

    switch (virus.type) {
      case VirusType.probe:
        iconData = Icons.search;
        color = Colors.blue;
        break;
      case VirusType.guardian:
        iconData = Icons.security;
        color = Colors.green;
        break;
      case VirusType.mutant:
        iconData = Icons.change_circle;
        color = Colors.purple;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color),
    );
  }

  Widget _buildStateChip() {
    Color color;
    String label;

    switch (virus.state) {
      case VirusState.dormant:
        color = Colors.grey;
        label = 'Neaktivan';
        break;
      case VirusState.active:
        color = Colors.green;
        label = 'Aktivan';
        break;
      case VirusState.mutating:
        color = Colors.purple;
        label = 'Mutira';
        break;
      case VirusState.dead:
        color = Colors.red;
        label = 'Mrtav';
        break;
    }

    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
        ),
      ),
      backgroundColor: color.withOpacity(0.2),
      side: BorderSide(color: color),
    );
  }

  Color _getCapabilityColor(VirusCapability capability) {
    switch (capability) {
      case VirusCapability.networkScanning:
        return Colors.blue.withOpacity(0.2);
      case VirusCapability.trafficAnalysis:
        return Colors.green.withOpacity(0.2);
      case VirusCapability.patternRecognition:
        return Colors.orange.withOpacity(0.2);
      case VirusCapability.codeModification:
        return Colors.red.withOpacity(0.2);
      case VirusCapability.selfReplication:
        return Colors.purple.withOpacity(0.2);
      case VirusCapability.mutation:
        return Colors.teal.withOpacity(0.2);
    }
  }

  Widget _buildResourceIndicator(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          height: 4,
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value%',
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
} 