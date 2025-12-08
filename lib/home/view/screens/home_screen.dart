import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:sih_25044/home/model/weather_model.dart'; // Adjust path if needed
import 'package:table_calendar/table_calendar.dart';
import 'package:timelines_plus/timelines_plus.dart';
import '../../controller/home_controller.dart';
import '../../model/crop_model.dart';
import '../widgets/weather_indicator.dart';
import '../widgets/crop_tile.dart';
import 'calender_full_screen.dart';
import 'month_detail_screen.dart';
import 'daily_actions_screen.dart';
import 'crop_plan_screen.dart'; // <--- IMPORT THIS
import '../../../services/ml_api_service.dart';
import '../../../prior_data/controller/farm_data_controller.dart';
import '../../../widgets/translated_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  Timer? _resumeScrollTimer;
  bool _isUserInteracting = false;
  late final HomeController _homeController;

  String _calendarView = 'year';
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  int _yearPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _homeController = HomeController();
    _pageController = PageController(
      viewportFraction: 0.35,
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
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.calendar_month,
              color: Color(0xFF2D5016),
              size: 28,
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
          centerTitle: true,
          title: const TranslatedText(
            'Crop Management',
            style: TextStyle(
              color: Color(0xFF2D5016),
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          actions: [
            Consumer<HomeController>(
              builder: (context, controller, _) => IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF2D5016)),
                onPressed: controller.refreshWeather,
              ),
            ),
          ],
        ),
        body: Consumer<HomeController>(
          builder: (context, controller, _) {
            if (controller.isLoadingCrops || controller.isLoadingWeather) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: controller.refreshWeather,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WeatherIndicator(weather: controller.currentWeather),
                    const SizedBox(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const TranslatedText(
                            'Select Crop',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D5016),
                            ),
                          ),
                          TranslatedText(
                            '${controller.crops.length} crops',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 100,
                      child: GestureDetector(
                        onPanDown: (_) => _onUserScroll(),
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: 1000000,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final cropIndex = index % controller.crops.length;
                            final crop = controller.crops[cropIndex];
                            final isSelected =
                                controller.selectedCrop?.id == crop.id;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: CropTile(
                                crop: crop,
                                isSelected: isSelected,
                                onTap: () {
                                  controller.selectCrop(crop);
                                  _onUserScroll();
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- TIMELINE SECTION (UPDATED) ---
                    if (controller.selectedCrop != null)
                      _buildCropGrowthTimeline(controller),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- UPDATED TIMELINE BUILDER WITH ONTAP NAVIGATION ---
  Widget _buildCropGrowthTimeline(HomeController controller) {
    final months = [
      {'name': 'January', 'abbr': 'Jan', 'number': 1},
      {'name': 'February', 'abbr': 'Feb', 'number': 2},
      {'name': 'March', 'abbr': 'Mar', 'number': 3},
      {'name': 'April', 'abbr': 'Apr', 'number': 4},
      {'name': 'May', 'abbr': 'May', 'number': 5},
      {'name': 'June', 'abbr': 'Jun', 'number': 6},
      {'name': 'July', 'abbr': 'Jul', 'number': 7},
      {'name': 'August', 'abbr': 'Aug', 'number': 8},
      {'name': 'September', 'abbr': 'Sep', 'number': 9},
      {'name': 'October', 'abbr': 'Oct', 'number': 10},
      {'name': 'November', 'abbr': 'Nov', 'number': 11},
      {'name': 'December', 'abbr': 'Dec', 'number': 12},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline,
                color:
                    controller.selectedCrop?.themeColor ??
                    const Color(0xFF4CAF50),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      'Annual Growth Timeline',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            controller.selectedCrop?.themeColor ??
                            const Color(0xFF2D5016),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TranslatedText(
                      'Tap a valid month to see daily plan',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 480,
            child: Timeline.tileBuilder(
              theme: TimelineThemeData(
                nodePosition: 0,
                color: Colors.grey[300]!,
                indicatorTheme: const IndicatorThemeData(size: 24),
                connectorTheme: ConnectorThemeData(
                  thickness: 3,
                  color: Colors.grey[300]!,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              builder: TimelineTileBuilder.connected(
                itemCount: 12,
                connectionDirection: ConnectionDirection.before,
                contentsAlign: ContentsAlign.basic,
                contentsBuilder: (context, index) {
                  final month = months[index];
                  final monthNum = month['number'] as int;
                  final suitability = controller.getSuitabilityForMonth(
                    monthNum,
                  );

                  // --- THIS GESTURE DETECTOR IS THE KEY CHANGE ---
                  return GestureDetector(
                    onTap: () {
                      if (suitability != SeasonSuitability.notRecommended &&
                          controller.selectedCrop != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CropPlanScreen(
                              crop: controller.selectedCrop!,
                              startMonth: monthNum,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'This month is not recommended for planting',
                            ),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 20),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              suitability?.color.withOpacity(0.15) ??
                              Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: suitability?.color ?? Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          TranslatedText(
                                            month['name'] as String,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  suitability?.color ??
                                                  Colors.grey[800],
                                            ),
                                          ),
                                          if (suitability !=
                                              SeasonSuitability.notRecommended)
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 12,
                                              color: suitability?.color,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      TranslatedText(
                                        _getBestCropForMonth(
                                          monthNum,
                                          controller,
                                        ),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (suitability != null) ...[
                              const SizedBox(height: 12),
                              ..._getDailyActivities(
                                    monthNum,
                                    suitability,
                                    month['name'] as String,
                                    controller,
                                  )
                                  .map(
                                    (activity) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 4,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: suitability.color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TranslatedText(
                                              activity,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[700],
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
                indicatorBuilder: (context, index) {
                  final month = months[index];
                  final monthNum = month['number'] as int;
                  final suitability = controller.getSuitabilityForMonth(
                    monthNum,
                  );
                  final isCurrentMonth = monthNum == DateTime.now().month;

                  return DotIndicator(
                    size: isCurrentMonth ? 28 : 24,
                    color: suitability?.color ?? Colors.grey[400]!,
                    border: isCurrentMonth
                        ? Border.all(color: Colors.black87, width: 3)
                        : null,
                    child: isCurrentMonth
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  );
                },
                connectorBuilder: (context, index, connectorType) {
                  final month = months[index];
                  final monthNum = month['number'] as int;
                  final suitability = controller.getSuitabilityForMonth(
                    monthNum,
                  );

                  return SolidLineConnector(
                    color: suitability?.color ?? Colors.grey[300]!,
                    thickness: 3,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER METHODS PRESERVED BELOW ---

  List<String> _getDailyActivities(
    int monthNum,
    SeasonSuitability suitability,
    String monthName,
    HomeController controller,
  ) {
    final daysInMonth = DateTime(DateTime.now().year, monthNum + 1, 0).day;
    final cropName = controller.selectedCrop?.name ?? 'crop';

    if (suitability == SeasonSuitability.notRecommended) {
      return [
        '📅 Day 1-$daysInMonth: Not recommended for $cropName',
        '⚠️ Consider alternative crops or wait',
      ];
    }

    // Updated text to encourage clicking
    if (suitability == SeasonSuitability.highCompatibility) {
      return [
        '📅 Tap to view full day-wise schedule',
        '🌱 Includes: Sowing, Irrigation & Fertilizer',
      ];
    } else {
      return [
        '📅 Tap to view maintenance schedule',
        '🌱 Includes: Field Prep & Planting',
      ];
    }
  }

  String _getBestCropForMonth(int monthNum, HomeController controller) {
    final crops = controller.crops;
    if (crops.isEmpty) {
      return controller.selectedCrop?.name ?? 'Crop';
    }
    Crop? bestCrop;
    SeasonSuitability? bestSuitability;

    for (final crop in crops) {
      final suitability = crop.monthSuitability[monthNum];
      if (suitability != null) {
        if (bestSuitability == null ||
            _isBetterSuitability(suitability, bestSuitability)) {
          bestCrop = crop;
          bestSuitability = suitability;
        }
      }
    }
    return bestCrop?.name ?? controller.selectedCrop?.name ?? 'Crop';
  }

  bool _isBetterSuitability(SeasonSuitability a, SeasonSuitability b) {
    const priority = {
      SeasonSuitability.highCompatibility: 3,
      SeasonSuitability.normal: 2,
      SeasonSuitability.notRecommended: 1,
    };
    return (priority[a] ?? 0) > (priority[b] ?? 0);
  }
}

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:sih_25044/home/model/weather_model.dart';
// import 'package:table_calendar/table_calendar.dart';
// import 'package:timelines_plus/timelines_plus.dart';
// import '../../controller/home_controller.dart';
// import '../../model/crop_model.dart';
// import '../widgets/weather_indicator.dart';
// import '../widgets/crop_tile.dart';
// import 'month_detail_screen.dart';
// import 'daily_actions_screen.dart';
// import '../../../services/ml_api_service.dart';
// import '../../../prior_data/controller/farm_data_controller.dart';
// import '../../../widgets/translated_text.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen>
//     with SingleTickerProviderStateMixin {
//   DateTime _focusedDay = DateTime.now();
//   DateTime? _selectedDay;
//   late final PageController _pageController;
//   Timer? _autoScrollTimer;
//   Timer? _resumeScrollTimer;
//   bool _isUserInteracting = false;
//   late final HomeController _homeController;
//
//   // Calendar navigation state
//   String _calendarView = 'year'; // 'year', 'month', or 'date'
//   int _selectedYear = DateTime.now().year;
//   int _selectedMonth = DateTime.now().month;
//   int _yearPageIndex = 0; // For navigating year pages
//
//   @override
//   void initState() {
//     super.initState();
//     _homeController = HomeController();
//     _pageController = PageController(
//       viewportFraction: 0.35,
//       initialPage: 500000,
//     );
//     // Start auto-scroll after widget is built
//     Future.delayed(const Duration(milliseconds: 500), () {
//       if (mounted) {
//         _startAutoScroll();
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _autoScrollTimer?.cancel();
//     _resumeScrollTimer?.cancel();
//     _pageController.dispose();
//     _homeController.dispose();
//     super.dispose();
//   }
//
//   void _startAutoScroll() {
//     _autoScrollTimer?.cancel();
//
//     _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (
//       timer,
//     ) {
//       if (!_isUserInteracting && mounted && _pageController.hasClients) {
//         try {
//           final double currentOffset = _pageController.offset;
//           final double nextOffset = currentOffset + 2.5;
//
//           _pageController.jumpTo(nextOffset);
//         } catch (e) {
//           // Ignore errors during scrolling
//         }
//       }
//     });
//   }
//
//   void _onUserScroll() {
//     _isUserInteracting = true;
//     _resumeScrollTimer?.cancel();
//     _resumeScrollTimer = Timer(const Duration(seconds: 3), () {
//       if (mounted) {
//         _isUserInteracting = false;
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider.value(
//       value: _homeController,
//       child: Scaffold(
//         backgroundColor: const Color(0xFFF8F6F0),
//         appBar: AppBar(
//           elevation: 0,
//           backgroundColor: const Color(0xFFF8F6F0),
//           surfaceTintColor: Colors.transparent,
//           scrolledUnderElevation: 0,
//           leading: IconButton(
//             icon: const Icon(
//               Icons.calendar_month,
//               color: Color(0xFF2D5016),
//               size: 28,
//             ),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => ChangeNotifierProvider.value(
//                     value: _homeController,
//                     child: const CalendarFullScreen(),
//                   ),
//                 ),
//               );
//             },
//           ),
//           centerTitle: true,
//           title: const TranslatedText(
//             'Crop Management',
//             style: TextStyle(
//               color: Color(0xFF2D5016),
//               fontWeight: FontWeight.w600,
//               fontSize: 20,
//             ),
//           ),
//           actions: [
//             Consumer<HomeController>(
//               builder: (context, controller, _) => controller.alerts.isNotEmpty
//                   ? Stack(
//                       children: [
//                         IconButton(
//                           icon: const Icon(
//                             Icons.notification_important,
//                             color: Color(0xFF2D5016),
//                           ),
//                           onPressed: () =>
//                               _showAlertsDialog(context, controller),
//                         ),
//                         Positioned(
//                           right: 8,
//                           top: 8,
//                           child: Container(
//                             padding: const EdgeInsets.all(4),
//                             decoration: BoxDecoration(
//                               color: Colors.red,
//                               shape: BoxShape.circle,
//                             ),
//                             constraints: const BoxConstraints(
//                               minWidth: 16,
//                               minHeight: 16,
//                             ),
//                             child: Text(
//                               '${controller.alerts.length}',
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 9,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                         ),
//                       ],
//                     )
//                   : const SizedBox.shrink(),
//             ),
//             Consumer<HomeController>(
//               builder: (context, controller, _) => IconButton(
//                 icon: const Icon(Icons.refresh, color: Color(0xFF2D5016)),
//                 onPressed: controller.refreshWeather,
//               ),
//             ),
//           ],
//         ),
//         body: Consumer<HomeController>(
//           builder: (context, controller, _) {
//             if (controller.isLoadingCrops || controller.isLoadingWeather) {
//               return const Center(child: CircularProgressIndicator());
//             }
//
//             return RefreshIndicator(
//               onRefresh: controller.refreshWeather,
//               child: SingleChildScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Weather Indicator
//                     WeatherIndicator(weather: controller.currentWeather),
//
//                     const SizedBox(height: 1),
//
//                     // Crop Selection Section
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 16),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           const TranslatedText(
//                             'Select Crop',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w600,
//                               color: Color(0xFF2D5016),
//                             ),
//                           ),
//                           TranslatedText(
//                             '${controller.crops.length} crops',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(height: 6),
//
//                     // Horizontal Crop Tiles - Auto-scrolling Carousel
//                     SizedBox(
//                       height: 100,
//                       child: Consumer<HomeController>(
//                         builder: (context, controller, _) {
//                           return GestureDetector(
//                             onPanDown: (_) => _onUserScroll(),
//                             child: PageView.builder(
//                               controller: _pageController,
//                               itemCount: 1000000, // Infinite scrolling
//                               physics: const BouncingScrollPhysics(),
//                               itemBuilder: (context, index) {
//                                 final cropIndex =
//                                     index % controller.crops.length;
//                                 final crop = controller.crops[cropIndex];
//                                 final isSelected =
//                                     controller.selectedCrop?.id == crop.id;
//                                 return Padding(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 8,
//                                   ),
//                                   child: CropTile(
//                                     crop: crop,
//                                     isSelected: isSelected,
//                                     onTap: () {
//                                       controller.selectCrop(crop);
//                                       _onUserScroll();
//                                     },
//                                   ),
//                                 );
//                               },
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//
//                     const SizedBox(height: 24),
//
//                     // Annual Growth Timeline
//                     if (controller.selectedCrop != null)
//                       _buildCropGrowthTimeline(controller),
//
//                     const SizedBox(height: 24),
//
//                     // Calendar Section - Now shown via bottom sheet
//                     // Tap the calendar icon in the app bar to view the calendar
//                     /*
//                     if (controller.selectedCrop != null) ...[
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         child: TranslatedText(
//                           'Yearly Calendar - ${controller.selectedCrop!.name}',
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFF2D5016),
//                           ),
//                         ),
//                       ),
//
//                       const SizedBox(height: 8),
//
//                       // Legend
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceAround,
//                           children: [
//                             _buildLegendItem(
//                               SeasonSuitability.highCompatibility.color,
//                               SeasonSuitability.highCompatibility.label,
//                             ),
//                             _buildLegendItem(
//                               SeasonSuitability.normal.color,
//                               SeasonSuitability.normal.label,
//                             ),
//                             _buildLegendItem(
//                               SeasonSuitability.notRecommended.color,
//                               SeasonSuitability.notRecommended.label,
//                             ),
//                           ],
//                         ),
//                       ),
//
//                       const SizedBox(height: 12),
//
//                       // Calendar with 3-level navigation
//                       Container(
//                         margin: const EdgeInsets.symmetric(horizontal: 16),
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                             colors: [
//                               Color(0xFFE8F5E9), // Light mint green
//                               Color(0xFFF1F8E9), // Light lime
//                               Color(0xFFFFF9E6), // Soft cream
//                             ],
//                           ),
//                           borderRadius: BorderRadius.circular(28),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Color(0xFF4CAF50).withOpacity(0.15),
//                               blurRadius: 20,
//                               offset: const Offset(0, 8),
//                               spreadRadius: 2,
//                             ),
//                             BoxShadow(
//                               color: Colors.white.withOpacity(0.8),
//                               blurRadius: 8,
//                               offset: const Offset(-4, -4),
//                             ),
//                           ],
//                           border: Border.all(
//                             color: Color(0xFFC8E6C9).withOpacity(0.5),
//                             width: 1.5,
//                           ),
//                         ),
//                         child: _buildCalendarView(controller),
//                       ),
//
//                       const SizedBox(height: 12),
//                     ],
//                     */
//
//                     // Month Tasks Preview
//                     if (controller.selectedCrop != null &&
//                         controller
//                             .getWeeklyTasksForMonth(_focusedDay.month)
//                             .isNotEmpty)
//                       Container(
//                         margin: const EdgeInsets.symmetric(horizontal: 16),
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(16),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.08),
//                               blurRadius: 12,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 TranslatedText(
//                                   'Tasks for ${_getMonthName(_focusedDay.month)}',
//                                   style: const TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                     color: Color(0xFF2D5016),
//                                   ),
//                                 ),
//                                 TextButton(
//                                   onPressed: () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) =>
//                                             ChangeNotifierProvider.value(
//                                               value: _homeController,
//                                               child: MonthDetailScreen(
//                                                 month: _focusedDay.month,
//                                               ),
//                                             ),
//                                       ),
//                                     );
//                                   },
//                                   child: const TranslatedText('View All'),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 8),
//                             TranslatedText(
//                               '${controller.getWeeklyTasksForMonth(_focusedDay.month).length} weeks planned',
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//
//                     const SizedBox(height: 24),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLegendItem(Color color, String label) {
//     return Row(
//       children: [
//         Container(
//           width: 16,
//           height: 16,
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.3),
//             border: Border.all(color: color, width: 2),
//             borderRadius: BorderRadius.circular(4),
//           ),
//         ),
//         const SizedBox(width: 6),
//         TranslatedText(
//           label,
//           style: const TextStyle(fontSize: 12, color: Color(0xFF2D5016)),
//         ),
//       ],
//     );
//   }
//
//   String _getMonthName(int month) {
//     const months = [
//       'January',
//       'February',
//       'March',
//       'April',
//       'May',
//       'June',
//       'July',
//       'August',
//       'September',
//       'October',
//       'November',
//       'December',
//     ];
//     return months[month - 1];
//   }
//
//   Widget _buildCropGrowthTimeline(HomeController controller) {
//     final months = [
//       {'name': 'January', 'abbr': 'Jan', 'number': 1},
//       {'name': 'February', 'abbr': 'Feb', 'number': 2},
//       {'name': 'March', 'abbr': 'Mar', 'number': 3},
//       {'name': 'April', 'abbr': 'Apr', 'number': 4},
//       {'name': 'May', 'abbr': 'May', 'number': 5},
//       {'name': 'June', 'abbr': 'Jun', 'number': 6},
//       {'name': 'July', 'abbr': 'Jul', 'number': 7},
//       {'name': 'August', 'abbr': 'Aug', 'number': 8},
//       {'name': 'September', 'abbr': 'Sep', 'number': 9},
//       {'name': 'October', 'abbr': 'Oct', 'number': 10},
//       {'name': 'November', 'abbr': 'Nov', 'number': 11},
//       {'name': 'December', 'abbr': 'Dec', 'number': 12},
//     ];
//
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 Icons.timeline,
//                 color:
//                     controller.selectedCrop?.themeColor ??
//                     const Color(0xFF4CAF50),
//                 size: 28,
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     TranslatedText(
//                       'Annual Growth Timeline',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color:
//                             controller.selectedCrop?.themeColor ??
//                             const Color(0xFF2D5016),
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     TranslatedText(
//                       'Crop suitability by month',
//                       style: TextStyle(fontSize: 13, color: Colors.grey[600]),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 24),
//           SizedBox(
//             height: 480,
//             child: Timeline.tileBuilder(
//               theme: TimelineThemeData(
//                 nodePosition: 0,
//                 color: Colors.grey[300]!,
//                 indicatorTheme: const IndicatorThemeData(size: 24),
//                 connectorTheme: ConnectorThemeData(
//                   thickness: 3,
//                   color: Colors.grey[300]!,
//                 ),
//               ),
//               padding: const EdgeInsets.symmetric(vertical: 8),
//               builder: TimelineTileBuilder.connected(
//                 itemCount: 12,
//                 connectionDirection: ConnectionDirection.before,
//                 contentsAlign: ContentsAlign.basic,
//                 contentsBuilder: (context, index) {
//                   final month = months[index];
//                   final monthNum = month['number'] as int;
//                   final suitability = controller.getSuitabilityForMonth(
//                     monthNum,
//                   );
//
//                   return Padding(
//                     padding: const EdgeInsets.only(left: 16, bottom: 20),
//                     child: Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color:
//                             suitability?.color.withOpacity(0.15) ??
//                             Colors.grey[100],
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                           color: suitability?.color ?? Colors.grey[300]!,
//                           width: 2,
//                         ),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     TranslatedText(
//                                       month['name'] as String,
//                                       style: TextStyle(
//                                         fontSize: 15,
//                                         fontWeight: FontWeight.bold,
//                                         color:
//                                             suitability?.color ??
//                                             Colors.grey[800],
//                                       ),
//                                     ),
//                                     const SizedBox(height: 4),
//                                     TranslatedText(
//                                       _getBestCropForMonth(
//                                         monthNum,
//                                         controller,
//                                       ),
//                                       style: TextStyle(
//                                         fontSize: 13,
//                                         fontWeight: FontWeight.w600,
//                                         color: Colors.grey[700],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                           if (suitability != null) ...[
//                             const SizedBox(height: 12),
//                             // Day-by-day breakdown
//                             ..._getDailyActivities(
//                                   monthNum,
//                                   suitability,
//                                   month['name'] as String,
//                                   controller,
//                                 )
//                                 .map(
//                                   (activity) => Padding(
//                                     padding: const EdgeInsets.only(bottom: 6),
//                                     child: Row(
//                                       children: [
//                                         Container(
//                                           width: 4,
//                                           height: 4,
//                                           decoration: BoxDecoration(
//                                             color: suitability.color,
//                                             shape: BoxShape.circle,
//                                           ),
//                                         ),
//                                         const SizedBox(width: 8),
//                                         Expanded(
//                                           child: TranslatedText(
//                                             activity,
//                                             style: TextStyle(
//                                               fontSize: 11,
//                                               color: Colors.grey[700],
//                                               height: 1.3,
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 )
//                                 .toList(),
//                           ],
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//                 indicatorBuilder: (context, index) {
//                   final month = months[index];
//                   final monthNum = month['number'] as int;
//                   final suitability = controller.getSuitabilityForMonth(
//                     monthNum,
//                   );
//                   final isCurrentMonth = monthNum == DateTime.now().month;
//
//                   return DotIndicator(
//                     size: isCurrentMonth ? 28 : 24,
//                     color: suitability?.color ?? Colors.grey[400]!,
//                     border: isCurrentMonth
//                         ? Border.all(color: Colors.black87, width: 3)
//                         : null,
//                     child: isCurrentMonth
//                         ? const Icon(Icons.check, color: Colors.white, size: 16)
//                         : null,
//                   );
//                 },
//                 connectorBuilder: (context, index, connectorType) {
//                   final month = months[index];
//                   final monthNum = month['number'] as int;
//                   final suitability = controller.getSuitabilityForMonth(
//                     monthNum,
//                   );
//
//                   return SolidLineConnector(
//                     color: suitability?.color ?? Colors.grey[300]!,
//                     thickness: 3,
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   List<String> _getDailyActivities(
//     int monthNum,
//     SeasonSuitability suitability,
//     String monthName,
//     HomeController controller,
//   ) {
//     final daysInMonth = DateTime(DateTime.now().year, monthNum + 1, 0).day;
//     final cropName = controller.selectedCrop?.name ?? 'crop';
//
//     if (suitability == SeasonSuitability.notRecommended) {
//       return [
//         '📅 Day 1-$daysInMonth: Not recommended for $cropName',
//         '⚠️ Consider alternative crops or wait',
//       ];
//     }
//
//     if (suitability == SeasonSuitability.highCompatibility) {
//       return [
//         '📅 Day 1-7: Land preparation for $cropName',
//         '📅 Day 8-15: $cropName planting & sowing',
//         '📅 Day 16-${(daysInMonth * 0.6).round()}: $cropName growth monitoring',
//         '📅 Day ${(daysInMonth * 0.6).round() + 1}-$daysInMonth: $cropName care & pest control',
//       ];
//     } else {
//       return [
//         '📅 Day 1-10: Field preparation for $cropName',
//         '📅 Day 11-20: $cropName planting with care',
//         '📅 Day 21-$daysInMonth: $cropName maintenance',
//       ];
//     }
//   }
//
//   String _getCropActivityForMonth(
//     int monthNum,
//     SeasonSuitability? suitability,
//   ) {
//     if (suitability == null) return 'No data available';
//
//     switch (suitability) {
//       case SeasonSuitability.highCompatibility:
//         if (monthNum >= 3 && monthNum <= 5) {
//           return '🌱 Active Growth Phase';
//         } else if (monthNum >= 6 && monthNum <= 8) {
//           return '🌿 Peak Growth Phase';
//         } else if (monthNum >= 9 && monthNum <= 11) {
//           return '🌾 Flowering & Maturation';
//         } else {
//           return '📦 Harvest Period';
//         }
//       case SeasonSuitability.normal:
//         return '🌿 Vegetative Stage';
//       case SeasonSuitability.notRecommended:
//         return '🚫 Field Preparation';
//     }
//   }
//
//   String _getBestCropForMonth(int monthNum, HomeController controller) {
//     // Get all available crops
//     final crops = controller.crops;
//
//     if (crops.isEmpty) {
//       return controller.selectedCrop?.name ?? 'Crop';
//     }
//
//     // Find the crop with highest suitability for this month
//     Crop? bestCrop;
//     SeasonSuitability? bestSuitability;
//
//     for (final crop in crops) {
//       final suitability = crop.monthSuitability[monthNum];
//
//       if (suitability != null) {
//         if (bestSuitability == null ||
//             _isBetterSuitability(suitability, bestSuitability)) {
//           bestCrop = crop;
//           bestSuitability = suitability;
//         }
//       }
//     }
//
//     return bestCrop?.name ?? controller.selectedCrop?.name ?? 'Crop';
//   }
//
//   SeasonSuitability? _getSuitabilityForCrop(Crop crop, int month) {
//     return crop.monthSuitability[month];
//   }
//
//   bool _isBetterSuitability(SeasonSuitability a, SeasonSuitability b) {
//     const priority = {
//       SeasonSuitability.highCompatibility: 3,
//       SeasonSuitability.normal: 2,
//       SeasonSuitability.notRecommended: 1,
//     };
//
//     return (priority[a] ?? 0) > (priority[b] ?? 0);
//   }
//
//   void _showAlertsDialog(BuildContext context, HomeController controller) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             Icon(
//               Icons.warning_amber_rounded,
//               color: _getHighestSeverityColor(controller.alerts),
//               size: 28,
//             ),
//             const SizedBox(width: 12),
//             const TranslatedText(
//               'Weather Alerts',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: ListView.separated(
//             shrinkWrap: true,
//             itemCount: controller.alerts.length,
//             separatorBuilder: (context, index) => const SizedBox(height: 12),
//             itemBuilder: (context, index) {
//               final alert = controller.alerts[index];
//               return _buildAlertItem(alert);
//             },
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const TranslatedText(
//               'Close',
//               style: TextStyle(
//                 color: Color(0xFF2D5016),
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAlertItem(WeatherAlert alert) {
//     final color = _getSeverityColor(alert.severity);
//     final icon = _getSeverityIcon(alert.severity);
//
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.3), width: 1.5),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, color: color, size: 20),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: TranslatedText(
//                   alert.title,
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: color,
//                   ),
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: color,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: TranslatedText(
//                   _getSeverityLabel(alert.severity),
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 11,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           TranslatedText(
//             alert.message,
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[800],
//               height: 1.4,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Color _getSeverityColor(AlertSeverity severity) {
//     switch (severity) {
//       case AlertSeverity.critical:
//         return const Color(0xFFD32F2F);
//       case AlertSeverity.high:
//         return const Color(0xFFE74C3C);
//       case AlertSeverity.medium:
//         return const Color(0xFFF39C12);
//       case AlertSeverity.low:
//         return const Color(0xFF3498DB);
//     }
//   }
//
//   Color _getHighestSeverityColor(List<WeatherAlert> alerts) {
//     if (alerts.any((a) => a.severity == AlertSeverity.critical)) {
//       return const Color(0xFFD32F2F);
//     } else if (alerts.any((a) => a.severity == AlertSeverity.high)) {
//       return const Color(0xFFE74C3C);
//     } else if (alerts.any((a) => a.severity == AlertSeverity.medium)) {
//       return const Color(0xFFF39C12);
//     } else {
//       return const Color(0xFF3498DB);
//     }
//   }
//
//   IconData _getSeverityIcon(AlertSeverity severity) {
//     switch (severity) {
//       case AlertSeverity.critical:
//         return Icons.error;
//       case AlertSeverity.high:
//         return Icons.warning_amber_rounded;
//       case AlertSeverity.medium:
//         return Icons.info_outline;
//       case AlertSeverity.low:
//         return Icons.info;
//     }
//   }
//
//   String _getSeverityLabel(AlertSeverity severity) {
//     switch (severity) {
//       case AlertSeverity.critical:
//         return 'CRITICAL';
//       case AlertSeverity.high:
//         return 'HIGH';
//       case AlertSeverity.medium:
//         return 'MEDIUM';
//       case AlertSeverity.low:
//         return 'LOW';
//     }
//   }
//
//   // Build calendar view based on current navigation level
//   Widget _buildCalendarView(HomeController controller) {
//     switch (_calendarView) {
//       case 'year':
//         return _buildYearSelectionView(controller);
//       case 'month':
//         return _buildMonthSelectionView(controller);
//       case 'date':
//       default:
//         return _buildDateCalendarView(controller);
//     }
//   }
//
//   // Year Selection View - Grid of years
//   Widget _buildYearSelectionView(HomeController controller) {
//     final currentYear = DateTime.now().year;
//     final startYear = 2000 + (_yearPageIndex * 16);
//     final years = List.generate(16, (index) => startYear + index);
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Header with navigation arrows
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               IconButton(
//                 icon: Icon(Icons.chevron_left, size: 28),
//                 onPressed: _yearPageIndex > 0
//                     ? () {
//                         setState(() {
//                           _yearPageIndex--;
//                         });
//                       }
//                     : null,
//                 color:
//                     controller.selectedCrop?.themeColor ??
//                     const Color(0xFF2D5016),
//               ),
//               const SizedBox(width: 16),
//               Text(
//                 '${years.first} - ${years.last}',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color:
//                       controller.selectedCrop?.themeColor ??
//                       const Color(0xFF2D5016),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               IconButton(
//                 icon: Icon(Icons.chevron_right, size: 28),
//                 onPressed: () {
//                   setState(() {
//                     _yearPageIndex++;
//                   });
//                 },
//                 color:
//                     controller.selectedCrop?.themeColor ??
//                     const Color(0xFF2D5016),
//               ),
//             ],
//           ),
//           const SizedBox(height: 24),
//           // Year Grid - 4 rows x 4 columns = 16 years per page
//           GridView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 4,
//               crossAxisSpacing: 12,
//               mainAxisSpacing: 12,
//               childAspectRatio: 2.2,
//             ),
//             itemCount: 16,
//             itemBuilder: (context, index) {
//               final year = years[index];
//               final isSelected = year == _selectedYear;
//               final isCurrent = year == currentYear;
//
//               return GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     _selectedYear = year;
//                     _calendarView = 'month';
//                   });
//                 },
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: isSelected
//                         ? controller.selectedCrop?.themeColor ??
//                               const Color(0xFF64B5F6)
//                         : isCurrent
//                         ? (controller.selectedCrop?.themeColor ??
//                                   const Color(0xFF90CAF9))
//                               .withOpacity(0.3)
//                         : const Color(0xFFFFF3E0),
//                     borderRadius: BorderRadius.circular(24),
//                   ),
//                   child: Center(
//                     child: Text(
//                       '$year',
//                       style: TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w500,
//                         color: isSelected ? Colors.white : Colors.black87,
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//           const SizedBox(height: 24),
//           // Today button
//           TextButton(
//             onPressed: () {
//               setState(() {
//                 _calendarView = 'date';
//                 _selectedYear = currentYear;
//                 _selectedMonth = DateTime.now().month;
//                 _focusedDay = DateTime.now();
//                 _yearPageIndex = (currentYear - 2000) ~/ 16;
//               });
//             },
//             style: TextButton.styleFrom(
//               foregroundColor: const Color(0xFF4CAF50),
//             ),
//             child: const TranslatedText('Go to Today'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Month Selection View - Grid of months
//   Widget _buildMonthSelectionView(HomeController controller) {
//     final months = [
//       'January',
//       'February',
//       'March',
//       'April',
//       'May',
//       'June',
//       'July',
//       'August',
//       'September',
//       'October',
//       'November',
//       'December',
//     ];
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Header
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               IconButton(
//                 icon: Icon(Icons.chevron_left, size: 28),
//                 onPressed: () {
//                   setState(() {
//                     _calendarView = 'year';
//                   });
//                 },
//                 color:
//                     controller.selectedCrop?.themeColor ??
//                     const Color(0xFF2D5016),
//               ),
//               const SizedBox(width: 16),
//               Text(
//                 '$_selectedYear',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color:
//                       controller.selectedCrop?.themeColor ??
//                       const Color(0xFF2D5016),
//                 ),
//               ),
//               const SizedBox(width: 60),
//             ],
//           ),
//           const SizedBox(height: 24),
//           // Month Grid
//           GridView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3,
//               crossAxisSpacing: 16,
//               mainAxisSpacing: 16,
//               childAspectRatio: 2.2,
//             ),
//             itemCount: 12,
//             itemBuilder: (context, index) {
//               final month = index + 1;
//               final monthName = months[index];
//               final isSelected = month == _selectedMonth;
//               final isCurrent =
//                   month == DateTime.now().month &&
//                   _selectedYear == DateTime.now().year;
//
//               // Get crop suitability for this month
//               final suitability = controller.getSuitabilityForMonth(month);
//               Color monthColor;
//
//               if (isSelected) {
//                 // Selected month uses crop theme color
//                 monthColor =
//                     controller.selectedCrop?.themeColor ??
//                     const Color(0xFF64B5F6);
//               } else if (suitability != null) {
//                 // Use suitability color (Peak/Moderate/Not Ideal)
//                 monthColor = suitability.color.withOpacity(
//                   isCurrent ? 0.9 : 0.7,
//                 );
//               } else {
//                 // Fallback color
//                 monthColor = const Color(0xFFFFF3E0);
//               }
//
//               return GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     _selectedMonth = month;
//                     _focusedDay = DateTime(_selectedYear, month, 1);
//                     _calendarView = 'date';
//                   });
//                 },
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: monthColor,
//                     borderRadius: BorderRadius.circular(24),
//                     border: isCurrent
//                         ? Border.all(color: Colors.black87, width: 2)
//                         : null,
//                   ),
//                   child: Center(
//                     child: TranslatedText(
//                       monthName,
//                       style: TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w500,
//                         color: isSelected ? Colors.white : Colors.black87,
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Date Calendar View - Normal calendar with dates
//   Widget _buildDateCalendarView(HomeController controller) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Header
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               IconButton(
//                 icon: Icon(Icons.chevron_left, size: 28),
//                 onPressed: () {
//                   setState(() {
//                     _focusedDay = DateTime(
//                       _focusedDay.year,
//                       _focusedDay.month - 1,
//                       1,
//                     );
//                     _selectedMonth = _focusedDay.month;
//                     _selectedYear = _focusedDay.year;
//                   });
//                 },
//                 color: Color(0xFF2D5016),
//               ),
//               const SizedBox(width: 16),
//               GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     _calendarView = 'month';
//                   });
//                 },
//                 child: TranslatedText(
//                   '${_getMonthName(_focusedDay.month)} ${_focusedDay.year}',
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF2D5016),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               IconButton(
//                 icon: Icon(Icons.chevron_right, size: 28),
//                 onPressed: () {
//                   setState(() {
//                     _focusedDay = DateTime(
//                       _focusedDay.year,
//                       _focusedDay.month + 1,
//                       1,
//                     );
//                     _selectedMonth = _focusedDay.month;
//                     _selectedYear = _focusedDay.year;
//                   });
//                 },
//                 color: Color(0xFF2D5016),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           TableCalendar(
//             firstDay: DateTime(_selectedYear, 1, 1),
//             lastDay: DateTime(_selectedYear, 12, 31),
//             focusedDay: _focusedDay,
//             selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//             calendarFormat: CalendarFormat.month,
//             startingDayOfWeek: StartingDayOfWeek.monday,
//             headerVisible: false,
//             daysOfWeekHeight: 40,
//             daysOfWeekStyle: const DaysOfWeekStyle(
//               weekdayStyle: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//               ),
//               weekendStyle: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             calendarBuilders: CalendarBuilders(
//               dowBuilder: (context, day) {
//                 final dayNames = {
//                   DateTime.monday: 'Mon',
//                   DateTime.tuesday: 'Tue',
//                   DateTime.wednesday: 'Wed',
//                   DateTime.thursday: 'Thu',
//                   DateTime.friday: 'Fri',
//                   DateTime.saturday: 'Sat',
//                   DateTime.sunday: 'Sun',
//                 };
//                 return Center(
//                   child: TranslatedText(
//                     dayNames[day.weekday] ?? '',
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500,
//                       color:
//                           day.weekday == DateTime.saturday ||
//                               day.weekday == DateTime.sunday
//                           ? const Color(0xFFE57373)
//                           : const Color(0xFF2D5016),
//                     ),
//                   ),
//                 );
//               },
//               defaultBuilder: (context, day, focusedDay) {
//                 // Get suitability for the current month
//                 final suitability = controller.getSuitabilityForMonth(
//                   day.month,
//                 );
//                 Color backgroundColor = Colors.white.withOpacity(0.5);
//
//                 if (suitability != null) {
//                   // Use season color with lower opacity for better readability
//                   backgroundColor = suitability.color.withOpacity(0.3);
//                 }
//
//                 return Container(
//                   margin: const EdgeInsets.all(3),
//                   decoration: BoxDecoration(
//                     color: backgroundColor,
//                     shape: BoxShape.circle,
//                   ),
//                   child: Center(
//                     child: Text(
//                       '${day.day}',
//                       style: const TextStyle(
//                         color: Color(0xFF2D5016),
//                         fontWeight: FontWeight.w500,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),
//                 );
//               },
//               todayBuilder: (context, day, focusedDay) {
//                 return Container(
//                   margin: const EdgeInsets.all(3),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         Color(0xFFA5D6A7).withOpacity(0.5),
//                         Color(0xFF81C784).withOpacity(0.5),
//                       ],
//                     ),
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Color(0xFF66BB6A), width: 2),
//                   ),
//                   child: Center(
//                     child: Text(
//                       '${day.day}',
//                       style: const TextStyle(
//                         color: Color(0xFF2D5016),
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//             calendarStyle: CalendarStyle(
//               todayDecoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     Color(0xFF81C784).withOpacity(0.6),
//                     Color(0xFF66BB6A).withOpacity(0.6),
//                   ],
//                 ),
//                 shape: BoxShape.circle,
//               ),
//               selectedDecoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
//                 ),
//                 shape: BoxShape.circle,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Color(0xFF4CAF50).withOpacity(0.4),
//                     blurRadius: 8,
//                     spreadRadius: 1,
//                   ),
//                 ],
//               ),
//               weekendTextStyle: const TextStyle(
//                 color: Color(0xFFE57373),
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             onDaySelected: (selectedDay, focusedDay) async {
//               setState(() {
//                 _selectedDay = selectedDay;
//                 _focusedDay = focusedDay;
//               });
//               controller.selectDate(selectedDay);
//
//               // Get farm data for ML API
//               final farmDataController = FarmDataController();
//               final farmData = await farmDataController.getFarmData();
//
//               if (farmData == null) {
//                 if (!mounted) return;
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: TranslatedText(
//                       'Please complete your farm profile first',
//                     ),
//                     backgroundColor: Colors.orange,
//                   ),
//                 );
//                 return;
//               }
//
//               // Prepare data for ML API
//               final apiData = MLApiService.prepareFarmDataForAPI(
//                 farmBasics: farmData.farmBasics.toJson(),
//                 soilQuality: farmData.soilQuality.toJson(),
//                 climateData: farmData.climateData?.toJson() ?? {},
//                 plantingDate: DateTime.now()
//                     .subtract(const Duration(days: 30))
//                     .toIso8601String()
//                     .split('T')[0],
//               );
//
//               // Navigate to ML-powered daily actions
//               if (!mounted) return;
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => DailyActionsScreen(
//                     selectedDate: selectedDay,
//                     farmData: apiData,
//                   ),
//                 ),
//               );
//             },
//             onPageChanged: (focusedDay) {
//               setState(() {
//                 _focusedDay = focusedDay;
//                 _selectedMonth = focusedDay.month;
//                 _selectedYear = focusedDay.year;
//               });
//               controller.selectMonth(focusedDay.month);
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   // DEPRECATED: Now using full screen calendar
//   // Show calendar in a bottom sheet
//   /* void _showCalendarBottomSheet(BuildContext context) {
//     final controller = _homeController; // Use the instance variable directly
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (bottomSheetContext) {
//         if (controller.selectedCrop == null) {
//           return Container(
//             height: MediaQuery.of(context).size.height * 0.3,
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//             ),
//             child: Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.crop, size: 48, color: Colors.grey[400]),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Please select a crop first',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.grey[600],
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }
//
//         return ChangeNotifierProvider.value(
//           value: controller,
//           child: Consumer<HomeController>(
//             builder: (context, controller, _) {
//               return DraggableScrollableSheet(
//                 initialChildSize: 0.9,
//                 minChildSize: 0.5,
//                 maxChildSize: 0.95,
//                 builder: (context, scrollController) {
//                   return Container(
//                     decoration: const BoxDecoration(
//                       color: Color(0xFFF8F6F0),
//                       borderRadius: BorderRadius.vertical(
//                         top: Radius.circular(20),
//                       ),
//                     ),
//                     child: Column(
//                       children: [
//                         // Handle bar
//                         Container(
//                           margin: const EdgeInsets.only(top: 12),
//                           width: 40,
//                           height: 4,
//                           decoration: BoxDecoration(
//                             color: Colors.grey[300],
//                             borderRadius: BorderRadius.circular(2),
//                           ),
//                         ),
//                         // Header
//                         Padding(
//                           padding: const EdgeInsets.all(16),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 'Yearly Calendar - ${controller.selectedCrop!.name}',
//                                 style: const TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.w600,
//                                   color: Color(0xFF2D5016),
//                                 ),
//                               ),
//                               IconButton(
//                                 icon: const Icon(Icons.close),
//                                 onPressed: () => Navigator.pop(context),
//                               ),
//                             ],
//                           ),
//                         ),
//                         // Legend
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 16),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceAround,
//                             children: [
//                               _buildLegendItem(
//                                 SeasonSuitability.highCompatibility.color,
//                                 SeasonSuitability.highCompatibility.label,
//                               ),
//                               _buildLegendItem(
//                                 SeasonSuitability.normal.color,
//                                 SeasonSuitability.normal.label,
//                               ),
//                               _buildLegendItem(
//                                 SeasonSuitability.notRecommended.color,
//                                 SeasonSuitability.notRecommended.label,
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         // Calendar
//                         Expanded(
//                           child: SingleChildScrollView(
//                             controller: scrollController,
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                               ),
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   gradient: const LinearGradient(
//                                     begin: Alignment.topLeft,
//                                     end: Alignment.bottomRight,
//                                     colors: [
//                                       Color(0xFFE8F5E9),
//                                       Color(0xFFF1F8E9),
//                                       Color(0xFFFFF9E6),
//                                     ],
//                                   ),
//                                   borderRadius: BorderRadius.circular(28),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: const Color(
//                                         0xFF4CAF50,
//                                       ).withOpacity(0.15),
//                                       blurRadius: 20,
//                                       offset: const Offset(0, 8),
//                                       spreadRadius: 2,
//                                     ),
//                                   ],
//                                   border: Border.all(
//                                     color: const Color(
//                                       0xFFC8E6C9,
//                                     ).withOpacity(0.5),
//                                     width: 1.5,
//                                   ),
//                                 ),
//                                 child: _buildCalendarView(controller),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                       ],
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         );
//       },
//     );
//   } */
// }
//
// // Full screen calendar view
// class CalendarFullScreen extends StatefulWidget {
//   const CalendarFullScreen({super.key});
//
//   @override
//   State<CalendarFullScreen> createState() => _CalendarFullScreenState();
// }
//
// class _CalendarFullScreenState extends State<CalendarFullScreen> {
//   String _calendarView = 'year';
//   int _selectedYear = DateTime.now().year;
//   int _selectedMonth = DateTime.now().month;
//   DateTime _focusedDay = DateTime.now();
//   DateTime? _selectedDay;
//   int _yearPageIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _yearPageIndex = (DateTime.now().year - 2000) ~/ 16;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<HomeController>(
//       builder: (context, controller, _) {
//         return Scaffold(
//           backgroundColor: const Color(0xFFF8F6F0),
//           appBar: AppBar(
//             elevation: 0,
//             backgroundColor: const Color(0xFFF8F6F0),
//             surfaceTintColor: Colors.transparent,
//             leading: IconButton(
//               icon: const Icon(Icons.arrow_back, color: Color(0xFF2D5016)),
//               onPressed: () => Navigator.pop(context),
//             ),
//             title: Text(
//               controller.selectedCrop != null
//                   ? 'Yearly Calendar - ${controller.selectedCrop!.name}'
//                   : 'Yearly Calendar',
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF2D5016),
//               ),
//             ),
//             centerTitle: true,
//           ),
//           body: controller.selectedCrop == null
//               ? Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.crop, size: 64, color: Colors.grey[400]),
//                       const SizedBox(height: 24),
//                       Text(
//                         'Please select a crop first',
//                         style: TextStyle(
//                           fontSize: 18,
//                           color: Colors.grey[600],
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//               : SingleChildScrollView(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       children: [
//                         // Legend
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceAround,
//                           children: [
//                             _buildLegendItem(
//                               SeasonSuitability.highCompatibility.color,
//                               SeasonSuitability.highCompatibility.label,
//                             ),
//                             _buildLegendItem(
//                               SeasonSuitability.normal.color,
//                               SeasonSuitability.normal.label,
//                             ),
//                             _buildLegendItem(
//                               SeasonSuitability.notRecommended.color,
//                               SeasonSuitability.notRecommended.label,
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 24),
//                         // Calendar
//                         Container(
//                           decoration: BoxDecoration(
//                             gradient: const LinearGradient(
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                               colors: [
//                                 Color(0xFFE8F5E9),
//                                 Color(0xFFF1F8E9),
//                                 Color(0xFFFFF9E6),
//                               ],
//                             ),
//                             borderRadius: BorderRadius.circular(28),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: const Color(
//                                   0xFF4CAF50,
//                                 ).withOpacity(0.15),
//                                 blurRadius: 20,
//                                 offset: const Offset(0, 8),
//                                 spreadRadius: 2,
//                               ),
//                             ],
//                             border: Border.all(
//                               color: const Color(0xFFC8E6C9).withOpacity(0.5),
//                               width: 1.5,
//                             ),
//                           ),
//                           child: _buildCalendarView(controller),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//         );
//       },
//     );
//   }
//
//   Widget _buildLegendItem(Color color, String label) {
//     return Row(
//       children: [
//         Container(
//           width: 16,
//           height: 16,
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.3),
//             border: Border.all(color: color, width: 2),
//             borderRadius: BorderRadius.circular(4),
//           ),
//         ),
//         const SizedBox(width: 6),
//         TranslatedText(
//           label,
//           style: const TextStyle(fontSize: 12, color: Color(0xFF2D5016)),
//         ),
//       ],
//     );
//   }
//
//   String _getMonthName(int month) {
//     const months = [
//       'January',
//       'February',
//       'March',
//       'April',
//       'May',
//       'June',
//       'July',
//       'August',
//       'September',
//       'October',
//       'November',
//       'December',
//     ];
//     return months[month - 1];
//   }
//
//   Widget _buildCalendarView(HomeController controller) {
//     switch (_calendarView) {
//       case 'year':
//         return _buildYearSelectionView(controller);
//       case 'month':
//         return _buildMonthSelectionView(controller);
//       case 'date':
//       default:
//         return _buildDateCalendarView(controller);
//     }
//   }
//
//   Widget _buildYearSelectionView(HomeController controller) {
//     final currentYear = DateTime.now().year;
//     final startYear = 2000 + (_yearPageIndex * 16);
//     final years = List.generate(16, (index) => startYear + index);
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.chevron_left, size: 28),
//                 onPressed: _yearPageIndex > 0
//                     ? () {
//                         setState(() {
//                           _yearPageIndex--;
//                         });
//                       }
//                     : null,
//                 color:
//                     controller.selectedCrop?.themeColor ??
//                     const Color(0xFF2D5016),
//               ),
//               const SizedBox(width: 16),
//               Text(
//                 '${years.first} - ${years.last}',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color:
//                       controller.selectedCrop?.themeColor ??
//                       const Color(0xFF2D5016),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               IconButton(
//                 icon: const Icon(Icons.chevron_right, size: 28),
//                 onPressed: () {
//                   setState(() {
//                     _yearPageIndex++;
//                   });
//                 },
//                 color:
//                     controller.selectedCrop?.themeColor ??
//                     const Color(0xFF2D5016),
//               ),
//             ],
//           ),
//           const SizedBox(height: 24),
//           GridView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 4,
//               crossAxisSpacing: 12,
//               mainAxisSpacing: 12,
//               childAspectRatio: 2.2,
//             ),
//             itemCount: 16,
//             itemBuilder: (context, index) {
//               final year = years[index];
//               final isSelected = year == _selectedYear;
//               final isCurrent = year == currentYear;
//
//               return GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     _selectedYear = year;
//                     _calendarView = 'month';
//                   });
//                 },
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: isSelected
//                         ? controller.selectedCrop?.themeColor ??
//                               const Color(0xFF64B5F6)
//                         : isCurrent
//                         ? (controller.selectedCrop?.themeColor ??
//                                   const Color(0xFF90CAF9))
//                               .withOpacity(0.3)
//                         : const Color(0xFFFFF3E0),
//                     borderRadius: BorderRadius.circular(24),
//                   ),
//                   child: Center(
//                     child: Text(
//                       '$year',
//                       style: TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w500,
//                         color: isSelected ? Colors.white : Colors.black87,
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//           const SizedBox(height: 24),
//           TextButton(
//             onPressed: () {
//               setState(() {
//                 _calendarView = 'date';
//                 _selectedYear = currentYear;
//                 _selectedMonth = DateTime.now().month;
//                 _focusedDay = DateTime.now();
//                 _yearPageIndex = (currentYear - 2000) ~/ 16;
//               });
//             },
//             style: TextButton.styleFrom(
//               foregroundColor: const Color(0xFF4CAF50),
//             ),
//             child: const TranslatedText('Go to Today'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMonthSelectionView(HomeController controller) {
//     final months = [
//       'January',
//       'February',
//       'March',
//       'April',
//       'May',
//       'June',
//       'July',
//       'August',
//       'September',
//       'October',
//       'November',
//       'December',
//     ];
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.chevron_left, size: 28),
//                 onPressed: () {
//                   setState(() {
//                     _calendarView = 'year';
//                   });
//                 },
//                 color:
//                     controller.selectedCrop?.themeColor ??
//                     const Color(0xFF2D5016),
//               ),
//               const SizedBox(width: 16),
//               Text(
//                 '$_selectedYear',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color:
//                       controller.selectedCrop?.themeColor ??
//                       const Color(0xFF2D5016),
//                 ),
//               ),
//               const SizedBox(width: 60),
//             ],
//           ),
//           const SizedBox(height: 24),
//           GridView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3,
//               crossAxisSpacing: 16,
//               mainAxisSpacing: 16,
//               childAspectRatio: 2.2,
//             ),
//             itemCount: 12,
//             itemBuilder: (context, index) {
//               final month = index + 1;
//               final monthName = months[index];
//               final isSelected = month == _selectedMonth;
//               final isCurrent =
//                   month == DateTime.now().month &&
//                   _selectedYear == DateTime.now().year;
//
//               final suitability = controller.getSuitabilityForMonth(month);
//               Color monthColor;
//
//               if (isSelected) {
//                 monthColor =
//                     controller.selectedCrop?.themeColor ??
//                     const Color(0xFF64B5F6);
//               } else if (suitability != null) {
//                 monthColor = suitability.color.withOpacity(
//                   isCurrent ? 0.9 : 0.7,
//                 );
//               } else {
//                 monthColor = const Color(0xFFFFF3E0);
//               }
//
//               return GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     _selectedMonth = month;
//                     _focusedDay = DateTime(_selectedYear, month, 1);
//                     _calendarView = 'date';
//                   });
//                 },
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: monthColor,
//                     borderRadius: BorderRadius.circular(24),
//                     border: isCurrent
//                         ? Border.all(color: Colors.black87, width: 2)
//                         : null,
//                   ),
//                   child: Center(
//                     child: TranslatedText(
//                       monthName,
//                       style: TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w500,
//                         color: isSelected ? Colors.white : Colors.black87,
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDateCalendarView(HomeController controller) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.chevron_left, size: 28),
//                 onPressed: () {
//                   setState(() {
//                     _focusedDay = DateTime(
//                       _focusedDay.year,
//                       _focusedDay.month - 1,
//                       1,
//                     );
//                     _selectedMonth = _focusedDay.month;
//                     _selectedYear = _focusedDay.year;
//                   });
//                 },
//                 color: const Color(0xFF2D5016),
//               ),
//               const SizedBox(width: 16),
//               GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     _calendarView = 'month';
//                   });
//                 },
//                 child: TranslatedText(
//                   '${_getMonthName(_focusedDay.month)} ${_focusedDay.year}',
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF2D5016),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               IconButton(
//                 icon: const Icon(Icons.chevron_right, size: 28),
//                 onPressed: () {
//                   setState(() {
//                     _focusedDay = DateTime(
//                       _focusedDay.year,
//                       _focusedDay.month + 1,
//                       1,
//                     );
//                     _selectedMonth = _focusedDay.month;
//                     _selectedYear = _focusedDay.year;
//                   });
//                 },
//                 color: const Color(0xFF2D5016),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           TableCalendar(
//             firstDay: DateTime(_selectedYear, 1, 1),
//             lastDay: DateTime(_selectedYear, 12, 31),
//             focusedDay: _focusedDay,
//             selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//             calendarFormat: CalendarFormat.month,
//             startingDayOfWeek: StartingDayOfWeek.monday,
//             headerVisible: false,
//             daysOfWeekHeight: 40,
//             daysOfWeekStyle: const DaysOfWeekStyle(
//               weekdayStyle: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//               ),
//               weekendStyle: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             calendarBuilders: CalendarBuilders(
//               dowBuilder: (context, day) {
//                 final dayNames = {
//                   DateTime.monday: 'Mon',
//                   DateTime.tuesday: 'Tue',
//                   DateTime.wednesday: 'Wed',
//                   DateTime.thursday: 'Thu',
//                   DateTime.friday: 'Fri',
//                   DateTime.saturday: 'Sat',
//                   DateTime.sunday: 'Sun',
//                 };
//                 return Center(
//                   child: TranslatedText(
//                     dayNames[day.weekday] ?? '',
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500,
//                       color:
//                           day.weekday == DateTime.saturday ||
//                               day.weekday == DateTime.sunday
//                           ? const Color(0xFFE57373)
//                           : const Color(0xFF2D5016),
//                     ),
//                   ),
//                 );
//               },
//               defaultBuilder: (context, day, focusedDay) {
//                 final suitability = controller.getSuitabilityForMonth(
//                   day.month,
//                 );
//                 Color backgroundColor = Colors.white.withOpacity(0.5);
//
//                 if (suitability != null) {
//                   backgroundColor = suitability.color.withOpacity(0.3);
//                 }
//
//                 return Container(
//                   margin: const EdgeInsets.all(3),
//                   decoration: BoxDecoration(
//                     color: backgroundColor,
//                     shape: BoxShape.circle,
//                   ),
//                   child: Center(
//                     child: Text(
//                       '${day.day}',
//                       style: const TextStyle(
//                         color: Color(0xFF2D5016),
//                         fontWeight: FontWeight.w500,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),
//                 );
//               },
//               todayBuilder: (context, day, focusedDay) {
//                 return Container(
//                   margin: const EdgeInsets.all(3),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         const Color(0xFFA5D6A7).withOpacity(0.5),
//                         const Color(0xFF81C784).withOpacity(0.5),
//                       ],
//                     ),
//                     shape: BoxShape.circle,
//                     border: Border.all(
//                       color: const Color(0xFF66BB6A),
//                       width: 2,
//                     ),
//                   ),
//                   child: Center(
//                     child: Text(
//                       '${day.day}',
//                       style: const TextStyle(
//                         color: Color(0xFF2D5016),
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//             calendarStyle: CalendarStyle(
//               todayDecoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     const Color(0xFF81C784).withOpacity(0.6),
//                     const Color(0xFF66BB6A).withOpacity(0.6),
//                   ],
//                 ),
//                 shape: BoxShape.circle,
//               ),
//               selectedDecoration: BoxDecoration(
//                 gradient: const LinearGradient(
//                   colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
//                 ),
//                 shape: BoxShape.circle,
//                 boxShadow: [
//                   BoxShadow(
//                     color: const Color(0xFF4CAF50).withOpacity(0.4),
//                     blurRadius: 8,
//                     spreadRadius: 1,
//                   ),
//                 ],
//               ),
//               weekendTextStyle: const TextStyle(
//                 color: Color(0xFFE57373),
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             onDaySelected: (selectedDay, focusedDay) async {
//               setState(() {
//                 _selectedDay = selectedDay;
//                 _focusedDay = focusedDay;
//               });
//               controller.selectDate(selectedDay);
//
//               final farmDataController = FarmDataController();
//               final farmData = await farmDataController.getFarmData();
//
//               if (farmData == null) {
//                 if (!mounted) return;
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: TranslatedText(
//                       'Please complete your farm profile first',
//                     ),
//                     backgroundColor: Colors.orange,
//                   ),
//                 );
//                 return;
//               }
//
//               if (!mounted) return;
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => DailyActionsScreen(
//                     selectedDate: selectedDay,
//                     farmData: farmData.toJson(),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _getCropActivityForMonth(int month, SeasonSuitability? suitability) {
//     if (suitability == null) return '🚫 No cultivation recommended';
//
//     // Map activities based on suitability
//     switch (suitability) {
//       case SeasonSuitability.highCompatibility:
//         // Peak season - Show crop growth stages
//         if (month >= 3 && month <= 5) {
//           return '🌱 Planting & Sowing';
//         } else if (month >= 6 && month <= 8) {
//           return '🌿 Active Growth Phase';
//         } else if (month >= 9 && month <= 11) {
//           return '🌾 Flowering & Maturation';
//         } else {
//           return '📦 Harvest & Storage';
//         }
//
//       case SeasonSuitability.normal:
//         // Moderate season - Maintenance activities
//         if (month >= 3 && month <= 5) {
//           return '🌾 Land Preparation';
//         } else if (month >= 6 && month <= 8) {
//           return '💧 Irrigation & Care';
//         } else if (month >= 9 && month <= 11) {
//           return '🌿 Vegetative Stage';
//         } else {
//           return '🔧 Maintenance';
//         }
//
//       case SeasonSuitability.notRecommended:
//         // Off-season - Show alternative activities
//         return '🏗️ Field Preparation';
//     }
//   }
// }
