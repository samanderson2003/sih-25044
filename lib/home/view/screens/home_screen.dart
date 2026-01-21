import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:lottie/lottie.dart';
import '../../controller/home_controller.dart';
import '../../model/crop_model.dart';
import '../../model/livestock_model.dart';
// import 'calender_full_screen.dart';
import 'crop_plan_screen.dart';
import '../../../widgets/translated_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  Timer? _resumeScrollTimer;
  bool _isUserInteracting = false;
  late final HomeController _homeController;

  @override
  void initState() {
    super.initState();
    _homeController = HomeController();

    _pageController = PageController(
      viewportFraction: 0.28,
      initialPage: 500000,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _resumeScrollTimer?.cancel();
    _pageController.dispose();
    _homeController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (
      timer,
    ) {
      if (!_isUserInteracting && mounted && _pageController.hasClients) {
        try {
          final double currentOffset = _pageController.offset;
          final double nextOffset = currentOffset + 2.5;
          _pageController.jumpTo(nextOffset);
        } catch (e) {
          // Ignore errors
        }
      }
    });
  }

  void _onUserScroll() {
    _isUserInteracting = true;
    _resumeScrollTimer?.cancel();
    _resumeScrollTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _isUserInteracting = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _homeController,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F0),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFF8F6F0),
          surfaceTintColor: Colors.transparent,
          /*
          leading: IconButton(
            icon: const Icon(
              Icons.calendar_month,
              color: Color(0xFF2D5016),
              size: 24,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: _homeController,
                    child: const CalendarFullScreen(),
                  ),
                ),
              );
            },
          ),
          */
          centerTitle: true,
          title: const TranslatedText(
            'Crop Management',
            style: TextStyle(
              color: Color(0xFF2D5016),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          actions: [
            Consumer<HomeController>(
              builder: (context, controller, _) => IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: Color(0xFF2D5016),
                  size: 22,
                ),
                onPressed: controller.refreshWeather,
              ),
            ),
          ],
        ),
        body: Consumer<HomeController>(
          builder: (context, controller, _) {
            if (controller.isLoadingCrops || controller.isLoadingWeather) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/loading.json',
                      width: 150,
                      height: 150,
                    ),
                    const SizedBox(height: 16),
                    TranslatedText(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: controller.refreshWeather,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // New Redesigned Weather (No Box, Just Content + Line)
                    _buildWeatherSection(controller),

                    const SizedBox(height: 16),
                    
                    // Toggle Switch (Crop / Livestock)
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                            child: SegmentedButton<bool>(
                              segments: [
                                ButtonSegment<bool>(
                                    value: true, 
                                    label: TranslatedText('Crops'), 
                                    icon: Icon(Icons.grass)
                                ),
                                ButtonSegment<bool>(
                                    value: false, 
                                    label: TranslatedText('Livestock'), 
                                    icon: Icon(Icons.pets)
                                ),
                              ],
                              selected: {controller.isCropView},
                              onSelectionChanged: (Set<bool> newSelection) {
                                controller.toggleView(newSelection.first);
                              },
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
                                    if (states.contains(MaterialState.selected)) {
                                      return const Color(0xFF2D5016);
                                    }
                                    return Colors.transparent;
                                  },
                                ),
                                foregroundColor: MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
                                    if (states.contains(MaterialState.selected)) {
                                      return Colors.white;
                                    }
                                    return Colors.black;
                                  },
                                ),
                              ),
                            ),
                       ),
                    ),

                    const SizedBox(height: 24),

                    // Crop Selection Header
                    // Crop/Livestock Selection Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TranslatedText(
                            controller.isCropView ? 'Select Crop' : 'Select Livestock',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF212121),
                            ),
                          ),
                          TranslatedText(
                            controller.isCropView 
                                ? '${controller.crops.length} crops'
                                : '${controller.livestockList.length} types',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Horizontal Carousel with Auto-scroll
                    SizedBox(
                      height: 120,
                      child: controller.isCropView 
                          ? (controller.crops.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Lottie.asset(
                                        'assets/loading.json',
                                        width: 100,
                                        height: 100,
                                      ),
                                      const SizedBox(height: 8),
                                      TranslatedText(
                                        'Loading crops...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : GestureDetector(
                                  onPanDown: (_) => _onUserScroll(),
                                  child: PageView.builder(
                                    controller: _pageController,
                                    itemCount: 1000000, // Infinite scrolling
                                    physics: const BouncingScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final cropIndex =
                                          index % controller.crops.length;
                                      final crop = controller.crops[cropIndex];
                                      final isSelected =
                                          controller.selectedCrop?.id == crop.id;
  
                                      return Center(
                                        child: _buildCropCard(
                                          crop,
                                          isSelected,
                                          controller,
                                        ),
                                      );
                                    },
                                  ),
                                ))
                          : (controller.livestockList.isEmpty 
                              ? const Center(child: Text("No livestock info"))
                              : Center(
                                  child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: controller.livestockList.length,
                                  itemBuilder: (context, index) {
                                      final livestock = controller.livestockList[index];
                                      final isSelected = controller.selectedLivestock?.id == livestock.id;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 16),
                                        child: Center(
                                          child: _buildLivestockCard(livestock, isSelected, controller)
                                        ),
                                      );
                                  },
                                ),
                              )),    
                    ),

                    const SizedBox(height: 20),

                    // AI-Generated Lifecycle Stages Timeline
                    // AI-Generated Lifecycle Stages Timeline OR Livestock Care
                    if (controller.isCropView)
                         if (controller.selectedCrop != null &&
                            controller.selectedCrop!.lifecycleStages.isNotEmpty)
                          _buildLifecycleStagesTimeline(controller)
                    else 
                         if (controller.selectedLivestock != null)
                             _buildLivestockCareTimeline(controller),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- WIDGETS ---

  // UPDATED: No Background, Large Icon, Divider Line
  Widget _buildWeatherSection(HomeController controller) {
    final weather = controller.currentWeather;
    if (weather == null) return const SizedBox.shrink();

    // Determine Lottie asset
    String lottieAsset = 'assets/sunny.json';
    if (weather.condition.toLowerCase().contains('rain')) {
      lottieAsset = 'assets/Rainy.json';
    } else if (weather.condition.toLowerCase().contains('cloud')) {
      lottieAsset = 'assets/Cloudy.json';
    }

    // Colors for text since background is removed
    final Color mainTextColor = const Color(0xFF2D5016); // App Theme Green/Dark
    final Color subTextColor = Colors.grey.shade600;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5).withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Top Row: Animation + Main Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Lottie Animation
                  SizedBox(
                    height: 180,
                    width: 180,
                    child: Transform.translate(
                      offset: const Offset(-10, 0),
                      child: Lottie.asset(
                        lottieAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) => const Icon(
                          Icons.wb_sunny,
                          color: Colors.amber,
                          size: 80,
                        ),
                      ),
                    ),
                  ),

                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${weather.temperature.toInt()}°C',
                          style: TextStyle(
                            fontSize: 56, // Large modern font
                            fontWeight: FontWeight.w300,
                            color: mainTextColor,
                            letterSpacing: -2,
                            height: 1,
                          ),
                        ),
                        TranslatedText(
                          weather.condition,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: mainTextColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.location_on,
                              color: subTextColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: TranslatedText(
                                weather.location,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: subTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Bottom Row: Soil & Humidity (Clean Capsules)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.thermostat,
                                color: Colors.orange.shade400,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TranslatedText(
                                      'Soil Temp',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '+${(weather.temperature - 5).toInt()}°C',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: mainTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.water_drop,
                            color: Colors.blue.shade400,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TranslatedText(
                                  'Humidity',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${weather.humidity.toInt()}%',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: mainTextColor,
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
            ],
          ),
        ),

        // --- THE DIVIDER LINE REQUESTED ---
        Center(
          child: Container(
            width: 100,
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade300.withOpacity(0.5),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCropCard(Crop crop, bool isSelected, HomeController controller) {
    return GestureDetector(
      onTap: () {
        controller.selectCrop(crop);
        _onUserScroll();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: isSelected
                  ? crop.themeColor.withOpacity(0.15)
                  : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? crop.themeColor : const Color(0xFFE0E0E0),
                width: isSelected ? 3 : 2,
              ),
            ),
            child: Center(
              child: Text(crop.icon, style: const TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 8),
          TranslatedText(
            crop.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? crop.themeColor : const Color(0xFF424242),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivestockCard(Livestock livestock, bool isSelected, HomeController controller) {
    return GestureDetector(
      onTap: () {
        controller.selectLivestock(livestock);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: isSelected
                  ? livestock.themeColor.withOpacity(0.15)
                  : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? livestock.themeColor : const Color(0xFFE0E0E0),
                width: isSelected ? 3 : 2,
              ),
            ),
            child: Center(
              child: Text(livestock.icon, style: const TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 8),
          TranslatedText(
            livestock.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? livestock.themeColor : const Color(0xFF424242),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivestockCareTimeline(HomeController controller) {
      final livestock = controller.selectedLivestock;
      if (livestock == null) return const SizedBox.shrink();
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: livestock.themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.health_and_safety,
                    color: livestock.themeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                 Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      '${livestock.name} Care Schedule',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const TranslatedText(
                      'Vaccination & Health Guide',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          Timeline.tileBuilder(
            theme: TimelineThemeData(
              nodePosition: 0,
              color: Colors.grey.shade300,
              connectorTheme: const ConnectorThemeData(thickness: 2.0),
            ),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            builder: TimelineTileBuilder.connected(
                itemCount: livestock.lifecycleStages.length,
                connectionDirection: ConnectionDirection.before,
                connectorBuilder: (context, index, type) {
                   return SolidLineConnector(
                      color: index < livestock.lifecycleStages.length // All colored for info
                          ? livestock.themeColor
                          : Colors.grey.shade300,
                   );
                },
                indicatorBuilder: (context, index) {
                   return DotIndicator(
                      color: livestock.themeColor,
                      child: Icon(
                          Icons.check, 
                          color: Colors.white, 
                          size: 14
                      ),
                   );
                },
                contentsBuilder: (context, index) {
                  final stage = livestock.lifecycleStages[index];
                  return Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 24),
                    child: Container(
                         width: double.infinity,
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: Colors.white,
                           borderRadius: BorderRadius.circular(16),
                           border: Border.all(color: Colors.grey.shade200),
                           boxShadow: [
                             BoxShadow(
                               color: Colors.black.withOpacity(0.04),
                               blurRadius: 8,
                               offset: const Offset(0, 4),
                             ),
                           ],
                         ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Row(
                                    children: [
                                         Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                                color: livestock.themeColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              children: [
                                                const TranslatedText(
                                                  'Age: ',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF2D5016), // livestock.themeColor (hardcoded to green for simplicity in rewrite or need to access outer scope variable?)
                                                  ),
                                                ),
                                                Text(
                                                  '${stage.ageInMonths}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: livestock.themeColor,
                                                  ),
                                                ),
                                                const TranslatedText(
                                                  ' Months',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF2D5016),
                                                  ),
                                                ),
                                              ],
                                            ),
                                         ),
                                         const Spacer(),
                                         Icon(stage.iconData, color: Colors.grey.shade400, size: 20),
                                    ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                    stage.actionTitle,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF212121)
                                    ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    stage.description,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                        height: 1.4
                                    ),
                                ),
                            ],
                        ),
                    ),
                  );
                },
            ),
          ),
        ],
      );
  }

  // Original Month-based Timeline
  Widget _buildMonthlyTimeline(HomeController controller) {
    final months = [
      {'name': 'January', 'number': 1},
      {'name': 'February', 'number': 2},
      {'name': 'March', 'number': 3},
      {'name': 'April', 'number': 4},
      {'name': 'May', 'number': 5},
      {'name': 'June', 'number': 6},
      {'name': 'July', 'number': 7},
      {'name': 'August', 'number': 8},
      {'name': 'September', 'number': 9},
      {'name': 'October', 'number': 10},
      {'name': 'November', 'number': 11},
      {'name': 'December', 'number': 12},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: controller.selectedCrop?.themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: controller.selectedCrop?.themeColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    'Monthly Calendar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  TranslatedText(
                    'Tap month to view detailed plan',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Timeline.tileBuilder(
          theme: TimelineThemeData(
            nodePosition: 0.5,
            color: Colors.grey.shade300,
            connectorTheme: const ConnectorThemeData(thickness: 4.0),
          ),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
          builder: TimelineTileBuilder.connected(
            itemCount: 12,
            connectionDirection: ConnectionDirection.after,
            contentsAlign: ContentsAlign.alternating,
            connectorBuilder: (context, index, type) {
              if (index + 1 < 12) {
                final nextMonthNum = months[index + 1]['number'] as int;
                final nextSuit = controller.getSuitabilityForMonth(
                  nextMonthNum,
                );
                if (nextSuit != SeasonSuitability.notRecommended) {
                  return SolidLineConnector(
                    color: controller.selectedCrop?.themeColor.withOpacity(0.5),
                  );
                }
              }
              return SolidLineConnector(color: Colors.grey.shade200);
            },
            indicatorBuilder: (context, index) {
              final monthNum = months[index]['number'] as int;
              final suitability = controller.getSuitabilityForMonth(monthNum);

              Widget indicator;
              Color borderColor;

              if (suitability == SeasonSuitability.highCompatibility) {
                borderColor =
                    controller.selectedCrop?.themeColor ?? Colors.green;
                indicator = Lottie.asset(
                  'assets/sowing.json',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.spa, color: borderColor, size: 30);
                  },
                );
              } else if (suitability == SeasonSuitability.normal) {
                borderColor =
                    (controller.selectedCrop?.themeColor ?? Colors.green)
                        .withOpacity(0.7);
                indicator = Lottie.asset(
                  'assets/growing.json',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.park, color: borderColor, size: 30);
                  },
                );
              } else {
                borderColor = Colors.grey.shade300;
                indicator = Icon(
                  Icons.bedtime,
                  color: Colors.grey.shade400,
                  size: 26,
                );
              }

              return Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: suitability == SeasonSuitability.highCompatibility
                        ? 2.5
                        : 1.5,
                  ),
                  boxShadow: [
                    if (suitability != SeasonSuitability.notRecommended)
                      BoxShadow(
                        color: borderColor.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Center(child: indicator),
              );
            },
            contentsBuilder: (context, index) {
              final month = months[index];
              final monthNum = month['number'] as int;
              final monthName = month['name'] as String;
              final suitability = controller.getSuitabilityForMonth(monthNum);
              final isRecommended =
                  suitability != SeasonSuitability.notRecommended;

              String dateSuffix = "";
              if (suitability == SeasonSuitability.highCompatibility) {
                dateSuffix = " 1 - 15";
              } else if (suitability == SeasonSuitability.normal) {
                dateSuffix = " 1 - 30";
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8.0,
                ),
                child: GestureDetector(
                  onTap: () {
                    if (isRecommended && controller.selectedCrop != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CropPlanScreen(
                            crop: controller.selectedCrop!,
                            startMonth: monthNum,
                          ),
                        ),
                      );
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: index % 2 == 0
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      TranslatedText(
                        monthName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isRecommended ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      if (isRecommended)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TranslatedText(
                                monthName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: controller.selectedCrop?.themeColor ?? Colors.green,
                                ),
                              ),
                              Text(
                                dateSuffix,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: controller.selectedCrop?.themeColor ?? Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 6),
                      if (isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                suitability ==
                                    SeasonSuitability.highCompatibility
                                ? Colors.green.shade50
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  suitability ==
                                      SeasonSuitability.highCompatibility
                                  ? Colors.green.shade200
                                  : Colors.blue.shade200,
                              width: 0.5,
                            ),
                          ),
                          child: TranslatedText(
                            suitability == SeasonSuitability.highCompatibility
                                ? '🌱 Sowing'
                                : '🌿 Growing',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color:
                                  suitability ==
                                      SeasonSuitability.highCompatibility
                                  ? Colors.green.shade800
                                  : Colors.blue.shade800,
                            ),
                          ),
                        )
                      else
                        TranslatedText(
                          'Rest Period',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade400,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // New Lifecycle Stages Timeline
  Widget _buildLifecycleStagesTimeline(HomeController controller) {
    final crop = controller.selectedCrop!;
    final stages = crop.lifecycleStages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: crop.themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.eco, color: crop.themeColor, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TranslatedText(
                    'Crop Lifecycle',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  TranslatedText(
                    'Schedule for ${crop.name}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Timeline.tileBuilder(
          theme: TimelineThemeData(
            nodePosition: 0.5,
            color: Colors.grey.shade300,
            connectorTheme: const ConnectorThemeData(thickness: 4.0),
          ),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
          builder: TimelineTileBuilder.connected(
            itemCount: stages.length,
            connectionDirection: ConnectionDirection.after,
            contentsAlign: ContentsAlign.alternating,

            connectorBuilder: (context, index, type) {
              return SolidLineConnector(
                color: crop.themeColor.withOpacity(0.5),
              );
            },

            indicatorBuilder: (context, index) {
              final stage = stages[index];

              // Map stage names to Lottie animations
              String? lottieAsset;
              Color borderColor = crop.themeColor;

              switch (stage.stageName.toLowerCase()) {
                case 'land preparation':
                  lottieAsset = 'assets/land preparation.json';
                  break;
                case 'seed selection & treatment':
                case 'seed selection':
                  lottieAsset = 'assets/seeds.json';
                  break;
                case 'sowing/transplanting':
                case 'sowing':
                case 'transplanting':
                  lottieAsset = 'assets/sowing.json';
                  break;
                case 'irrigation management':
                case 'irrigation':
                  lottieAsset = 'assets/Rainy.json';
                  break;
                case 'intercultural operations':
                case 'weeding':
                  lottieAsset = 'assets/growing.json';
                  break;
                case 'plant protection':
                case 'pest control':
                  lottieAsset = 'assets/plant protection.json';
                  break;
                case 'harvesting':
                case 'harvest':
                  lottieAsset = 'assets/harvest.json';
                  break;
                case 'post-harvest processing':
                case 'post-harvest':
                  lottieAsset = 'assets/harvest.json';
                  break;
                default:
                  lottieAsset = 'assets/growing.json';
              }

              Widget indicator = Lottie.asset(
                lottieAsset,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(stage.iconData, color: borderColor, size: 30);
                },
              );

              return Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: borderColor.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(child: indicator),
              );
            },

            contentsBuilder: (context, index) {
              final stage = stages[index];

              // Calculate month-based date range from days after planting
              final dateData = _calculateMonthDateRange(
                controller,
                stage.daysAfterPlanting,
              );

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8.0,
                ),
                child: GestureDetector(
                  onTap: () {
                    // Navigate to detailed timeline view
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CropPlanScreen(
                          crop: crop,
                          startMonth: _findBestPlantingMonth(controller),
                        ),
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: index % 2 == 0
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      TranslatedText(
                        stage.stageName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        textAlign: index % 2 == 0
                            ? TextAlign.right
                            : TextAlign.left,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TranslatedText(
                              dateData['month']!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: crop.themeColor,
                              ),
                            ),
                            Text(
                              dateData['suffix']!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: crop.themeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: crop.themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: crop.themeColor.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: TranslatedText(
                          stage.actionTitle,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: crop.themeColor,
                          ),
                          textAlign: index % 2 == 0
                              ? TextAlign.right
                              : TextAlign.left,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Return a Map with 'month' and 'suffix' for translation
  Map<String, String> _calculateMonthDateRange(
    HomeController controller,
    int daysAfterPlanting,
  ) {
    // Find the best planting month for the selected crop
    int plantingMonth = _findBestPlantingMonth(controller);

    // Calculate the target date by adding days to planting month
    DateTime plantingDate = DateTime(DateTime.now().year, plantingMonth, 1);
    DateTime targetDate = plantingDate.add(Duration(days: daysAfterPlanting));

    // Format the date range
    const monthNames = [
      '',
      'January', // Use full names for translation dictionary matching
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    // Calculate start and end dates for a ~10 day period
    DateTime startDate = targetDate;
    DateTime endDate = targetDate.add(const Duration(days: 10));

    // Get days in month to avoid going over
    int daysInMonth = DateTime(startDate.year, startDate.month + 1, 0).day;
    int startDay = startDate.day;
    int endDay = endDate.day;

    String monthName = monthNames[startDate.month];

    // If end date goes to next month, cap it at month end
    if (endDate.month != startDate.month) {
      endDay = daysInMonth;
      return {'month': monthName, 'suffix': " $startDay - $endDay"};
    }

    // If end day exceeds month days, cap it
    if (endDay > daysInMonth) {
      endDay = daysInMonth;
    }

    return {'month': monthName, 'suffix': " $startDay - $endDay"};
  }

  // Find the best planting month (high compatibility month)
  int _findBestPlantingMonth(HomeController controller) {
    for (int month = 1; month <= 12; month++) {
      final suitability = controller.getSuitabilityForMonth(month);
      if (suitability == SeasonSuitability.highCompatibility) {
        return month;
      }
    }
    // Fallback to current month if no high compatibility found
    return DateTime.now().month;
  }
}
