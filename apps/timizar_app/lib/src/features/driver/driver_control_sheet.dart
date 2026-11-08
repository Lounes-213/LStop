import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../transport/fourgon_provider.dart';

class DriverControlSheet extends ConsumerStatefulWidget {
  const DriverControlSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DriverControlSheet(),
    );
  }

  @override
  ConsumerState<DriverControlSheet> createState() => _DriverControlSheetState();
}

class _DriverControlSheetState extends ConsumerState<DriverControlSheet> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final driverName = ref.read(transportProvider).driverCustomName;
    _nameController = TextEditingController(text: driverName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transportProvider);
    final notifier = ref.read(transportProvider.notifier);
    final driverFourgon = state.driverFourgon;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Indicator
            Center(
              child: Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.drive_eta_rounded,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Espace Chauffeur / Transporteur',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Configurez votre ligne et votre visibilité en direct',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Driver Name Input Field
            const Text(
              'Nom du Chauffeur / Transporteur',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Ex: Mourad Chauffeur, Karim T...',
                  prefixIcon: Icon(Icons.badge_outlined, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: notifier.updateDriverName,
              ),
            ),
            const SizedBox(height: 16),

            // Select Transport Line
            const Text(
              'Ligne de Transport desservie',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: availableTransportLines.map((line) {
                  final isSelected = line.id == state.driverSelectedLineId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(
                        line.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      selectedColor: line.color,
                      backgroundColor: const Color(0xFFF1F5F9),
                      onSelected: (val) {
                        if (val) notifier.updateDriverLine(line.id);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Visibility Toggle (Désactiver son affichage sur la map)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(
                    state.isDriverVisibleOnMap
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: state.isDriverVisibleOnMap
                        ? const Color(0xFF059669)
                        : const Color(0xFF64748B),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Afficher sur la carte des passagers',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Désactivez pour passer en pause ou masquer votre fourgon',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: state.isDriverVisibleOnMap,
                    activeTrackColor: const Color(0xFF059669),
                    onChanged: notifier.toggleDriverVisibility,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Driver Driving / Simulation Controls
            Row(
              children: [
                // Driving Toggle
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(
                      state.isDriverDriving
                          ? Icons.pause_circle_rounded
                          : Icons.play_circle_rounded,
                      size: 20,
                    ),
                    label: Text(
                      state.isDriverDriving ? 'En Pause' : 'Démarrer Trajet',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.isDriverDriving
                          ? const Color(0xFFD97706)
                          : const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      notifier.toggleDriverDriving(!state.isDriverDriving);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Step forward button
                OutlinedButton.icon(
                  icon: const Icon(Icons.skip_next_rounded, size: 20),
                  label: const Text('Avancer'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: notifier.advanceDriverPositionManually,
                ),
              ],
            ),
            if (driverFourgon != null) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Position actuelle : ${driverFourgon.currentLocation.latitude.toStringAsFixed(4)}, ${driverFourgon.currentLocation.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
