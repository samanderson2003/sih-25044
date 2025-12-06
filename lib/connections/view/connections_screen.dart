import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../controller/connections_controller.dart';
import '../../community_chat/view/community_chat_screen.dart';
import '../../news/view/news_feed_screen.dart';
import 'farmer_profile_card.dart';
import 'bot_screen.dart';
import '../../widgets/translated_text.dart';

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
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F6F0),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  bottom: 8,
                  left: 16,
                  right: 16,
                ),
                child: Row(
                  children: [
                    // Community Chat Button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CommunityChatScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/chats.png',
                          width: 36,
                          height: 34,
                          color: const Color(0xFF2D5016),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Title
                    const TranslatedText(
                      'FarmConnect',
                      style: TextStyle(
                        color: Color(0xFF2D5016),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    // News Feed Button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NewsFeedScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/news.png',
                          width: 34,
                          height: 34,
                          color: const Color(0xFF2D5016),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // FarmBot Chatbot Button
            Positioned(
              bottom: 40,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BotScreen()),
                  );
                },
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: Lottie.asset(
                    'assets/Green Robot.json',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // My Location Button
            Positioned(
              bottom: 140,
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
}
