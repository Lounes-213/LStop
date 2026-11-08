import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class AlgerianPlace {
  final String name;
  final String detail;
  final LatLng location;

  const AlgerianPlace({
    required this.name,
    required this.detail,
    required this.location,
  });
}

class SearchPlacesBar extends StatefulWidget {
  final Function(AlgerianPlace) onPlaceSelected;
  final VoidCallback onClear;
  final VoidCallback onOpenDrawer;
  final VoidCallback onOpenLanguage;
  final VoidCallback onOpenDriverMode;

  const SearchPlacesBar({
    super.key,
    required this.onPlaceSelected,
    required this.onClear,
    required this.onOpenDrawer,
    required this.onOpenLanguage,
    required this.onOpenDriverMode,
  });

  @override
  State<SearchPlacesBar> createState() => _SearchPlacesBarState();
}

class _SearchPlacesBarState extends State<SearchPlacesBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isSearching = false;

  static const List<AlgerianPlace> popularPlaces = [
    AlgerianPlace(
      name: 'Gare Multimodale de Tizi Ouzou',
      detail: 'Kef Naadja, Tizi Ouzou',
      location: LatLng(36.7020, 4.0410),
    ),
    AlgerianPlace(
      name: 'Université Mouloud Mammeri (Hasnaoua)',
      detail: 'Boulevard des Frères Ouamrane, Tizi Ouzou',
      location: LatLng(36.7145, 4.0580),
    ),
    AlgerianPlace(
      name: 'Timizart Loghbar',
      detail: 'Route Nationale 12, Tizi Ouzou',
      location: LatLng(36.7350, 4.0720),
    ),
    AlgerianPlace(
      name: 'Azazga Centre',
      detail: 'RN12, Azazga',
      location: LatLng(36.7480, 4.3720),
    ),
    AlgerianPlace(
      name: 'Nouvelle Ville',
      detail: 'Cité 20 Août, Tizi Ouzou',
      location: LatLng(36.6890, 4.0610),
    ),
    AlgerianPlace(
      name: 'Draa Ben Khedda (DBK)',
      detail: 'Centre Ville, DBK',
      location: LatLng(36.7320, 3.9610),
    ),
  ];

  List<AlgerianPlace> _filteredPlaces = [];

  void _onQueryChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredPlaces = [];
      });
      return;
    }

    final q = query.toLowerCase();
    setState(() {
      _isSearching = true;
      _filteredPlaces = popularPlaces.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.detail.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Floating Search Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Drawer Menu Button
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A)),
                onPressed: widget.onOpenDrawer,
              ),
              // Search Input Field
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: _onQueryChanged,
                  decoration: const InputDecoration(
                    hintText: 'Où allez-vous ? (Recherche lieu, arrêt...)',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _controller.clear();
                    _onQueryChanged('');
                    widget.onClear();
                  },
                ),
              // Driver Mode Quick Switch Button
              IconButton(
                tooltip: 'Mode Chauffeur',
                icon: const Icon(
                  Icons.drive_eta_rounded,
                  color: Color(0xFF2563EB),
                ),
                onPressed: widget.onOpenDriverMode,
              ),
              // Language Switch Button
              IconButton(
                tooltip: 'Langue',
                icon: const Icon(Icons.language_rounded, color: Color(0xFF475569)),
                onPressed: widget.onOpenLanguage,
              ),
            ],
          ),
        ),

        // Autocomplete Results Dropdown
        if (_isSearching && _filteredPlaces.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: _filteredPlaces.length,
              separatorBuilder: (context, i) =>
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, i) {
                final place = _filteredPlaces[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                  title: Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    place.detail,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  onTap: () {
                    _controller.text = place.name;
                    setState(() => _isSearching = false);
                    widget.onPlaceSelected(place);
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
