import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timizar_core/timizar_core.dart';
import '../../providers.dart';

class DestinationSearchScreen extends ConsumerStatefulWidget {
  const DestinationSearchScreen({super.key});

  @override
  ConsumerState<DestinationSearchScreen> createState() => _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends ConsumerState<DestinationSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  List<PlaceResult> _results = [];

  // Regional suggestions for rapid booking without typing
  final List<PlaceResult> _popularPlaces = const [
    PlaceResult(
      id: 'p1',
      name: 'Gare Multimodale de Tizi Ouzou',
      address: 'Kef Naadja, Tizi Ouzou',
      lat: 36.7020,
      lng: 4.0410,
      municipality: 'Tizi Ouzou',
    ),
    PlaceResult(
      id: 'p2',
      name: 'Timizart Loghbar',
      address: 'Route Nationale 12, Tizi Ouzou',
      lat: 36.7350,
      lng: 4.0720,
      municipality: 'Tizi Ouzou',
    ),
    PlaceResult(
      id: 'p3',
      name: 'Université Mouloud Mammeri (Hasnaoua)',
      address: 'Boulevard des Frères Ouamrane, Tizi Ouzou',
      lat: 36.7145,
      lng: 4.0580,
      municipality: 'Tizi Ouzou',
    ),
    PlaceResult(
      id: 'p4',
      name: 'Centre Commercial Ardis / Alger',
      address: 'Lido, Mohammadia, Alger',
      lat: 36.7350,
      lng: 3.1650,
      municipality: 'Alger',
    ),
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    // 400ms debounce saves TomTom monthly quota
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final api = ref.read(apiClientProvider);
      final res = await api.get<Map<String, dynamic>>(
        ApiEndpoints.search,
        queryParameters: {
          'q': query,
          'lat': AppConstants.defaultTiziOuzouLat,
          'lng': AppConstants.defaultTiziOuzouLng,
        },
        parser: (data) => data as Map<String, dynamic>,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      res.when(
        success: (data) {
          final list = (data['results'] as List? ?? [])
              .map((item) => PlaceResult.fromJson(item as Map<String, dynamic>))
              .toList();
          setState(() => _results = list);
        },
        failure: (err) {
          AppLogger.w('Search failed: $err');
        },
      );
    });
  }

  void _selectPlace(PlaceResult place) {
    context.pushReplacement('/request', extra: {
      'name': place.name,
      'address': place.address,
      'lat': place.lat,
      'lng': place.lng,
    });
  }

  @override
  Widget build(BuildContext context) {
    final listToShow = _results.isNotEmpty ? _results : _popularPlaces;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: TimizarSearchField(
          controller: _controller,
          hintText: 'Où allez-vous ?',
          autofocus: true,
          onChanged: _onSearchChanged,
          onClear: () => setState(() => _results = []),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: listToShow.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
              itemBuilder: (context, index) {
                final place = listToShow[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    place.address,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _selectPlace(place),
                );
              },
            ),
    );
  }
}
