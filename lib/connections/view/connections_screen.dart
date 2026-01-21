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
                  circles: controller.circles,
                  onMapCreated: controller.setMapController,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                  onTap: (_) => controller.clearSelection(),
                  buildingsEnabled: true,
                  compassEnabled: true,
                  indoorViewEnabled: true,
                  trafficEnabled: false,
                  mapToolbarEnabled: true,
                  minMaxZoomPreference: const MinMaxZoomPreference(2, 20),
                  tiltGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                );
              },
            ),

            // Loading Indicator
            Consumer<ConnectionsController>(
              builder: (context, controller, _) {
                if (!controller.isLoading) return const SizedBox.shrink();

                return Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Card(
                      margin: EdgeInsets.all(20),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2D5016),
                              ),
                            ),
                            SizedBox(height: 16),
                              const TranslatedText(
                                'Loading farmers...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Error Display
            Consumer<ConnectionsController>(
              builder: (context, controller, _) {
                if (controller.error == null) return const SizedBox.shrink();

                return Positioned(
                  top: MediaQuery.of(context).padding.top + 80,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              controller.error!,
                              style: TextStyle(color: Colors.red[900]),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: controller.refreshFarmers,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Debug Info (Top-right corner)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              right: 16,
              child: Consumer<ConnectionsController>(
                builder: (context, controller, _) {
                  return Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '👥 ${controller.farmers.length} farmers',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '📍 ${controller.markers.length} markers',
                            style: const TextStyle(fontSize: 11),
                          ),
                          if (controller.currentUser != null)
                            Text(
                              '🏠 ${controller.currentUser!.name}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
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

            // Filter Chips Bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 55,
              left: 0,
              right: 0,
              child: Consumer<ConnectionsController>(
                builder: (context, controller, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Filter Chips Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(
                                context,
                                controller,
                                MapFilterType.all,
                                '🌍 All',
                                Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                context,
                                controller,
                                MapFilterType.crop,
                                '🌾 Crops',
                                Colors.green,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                context,
                                controller,
                                MapFilterType.livestock,
                                '🐄 Livestock',
                                Colors.purple,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                context,
                                controller,
                                MapFilterType.alerts,
                                '⚠️ Alerts',
                                Colors.orange,
                              ),
                            ],
                          ),
                        ),
                        // Alert Radius Slider (only shown when alerts filter is selected)
                        if (controller.selectedFilter == MapFilterType.alerts) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.radar, size: 16, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(
                                'Radius: ${controller.alertRadius.toStringAsFixed(0)} km',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Expanded(
                                child: Slider(
                                  value: controller.alertRadius,
                                  min: 1,
                                  max: 50,
                                  divisions: 49,
                                  activeColor: Colors.orange,
                                  inactiveColor: Colors.orange.withOpacity(0.3),
                                  onChanged: (value) {
                                    controller.setAlertRadius(value);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
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
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Refresh Button
                      FloatingActionButton(
                        mini: true,
                        heroTag: 'refresh',
                        backgroundColor: Colors.white,
                        onPressed: controller.refreshFarmers,
                        child: const Icon(
                          Icons.refresh,
                          color: Color(0xFF2D5016),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // My Location Button
                      FloatingActionButton(
                        mini: true,
                        heroTag: 'location',
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
                      ),
                    ],
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
        floatingActionButton: Consumer<ConnectionsController>(
          builder: (context, controller, _) {
            if (controller.isLoading) return const SizedBox.shrink();
            
            return FloatingActionButton.extended(
              onPressed: () => _showMarkAlertDialog(context, controller),
              backgroundColor: Colors.redAccent,
              icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
              label: const TranslatedText('Mark Alert', style: TextStyle(color: Colors.white)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    ConnectionsController controller,
    MapFilterType filterType,
    String label,
    Color color,
  ) {
    final isSelected = controller.selectedFilter == filterType;
    return GestureDetector(
      onTap: () => controller.setFilter(filterType),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: TranslatedText(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }


  void _showMarkAlertDialog(BuildContext context, ConnectionsController controller) {
    final alertController = TextEditingController();
    String selectedType = 'General';
    double radius = 500;
    
    // Determine available types based on filter
    List<String> availableTypes = ['General', 'Crop', 'Livestock'];
    if (controller.selectedFilter == MapFilterType.crop) {
      availableTypes = ['Crop'];
      selectedType = 'Crop';
    } else if (controller.selectedFilter == MapFilterType.livestock) {
      availableTypes = ['Livestock'];
      selectedType = 'Livestock';
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const TranslatedText('Mark Risk Alert'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TranslatedText(
                    'Report an issue at your location to warn other farmers.',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  
                  // Alert Type Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      label: TranslatedText('Alert Type'),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: availableTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(
                              type == 'Crop' ? Icons.grass : 
                              type == 'Livestock' ? Icons.pets : Icons.warning_amber,
                              color: type == 'Crop' ? Colors.green : 
                                     type == 'Livestock' ? Colors.purple : Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(type), // Type names (Crop, Livestock) should also be translated ideally, or use icons mostly
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
        
                  TextField(
                    controller: alertController,
                    decoration: const InputDecoration(
                      label: TranslatedText('Alert Message'),
                      hintText: 'e.g., Pest Attack, Disease', // Hint text needs dynamic translation or manual lookup
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit),
                    ),
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 20),
                  Text(
                    'Alert Radius: ${radius.toInt()}m',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: radius,
                    min: 100,
                    max: 5000,
                    divisions: 49,
                    label: '${radius.toInt()}m',
                    activeColor: selectedType == 'Crop' ? Colors.green : 
                                 selectedType == 'Livestock' ? Colors.purple : Colors.orange,
                    onChanged: (value) {
                      setState(() => radius = value);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const TranslatedText('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (alertController.text.trim().isNotEmpty) {
                    controller.markRiskAlert(
                      alertController.text,
                      selectedType,
                      radius,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Alert marked ($selectedType) with ${radius.toInt()}m radius!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D5016)),
                child: const TranslatedText('Mark Alert', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }
}
