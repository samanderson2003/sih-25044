import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../controller/connections_controller.dart';
import '../../community_chat/view/community_chat_screen.dart';
import '../../news/view/news_feed_screen.dart';
import 'farmer_profile_card.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(13.0827, 80.2707), // Chennai coordinates
    zoom: 12,
  );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConnectionsController(),
      child: Scaffold(
        body: Stack(
          children: [
            // Google Map
            Consumer<ConnectionsController>(
              builder: (context, controller, _) {
                return GoogleMap(
                  initialCameraPosition: _initialPosition,
                  markers: controller.markers,
                  onMapCreated: controller.setMapController,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                  onTap: (_) => controller.clearSelection(),
                );
              },
            ),

            // Top Navigation Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  bottom: 12,
                  left: 16,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5016),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Community Chat Button
                    _buildTopNavButton(
                      icon: Icons.chat_bubble,
                      label: 'Community',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CommunityChatScreen(),
                          ),
                        );
                      },
                    ),

                    // Title
                    const Text(
                      'AgriConnect',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),

                    // News Feed Button
                    _buildTopNavButton(
                      icon: Icons.article,
                      label: 'News',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NewsFeedScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // My Location Button
            Positioned(
              bottom: 120,
              right: 16,
              child: Consumer<ConnectionsController>(
                builder: (context, controller, _) {
                  return FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: () {
                      if (controller.currentUser != null) {
                        controller.moveToLocation(
                          controller.currentUser!.latitude,
                          controller.currentUser!.longitude,
                        );
                      }
                    },
                    child: const Icon(
                      Icons.my_location,
                      color: Color(0xFF2D5016),
                    ),
                  );
                },
              ),
            ),

            // Farmer Profile Card (Bottom Sheet)
            Consumer<ConnectionsController>(
              builder: (context, controller, _) {
                if (controller.selectedFarmer == null) {
                  return const SizedBox.shrink();
                }

                final isCurrentUser =
                    controller.selectedFarmer?.id == controller.currentUser?.id;

                return Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.65,
                    child: FarmerProfileCard(
                      farmer: controller.selectedFarmer!,
                      isCurrentUser: isCurrentUser,
                      onClose: controller.clearSelection,
                      onToggleFollow: () {
                        controller.toggleFollow(controller.selectedFarmer!.id);
                      },
                      onCall: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Calling ${controller.selectedFarmer!.phoneNumber}...',
                            ),
                          ),
                        );
                      },
                      onMessage: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Opening chat with ${controller.selectedFarmer!.name}...',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
