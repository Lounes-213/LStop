import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timizar_core/timizar_core.dart';
import '../../providers.dart';

class DriverLoginScreen extends ConsumerStatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  ConsumerState<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends ConsumerState<DriverLoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final authNotifier = ref.read(driverAuthProvider.notifier);
    final result = await authNotifier.signIn();
    if (!mounted) return;
    setState(() => _isLoading = false);

    result.when(
      success: (_) {
        context.go('/');
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.dangerRed),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.local_taxi_rounded, color: AppColors.primary, size: 48),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Timizar Chauffeur',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Maximisez vos revenus en conduisant à votre rythme',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
              ),
              const Spacer(),
              _buildFeature(Icons.monetization_on_outlined, 'Paiements directs en espèces (DZD)'),
              const SizedBox(height: 14),
              _buildFeature(Icons.schedule_rounded, 'Liberté totale : passez en ligne quand vous voulez'),
              const SizedBox(height: 14),
              _buildFeature(Icons.map_rounded, 'Navigation GPS intégrée vers le passager'),
              const Spacer(),
              TimizarButton(
                text: 'Espace Chauffeur avec Google',
                isLoading: _isLoading,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 30, color: Colors.white),
                onPressed: _handleGoogleSignIn,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }
}
