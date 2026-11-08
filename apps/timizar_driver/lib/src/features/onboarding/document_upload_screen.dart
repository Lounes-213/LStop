import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timizar_core/timizar_core.dart';
import '../../providers.dart';

class DocumentUploadScreen extends ConsumerStatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  ConsumerState<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseCtrl = TextEditingController(text: 'DZ-15-884920');
  final _makeCtrl = TextEditingController(text: 'Dacia');
  final _modelCtrl = TextEditingController(text: 'Logan');
  final _yearCtrl = TextEditingController(text: '2022');
  final _colorCtrl = TextEditingController(text: 'Gris');
  final _plateCtrl = TextEditingController(text: '12345-122-15');

  bool _isSubmitting = false;

  @override
  void dispose() {
    _licenseCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitOnboarding() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final api = ref.read(apiClientProvider);
    final res = await api.post<Map<String, dynamic>>(
      ApiEndpoints.driverOnboard,
      data: {
        'licenseNumber': _licenseCtrl.text.trim(),
        'licenseDocumentUrl': 'https://timizar-storage.workers.dev/sample-license.jpg',
        'idCardDocumentUrl': 'https://timizar-storage.workers.dev/sample-id.jpg',
        'insuranceDocumentUrl': 'https://timizar-storage.workers.dev/sample-insurance.jpg',
        'vehicle': {
          'make': _makeCtrl.text.trim(),
          'model': _modelCtrl.text.trim(),
          'year': int.tryParse(_yearCtrl.text.trim()) ?? 2022,
          'color': _colorCtrl.text.trim(),
          'licensePlate': _plateCtrl.text.trim(),
        },
      },
      parser: (data) => data as Map<String, dynamic>,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    res.when(
      success: (data) async {
        await ref.read(driverAuthProvider.notifier).checkAuth();
        if (mounted) {
          context.go('/approval');
        }
      },
      failure: (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $err'), backgroundColor: AppColors.dangerRed),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dossier Chauffeur'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Complétez votre inscription',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Vérification obligatoire pour rouler sur la plateforme Timizar.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 20),
                const Text('Informations du Permis', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _licenseCtrl,
                  decoration: const InputDecoration(labelText: 'Numéro de permis de conduire', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 20),
                const Text('Informations du Véhicule', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _makeCtrl,
                        decoration: const InputDecoration(labelText: 'Marque (ex: Dacia)', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _modelCtrl,
                        decoration: const InputDecoration(labelText: 'Modèle (ex: Logan)', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yearCtrl,
                        decoration: const InputDecoration(labelText: 'Année', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _colorCtrl,
                        decoration: const InputDecoration(labelText: 'Couleur', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _plateCtrl,
                  decoration: const InputDecoration(labelText: 'Matricule (ex: 12345-122-15)', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 24),
                // Document upload cards
                _buildUploadDocTile('Permis de conduire (Recto / Verso)'),
                const SizedBox(height: 10),
                _buildUploadDocTile('Carte grise du véhicule'),
                const SizedBox(height: 10),
                _buildUploadDocTile('Attestation d\'assurance en cours de validité'),
                const SizedBox(height: 30),
                TimizarButton(
                  text: 'Soumettre mon dossier',
                  isLoading: _isSubmitting,
                  onPressed: _submitOnboarding,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadDocTile(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
        ],
      ),
    );
  }
}
