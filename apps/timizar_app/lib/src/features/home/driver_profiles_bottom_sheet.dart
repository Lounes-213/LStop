import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../search/unified_search_service.dart';
import '../transport/fourgon_model.dart';
import '../transport/fourgon_provider.dart';
import '../transport/routing_service.dart';

class DriverProfilesBottomSheet extends StatefulWidget {
  final DraggableScrollableController sheetController;
  final LatLng userLocation;
  final List<Fourgon> fourgons;
  final Fourgon? selectedFourgon;
  final Function(Fourgon) onSelectDriver;
  final Function(UnifiedSearchResult) onSelectSearchResult;
  final VoidCallback onExpandSheet;
  final String selectedLineFilter;
  final Function(String) onSelectLineFilter;

  const DriverProfilesBottomSheet({
    super.key,
    required this.sheetController,
    required this.userLocation,
    required this.fourgons,
    this.selectedFourgon,
    required this.onSelectDriver,
    required this.onSelectSearchResult,
    required this.onExpandSheet,
    required this.selectedLineFilter,
    required this.onSelectLineFilter,
  });

  @override
  State<DriverProfilesBottomSheet> createState() =>
      _DriverProfilesBottomSheetState();
}

class _DriverProfilesBottomSheetState
    extends State<DriverProfilesBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<UnifiedSearchResult> _searchResults = [];
  bool _isSearching = false;

  void _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    // Agrandir automatiquement la page du bas lors de la recherche pour afficher les résultats sans débordement
    if (widget.sheetController.isAttached && widget.sheetController.size < 0.70) {
      widget.sheetController.animateTo(
        0.88,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }

    setState(() => _isSearching = true);
    final results = await UnifiedSearchService.search(
      query: query,
      activeFourgons: widget.fourgons,
    );

    if (!mounted) return;
    setState(() => _searchResults = results);
  }

  double _calculateDistanceKm(LatLng a, LatLng b) {
    const p = 0.017453292519943295;
    final c = 0.5 -
        math.cos((b.latitude - a.latitude) * p) / 2 +
        math.cos(a.latitude * p) *
            math.cos(b.latitude * p) *
            (1 - math.cos((b.longitude - a.longitude) * p)) /
            2;
    final dist = (12742 * math.asin(math.sqrt(c.clamp(0.0, 1.0)))) * 1.25;
    return double.parse(dist.toStringAsFixed(1));
  }

  /// Ouvre le menu tactile avec les 2 choix : Tracer l'itinéraire OU Voir le profil
  void _showDriverOptions(BuildContext context, Fourgon fourgon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Driver Mini Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: fourgon.lineColor.withValues(alpha: 0.15),
                        backgroundImage: fourgon.avatarUrl != null
                            ? NetworkImage(fourgon.avatarUrl!)
                            : null,
                        onBackgroundImageError: fourgon.avatarUrl != null ? (_, __) {} : null,
                        child: fourgon.avatarUrl == null
                            ? Text(
                                fourgon.driverName.isNotEmpty
                                    ? fourgon.driverName[0].toUpperCase()
                                    : 'C',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: fourgon.lineColor,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fourgon.driverName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${fourgon.lineTitle} • ${fourgon.vehicleName}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: fourgon.lineColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Option 1 : Tracer l'itinéraire
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    tileColor: const Color(0xFFEFF6FF),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.near_me_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Tracer l\'itinéraire',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: const Text(
                      'Dessiner le tracé routier réel jusqu\'au fourgon',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      widget.onSelectDriver(fourgon);
                    },
                  ),
                  const SizedBox(height: 10),

                  // Option 2 : Voir son profil
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    tileColor: Colors.white,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        color: Color(0xFF0F172A),
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Voir son profil',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: const Text(
                      'Numéro de téléphone, note, matricule et avis',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showDriverFullProfileDialog(context, fourgon);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Dialogue affichant le profil complet du chauffeur
  void _showDriverFullProfileDialog(BuildContext context, Fourgon fourgon) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Real portrait avatar with colored ring
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: fourgon.lineColor, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 34,
                    backgroundImage: fourgon.avatarUrl != null
                        ? NetworkImage(fourgon.avatarUrl!)
                        : null,
                    onBackgroundImageError: fourgon.avatarUrl != null ? (_, __) {} : null,
                    backgroundColor: fourgon.lineColor.withValues(alpha: 0.15),
                    child: fourgon.avatarUrl == null
                        ? Text(
                            fourgon.driverName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: fourgon.lineColor,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  fourgon.driverName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  fourgon.lineTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fourgon.lineColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 14),

                // Stats Row (Note, Courses, Places)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildProfileStat(
                      icon: Icons.star_rounded,
                      color: const Color(0xFFF59E0B),
                      value: '${fourgon.rating}',
                      label: 'Note',
                    ),
                    _buildProfileStat(
                      icon: Icons.directions_bus_rounded,
                      color: const Color(0xFF2563EB),
                      value: '${fourgon.totalTrips}',
                      label: 'Courses',
                    ),
                    _buildProfileStat(
                      icon: Icons.event_seat_rounded,
                      color: const Color(0xFF0D9488),
                      value: '${fourgon.seatsAvailable}',
                      label: 'Places dispo',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Phone and Vehicle Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF2563EB)),
                          const SizedBox(width: 8),
                          Text(
                            fourgon.phone,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.car_rental_rounded, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${fourgon.vehicleName} (${fourgon.plate})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action: Tracer l'itinéraire
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.near_me_rounded, size: 18),
                    label: const Text('Tracer l\'itinéraire'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      widget.onSelectDriver(fourgon);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileStat({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: widget.sheetController,
      initialChildSize: 0.35,
      minChildSize: 0.22,
      maxChildSize: 0.90,
      snap: true,
      snapSizes: const [0.22, 0.35, 0.70, 0.90],
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 28,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // 1. Drag Handle Area with real-time finger tracking up and down (ttharek ttabe3 lyed)
                  GestureDetector(
                    onTap: widget.onExpandSheet,
                    onVerticalDragUpdate: (drag) {
                      if (widget.sheetController.isAttached) {
                        final screenHeight = MediaQuery.of(context).size.height;
                        if (screenHeight > 0) {
                          final delta = -drag.primaryDelta! / screenHeight;
                          final newSize = (widget.sheetController.size + delta).clamp(0.20, 0.90);
                          widget.sheetController.jumpTo(newSize);
                        }
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 10, bottom: 6),
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 5.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFF94A3B8).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Integrated Search Bar (Places, Lignes, Chauffeurs)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.search_rounded,
                            size: 19,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearch,
                              decoration: const InputDecoration(
                                hintText:
                                    'Rechercher lieu, ligne ou chauffeur...',
                                hintStyle: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF94A3B8),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                _onSearch('');
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Line Filter Chips (Filtres des Lignes de Transport)
                  Container(
                    height: 36,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildFilterChip(
                          label: 'Toutes les lignes',
                          id: 'all',
                          color: const Color(0xFF0F172A),
                          isSelected: widget.selectedLineFilter == 'all',
                        ),
                        ...availableTransportLines.map((line) {
                          return _buildFilterChip(
                            label: line.name.split(':').first.trim(),
                            id: line.id,
                            color: line.color,
                            isSelected: widget.selectedLineFilter == line.id,
                          );
                        }),
                      ],
                    ),
                  ),

                  // 4. Driver Profiles List / Search Results (Scrollable to the top)
                  Expanded(
                    child: _isSearching
                        ? _buildSearchResults()
                        : _buildDriversProfileList(scrollController),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String id,
    required Color color,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: Material(
        color: isSelected ? color : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => widget.onSelectLineFilter(id),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          'Aucun résultat trouvé.',
          style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        final icon = switch (item.type) {
          SearchResultType.place => Icons.location_on_outlined,
          SearchResultType.line => Icons.timeline_rounded,
          SearchResultType.fourgon => Icons.person_pin_circle_outlined,
        };

        return ListTile(
          dense: true,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
          ),
          title: Text(
            item.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            item.subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            _searchController.clear();
            setState(() => _isSearching = false);
            widget.onSelectSearchResult(item);
          },
        );
      },
    );
  }

  Widget _buildDriversProfileList(ScrollController scrollController) {
    if (widget.fourgons.isEmpty) {
      return const Center(
        child: Text(
          'Aucun fourgon sur cette ligne actuellement.',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
      itemCount: widget.fourgons.length,
      itemBuilder: (context, index) {
        final fourgon = widget.fourgons[index];
        final isSelected = widget.selectedFourgon?.id == fourgon.id;

        // REAL distance from YOUR REAL GPS POSITION
        final realDistKm =
            _calculateDistanceKm(widget.userLocation, fourgon.currentLocation);
        // REALISTIC Algerian fourgon duration
        final realisticEtaMins =
            RoutingService.calculateRealisticFourgonDuration(realDistKm);

        return Container(
          margin: const EdgeInsets.only(bottom: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFEFF6FF).withValues(alpha: 0.95)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? fourgon.lineColor : const Color(0xFFE2E8F0),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => _showDriverOptions(context, fourgon), // Ouvre les 2 choix (Tracer route OU Voir profil)
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Avatar Photo de Profil RÉELLE
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 23,
                          backgroundColor:
                              fourgon.lineColor.withValues(alpha: 0.15),
                          backgroundImage: fourgon.avatarUrl != null
                              ? NetworkImage(fourgon.avatarUrl!)
                              : null,
                          onBackgroundImageError: fourgon.avatarUrl != null ? (_, __) {} : null,
                          child: fourgon.avatarUrl == null
                              ? Text(
                                  fourgon.driverName.isNotEmpty
                                      ? fourgon.driverName[0].toUpperCase()
                                      : 'C',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: fourgon.lineColor,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Driver details + "Win wsel" (En temps réel)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  fourgon.driverName,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: fourgon.lineColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  fourgon.lineId,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: fourgon.lineColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          // "Win wsel" live badge
                          Row(
                            children: [
                              const Icon(
                                Icons.near_me_rounded,
                                size: 12,
                                color: Color(0xFF0D9488),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Position : ${fourgon.currentStatusText}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0D9488),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${fourgon.vehicleName} • ${fourgon.seatsAvailable} places',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // ETA & Distance
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$realisticEtaMins min',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${realDistKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
