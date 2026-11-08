import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timizar_core/timizar_core.dart';
import '../../providers.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(driverAuthProvider);
    final driver = authState.driver;

    final isApproved = driver?.approvalStatus == DriverApprovalStatus.approved;
    final isRejected = driver?.approvalStatus == DriverApprovalStatus.rejected;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Validation du compte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(driverAuthProvider.notifier).checkAuth(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: isApproved
                        ? const Color(0xFFF0FDF4)
                        : isRejected
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFFFFBEB),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isApproved
                          ? Icons.check_circle_rounded
                          : isRejected
                              ? Icons.cancel_rounded
                              : Icons.hourglass_top_rounded,
                      color: isApproved
                          ? AppColors.primary
                          : isRejected
                              ? AppColors.dangerRed
                              : AppColors.warningOrange,
                      size: 52,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isApproved
                    ? 'Compte chauffeur approuvé !'
                    : isRejected
                        ? 'Dossier non validé'
                        : 'Dossier en cours d\'examen',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isApproved
                    ? 'Félicitations, vous pouvez désormais passer en ligne et recevoir des courses.'
                    : isRejected
                        ? 'Votre dossier a été refusé. Veuillez vérifier vos documents ou contacter le support.'
                        : 'Votre dossier est en cours de révision par l\'équipe d\'administration Timizar. Vous recevrez une notification dès validation.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 36),
              if (isApproved)
                TimizarButton(
                  text: 'Accéder au Cockpit Chauffeur',
                  onPressed: () => context.go('/'),
                )
              else
                TimizarButton(
                  text: 'Actualiser le statut',
                  variant: ButtonVariant.outline,
                  onPressed: () async {
                    await ref.read(driverAuthProvider.notifier).checkAuth();
                  },
                ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(driverAuthProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
