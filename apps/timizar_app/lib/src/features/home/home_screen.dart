import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timizar_core/timizar_core.dart';
import '../../providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Realtime active drivers in this zone
  final Map<String, DriverLocation> _nearbyDrivers = {};

  // Current passenger location (Tizi Ouzou default)
  static const double _currentLat = AppConstants.defaultTiziOuzouLat;
  static const double _currentLng = AppConstants.defaultTiziOuzouLng;

  @override
  void initState() {
    super.initState();
    _initRealtimeSubscription();
  }

  void _initRealtimeSubscription() {
    final userAsync = ref.read(authStateProvider);
    final userId = userAsync.value?.id ?? 'anon';
    final geohash5 = GeohashHelper.encode(_currentLat, _currentLng, precision: 5);

    final realtime = ref.read(realtimeClientProvider);
    realtime.connectToZone(
      geohash5: geohash5,
      userId: userId,
      role: 'passenger',
      lat: _currentLat,
      lng: _currentLng,
    );

    realtime.messageStream.listen((msg) {
      if (!mounted) return;
      if (msg is NearbyDriversMessage) {
        setState(() {
          _nearbyDrivers.clear();
          for (final d in msg.drivers) {
            final loc = DriverLocation.fromJson(d);
            _nearbyDrivers[loc.driverId] = loc;
          }
        });
      } else if (msg is DriverMovedMessage) {
        setState(() {
          _nearbyDrivers[msg.driverId] = DriverLocation(
            driverId: msg.driverId,
            latitude: msg.latitude,
            longitude: msg.longitude,
            heading: msg.heading,
          );
        });
      } else if (msg is DriverLeftMessage) {
        setState(() {
          _nearbyDrivers.remove(msg.driverId);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildAppDrawer(context, user),
      body: Stack(
        children: [
          // 1. Map View
          const TimizarMapView(
            initialLat: _currentLat,
            initialLng: _currentLng,
          ),

          // 2. User Center Position Marker (matching blue navigation arrow from screenshot)
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 120),
              child: Transform.rotate(
                angle: -0.2, // Slight tilt matching arrow in screenshot
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7CF6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.navigation_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Top Floating Hamburger Menu Button (exact match from screenshot)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 12.0),
              child: Material(
                color: Colors.white,
                elevation: 4,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  borderRadius: BorderRadius.circular(16),
                  child: const SizedBox(
                    width: 52,
                    height: 52,
                    child: Center(
                      child: Icon(
                        Icons.menu_rounded,
                        color: Color(0xFF1E293B),
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. Bottom Sheet (Exact Match from screenshot)
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildPassengerBottomSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerBottomSheet(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar Pill
              TimizarSearchField(
                hintText: 'Rechercher',
                readOnly: true,
                onTap: () {
                  context.push('/search');
                },
              ),
              const SizedBox(height: 14),

              // Quick Action Pills ("Ajouter domicile", "Ajouter travail")
              Row(
                children: [
                  Expanded(
                    child: _buildActionPill(
                      icon: Icons.add_home_outlined,
                      label: 'Ajouter domicile',
                      onTap: () => context.push('/favorites'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionPill(
                      icon: Icons.work_outline_rounded,
                      label: 'Ajouter travail',
                      onTap: () => context.push('/favorites'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // "Récents" Section Header
              Row(
                children: [
                  const Text(
                    'Récents',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF64748B)),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Recent place item (matching screenshot: "Timizart Loghbar, Tizi Ouzou, DZA")
              InkWell(
                onTap: () {
                  context.push('/request', extra: {
                    'name': 'Timizart Loghbar',
                    'address': 'Timizart Loghbar, Tizi Ouzou, DZA',
                    'lat': 36.7350,
                    'lng': 4.0720,
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.mail_outline_rounded,
                          color: Color(0xFF475569),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Timizart Loghbar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Tizi Ouzou, DZA',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF334155)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppDrawer(BuildContext context, User? user) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // User Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                    child: user?.avatarUrl == null
                        ? const Icon(Icons.person_rounded, color: AppColors.primary, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Passager Timizar',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'passager@timizar.dz',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Links (matching screenshot 3)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _buildDrawerItem(
                    icon: Icons.star_border_rounded,
                    title: 'Favoris',
                    onTap: () {
                      context.pop();
                      context.push('/favorites');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.history_rounded,
                    title: 'Historique des courses',
                    onTap: () {
                      context.pop();
                      context.push('/history');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.security_rounded,
                    title: 'Urgence & Sécurité SOS',
                    textColor: AppColors.dangerRed,
                    iconColor: AppColors.dangerRed,
                    onTap: () {
                      context.pop();
                      context.push('/sos');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Paramètres',
                    onTap: () => context.pop(),
                  ),
                  _buildDrawerItem(
                    icon: Icons.info_outline_rounded,
                    title: 'À propos de Timizar',
                    onTap: () => context.pop(),
                  ),
                ],
              ),
            ),

            // Logout Action
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Déconnexion'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () async {
                  await ref.read(authStateProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? const Color(0xFF334155), size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ?? const Color(0xFF0F172A),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
      onTap: onTap,
    );
  }
}
