import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timizar_core/timizar_core.dart';

class SosSafetyScreen extends StatelessWidget {
  const SosSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Centre d\'Urgence & Sécurité'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.dangerRed, size: 28),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'En cas de danger immédiat, contactez directement les services de secours algériens.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Numéros d\'urgence nationaux',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              _buildEmergencyTile(
                icon: Icons.local_police_rounded,
                title: 'Police Nationale',
                number: '1548',
                description: 'Police secours et assistance',
              ),
              const SizedBox(height: 10),
              _buildEmergencyTile(
                icon: Icons.fire_truck_rounded,
                title: 'Protection Civile',
                number: '14',
                description: 'Ambulance, pompiers et secours médical',
              ),
              const SizedBox(height: 10),
              _buildEmergencyTile(
                icon: Icons.shield_rounded,
                title: 'Gendarmerie Nationale',
                number: '1055',
                description: 'Sécurité routière et zones hors agglomération',
              ),
              const Spacer(),
              TimizarButton(
                text: 'Partager ma position en direct',
                icon: const Icon(Icons.share_location_rounded, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lien de suivi GPS en direct copié')),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyTile({
    required IconData icon,
    required String title,
    required String number,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.dangerRed, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.dangerRed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
