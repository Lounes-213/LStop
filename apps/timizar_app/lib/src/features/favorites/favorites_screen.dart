import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timizar_core/timizar_core.dart';
import '../../providers.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _favorites = [];

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    final api = ref.read(apiClientProvider);
    final res = await api.get<Map<String, dynamic>>(
      ApiEndpoints.userFavorites,
      parser: (data) => data as Map<String, dynamic>,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    res.when(
      success: (data) {
        final list = (data['favorites'] as List? ?? []).cast<Map<String, dynamic>>();
        setState(() => _favorites = list);
      },
      failure: (err) {
        AppLogger.w('Failed to load favorites: $err');
      },
    );
  }

  Future<void> _addFavorite(String label, String address, double lat, double lng) async {
    final api = ref.read(apiClientProvider);
    await api.post(
      ApiEndpoints.userFavorites,
      data: {'label': label, 'address': address, 'lat': lat, 'lng': lng},
    );
    _fetchFavorites();
  }

  void _showAddDialog() {
    final labelCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter un lieu favori'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: 'Nom (ex: Maison, Travail)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'Adresse'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _addFavorite(
                labelCtrl.text.trim().isEmpty ? 'Lieu' : labelCtrl.text.trim(),
                addressCtrl.text.trim().isEmpty ? 'Tizi Ouzou' : addressCtrl.text.trim(),
                AppConstants.defaultTiziOuzouLat,
                AppConstants.defaultTiziOuzouLng,
              );
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Lieux Favoris'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_border_rounded, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Aucun lieu favori enregistré'),
                      const SizedBox(height: 16),
                      TimizarButton(
                        text: 'Ajouter une adresse',
                        width: 220,
                        onPressed: _showAddDialog,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favorites.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _favorites[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(
                          item['label'] == 'Maison' ? Icons.home_rounded : Icons.work_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(item['label'] as String? ?? 'Favori', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(item['address'] as String? ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        onPressed: () async {
                          final api = ref.read(apiClientProvider);
                          await api.delete('${ApiEndpoints.userFavorites}/${item['id']}');
                          _fetchFavorites();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
