import 'package:flutter/material.dart';
import '../connected_device_model.dart';
import 'device_status_badge.dart';

class DeviceCard extends StatelessWidget {
  final ConnectedDevice device;
  final bool isPinging;
  final VoidCallback onPing;
  final VoidCallback onLocate;

  const DeviceCard({
    super.key,
    required this.device,
    required this.isPinging,
    required this.onPing,
    required this.onLocate,
  });

  String _formatElapsed(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 5) return 'À l\'instant';
    if (diff.inSeconds < 60) return 'Il y a ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}m';
    return 'Il y a ${diff.inHours}h';
  }

  IconData get _typeIcon => switch (device.type) {
        DeviceType.vehicle => Icons.directions_car_filled_outlined,
        DeviceType.tracker => Icons.sensors_outlined,
        DeviceType.terminal => Icons.phone_android_outlined,
      };

  @override
  Widget build(BuildContext context) {
    // Outer Shell (Double-Bezel)
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Subtle aluminum/slate tray
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3), // Double-bezel spacing
      child: Container(
        // Inner Core
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: const Color(0xFFF8FAFC),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Type Icon + Name + Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Device Icon in circular badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: device.isHostDevice
                        ? const Color(0xFFF0FDFA)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: device.isHostDevice
                          ? const Color(0xFFCCFBF1)
                          : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _typeIcon,
                      size: 22,
                      color: device.isHostDevice
                          ? const Color(0xFF0D9488)
                          : const Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Device Name & ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              device.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (device.isHostDevice) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'HÔTE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${device.id} • ${device.firmware}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                // Live Status Badge
                DeviceStatusBadge(status: device.status, compact: true),
              ],
            ),
            const SizedBox(height: 14),

            // Location Address
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEEF2F6)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Color(0xFF0D9488),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      device.address,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${device.latitude.toStringAsFixed(3)}, ${device.longitude.toStringAsFixed(3)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Telemetry Chips Grid
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildTelemetryChip(
                  icon: Icons.battery_charging_full_rounded,
                  label: '${device.batteryLevel}%',
                  accent: device.batteryLevel > 20
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                ),
                _buildTelemetryChip(
                  icon: Icons.signal_cellular_alt_rounded,
                  label: '${device.signalPercent}%',
                  accent: const Color(0xFF2563EB),
                ),
                _buildTelemetryChip(
                  icon: Icons.satellite_alt_outlined,
                  label: '${device.satellitesCount} Sats',
                  accent: const Color(0xFF475569),
                ),
                if (device.speedKmh > 0)
                  _buildTelemetryChip(
                    icon: Icons.speed_rounded,
                    label: '${device.speedKmh.toStringAsFixed(0)} km/h',
                    accent: const Color(0xFFD97706),
                  ),
                _buildTelemetryChip(
                  icon: Icons.lock_clock_outlined,
                  label: _formatElapsed(device.lastPing),
                  accent: const Color(0xFF64748B),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Provider source pill (microG tag)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.security_outlined,
                    size: 13,
                    color: Color(0xFF0D9488),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    device.locationSource,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),

            // Bottom Actions (Button-in-Button architecture)
            Row(
              children: [
                // Ping Action
                Expanded(
                  child: OutlinedButton(
                    onPressed: isPinging ? null : onPing,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isPinging
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi_tethering_rounded, size: 16),
                              SizedBox(width: 6),
                              Text('Ping Test', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                // Locate on Map
                Expanded(
                  child: ElevatedButton(
                    onPressed: onLocate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.near_me_outlined, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Localiser',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryChip({
    required IconData icon,
    required String label,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accent.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
