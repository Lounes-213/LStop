import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'connected_devices_provider.dart';
import 'widgets/device_card.dart';
import 'widgets/microg_diagnostic_modal.dart';

class ConnectedDevicesScreen extends ConsumerStatefulWidget {
  const ConnectedDevicesScreen({super.key});

  @override
  ConsumerState<ConnectedDevicesScreen> createState() =>
      _ConnectedDevicesScreenState();
}

class _ConnectedDevicesScreenState extends ConsumerState<ConnectedDevicesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectedDevicesProvider);
    final notifier = ref.read(connectedDevicesProvider.notifier);
    final devices = state.filteredDevices;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar (Modern detached island style)
            _buildTopBar(context, state, notifier),

            // Filter Tabs & Search
            _buildSearchAndFilters(state, notifier),

            // Devices List
            Expanded(
              child: RefreshIndicator(
                onRefresh: notifier.refreshDevices,
                color: const Color(0xFF0D9488),
                child: devices.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          final isPinging = state.pingingDeviceId == device.id;

                          // Staggered slide-fade animation
                          final curved = CurvedAnimation(
                            parent: _animController,
                            curve: Interval(
                              (index * 0.12).clamp(0.0, 0.7),
                              ((index * 0.12) + 0.3).clamp(0.1, 1.0),
                              curve: Curves.easeOutCubic,
                            ),
                          );

                          return AnimatedBuilder(
                            animation: _animController,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: curved,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.08),
                                    end: Offset.zero,
                                  ).animate(curved),
                                  child: child,
                                ),
                              );
                            },
                            child: DeviceCard(
                              device: device,
                              isPinging: isPinging,
                              onPing: () => notifier.pingDevice(device.id),
                              onLocate: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Position de ${device.name}: ${device.latitude.toStringAsFixed(4)}, ${device.longitude.toStringAsFixed(4)}',
                                    ),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                context.pop();
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    ConnectedDevicesState state,
    ConnectedDevicesNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Back Button
              Material(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => context.pop(),
                  borderRadius: BorderRadius.circular(12),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Center(
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF0F172A),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appareils Connectés',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.onlineCount} actif(s) sur ${state.devices.length} • microG & GNSS',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // MicroG Info Action
              Material(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => MicroGDiagnosticModal.show(context),
                  borderRadius: BorderRadius.circular(12),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Center(
                      child: Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF0D9488),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Refresh Button
              Material(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: state.isRefreshing ? null : notifier.refreshDevices,
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Center(
                      child: state.isRefreshing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.refresh_rounded,
                              color: Color(0xFF334155),
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(
    ConnectedDevicesState state,
    ConnectedDevicesNotifier notifier,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Search Field
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: notifier.setSearchQuery,
                    decoration: const InputDecoration(
                      hintText: 'Filtrer par nom, ID ou adresse...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      notifier.setSearchQuery('');
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Filter Pills Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterPill(
                  label: 'Tous (${state.devices.length})',
                  key: 'all',
                  isSelected: state.selectedFilter == 'all',
                  onTap: () => notifier.setFilter('all'),
                ),
                const SizedBox(width: 8),
                _buildFilterPill(
                  label: 'En ligne (${state.onlineCount})',
                  key: 'online',
                  isSelected: state.selectedFilter == 'online',
                  onTap: () => notifier.setFilter('online'),
                ),
                const SizedBox(width: 8),
                _buildFilterPill(
                  label: 'Véhicules',
                  key: 'vehicle',
                  isSelected: state.selectedFilter == 'vehicle',
                  onTap: () => notifier.setFilter('vehicle'),
                ),
                const SizedBox(width: 8),
                _buildFilterPill(
                  label: 'Balises GPS',
                  key: 'tracker',
                  isSelected: state.selectedFilter == 'tracker',
                  onTap: () => notifier.setFilter('tracker'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required String key,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.devices_outlined,
                size: 32,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun appareil trouvé',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Vérifiez vos filtres de recherche ou réinitialisez la sélection.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
