import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timizar_core/timizar_core.dart';
import '../../providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final authNotifier = ref.read(authStateProvider.notifier);
    final result = await authNotifier.signIn();
    if (!mounted) return;
    setState(() => _isLoading = false);

    result.when(
      success: (user) {
        context.go('/');
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // App Brand Logo / Icon
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.navigation_rounded,
                      color: AppColors.primary,
                      size: 48,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Timizar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Votre transport fiable et rapide en Algérie',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const Spacer(),
              // Highlights list
              _buildFeatureRow(Icons.security_rounded, 'Chauffeurs vérifiés et agréés'),
              const SizedBox(height: 12),
              _buildFeatureRow(Icons.location_on_rounded, 'Couverture Tizi Ouzou & wilayas d\'Algérie'),
              const SizedBox(height: 12),
              _buildFeatureRow(Icons.payments_rounded, 'Tarifs transparents en dinars (DZD)'),
              const Spacer(),
              // Google Sign-In Action
              TimizarButton(
                text: 'Continuer avec Google',
                isLoading: _isLoading,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 28, color: Colors.white),
                onPressed: _handleGoogleSignIn,
              ),
              const SizedBox(height: 16),
              const Text(
                'En continuant, vous acceptez les conditions d\'utilisation de Timizar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.pillBackgroundLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ),
      ],
    );
  }
}
