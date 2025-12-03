import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sih_25044/home/model/weather_model.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../controller/home_controller.dart';
import '../../model/crop_model.dart';
import '../widgets/weather_indicator.dart';
import '../widgets/crop_tile.dart';
import 'month_detail_screen.dart';
import 'daily_action_screen.dart';

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

  // Calendar navigation state
  String _calendarView = 'year'; // 'year', 'month', or 'date'
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  int _yearPageIndex = 0; // For navigating year pages

  @override
  void initState() {
    super.initState();
    _homeController = HomeController();
    _pageController = PageController(
      viewportFraction: 0.35,
      initialPage: 500000,
    );
    // Start auto-scroll after widget is built
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
          // Ignore errors during scrolling
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
          title: const Text(
            'Crop Management',
            style: TextStyle(
              color: Color(0xFF2D5016),
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          actions: [
            Consumer<HomeController>(
              builder: (context, controller, _) => controller.alerts.isNotEmpty
                  ? Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notification_important,
                            color: Color(0xFF2D5016),
                          ),
                          onPressed: () =>
                              _showAlertsDialog(context, controller),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${controller.alerts.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
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
                    // Weather Indicator
                    WeatherIndicator(weather: controller.currentWeather),

                    const SizedBox(height: 1),

                    // Crop Selection Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Crop',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D5016),
                            ),
                          ),
                          Text(
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

                    // Horizontal Crop Tiles - Auto-scrolling Carousel
                    SizedBox(
                      height: 100,
                      child: Consumer<HomeController>(
                        builder: (context, controller, _) {
                          return GestureDetector(
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
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Calendar Section
                    if (controller.selectedCrop != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Yearly Calendar - ${controller.selectedCrop!.name}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D5016),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Legend
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildLegendItem(
                              SeasonSuitability.highCompatibility.color,
                              SeasonSuitability.highCompatibility.label,
                            ),
                            _buildLegendItem(
                              SeasonSuitability.normal.color,
                              SeasonSuitability.normal.label,
                            ),
                            _buildLegendItem(
                              SeasonSuitability.notRecommended.color,
                              SeasonSuitability.notRecommended.label,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Calendar with 3-level navigation
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFE8F5E9), // Light mint green
                              Color(0xFFF1F8E9), // Light lime
                              Color(0xFFFFF9E6), // Soft cream
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF4CAF50).withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              blurRadius: 8,
                              offset: const Offset(-4, -4),
                            ),
                          ],
                          border: Border.all(
                            color: Color(0xFFC8E6C9).withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: _buildCalendarView(controller),
                      ),

                      const SizedBox(height: 12),

                      // Month Tasks Preview
                      if (controller
                          .getWeeklyTasksForMonth(_focusedDay.month)
                          .isNotEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tasks for ${_getMonthName(_focusedDay.month)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2D5016),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ChangeNotifierProvider.value(
                                                value: _homeController,
                                                child: MonthDetailScreen(
                                                  month: _focusedDay.month,
                                                ),
                                              ),
                                        ),
                                      );
                                    },
                                    child: const Text('View All'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${controller.getWeeklyTasksForMonth(_focusedDay.month).length} weeks planned',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF2D5016)),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
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
    return months[month - 1];
  }

  void _showAlertsDialog(BuildContext context, HomeController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: _getHighestSeverityColor(controller.alerts),
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Weather Alerts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: controller.alerts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final alert = controller.alerts[index];
              return _buildAlertItem(alert);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: Color(0xFF2D5016),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(WeatherAlert alert) {
    final color = _getSeverityColor(alert.severity);
    final icon = _getSeverityIcon(alert.severity);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getSeverityLabel(alert.severity),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return const Color(0xFFD32F2F);
      case AlertSeverity.high:
        return const Color(0xFFE74C3C);
      case AlertSeverity.medium:
        return const Color(0xFFF39C12);
      case AlertSeverity.low:
        return const Color(0xFF3498DB);
    }
  }

  Color _getHighestSeverityColor(List<WeatherAlert> alerts) {
    if (alerts.any((a) => a.severity == AlertSeverity.critical)) {
      return const Color(0xFFD32F2F);
    } else if (alerts.any((a) => a.severity == AlertSeverity.high)) {
      return const Color(0xFFE74C3C);
    } else if (alerts.any((a) => a.severity == AlertSeverity.medium)) {
      return const Color(0xFFF39C12);
    } else {
      return const Color(0xFF3498DB);
    }
  }

  IconData _getSeverityIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Icons.error;
      case AlertSeverity.high:
        return Icons.warning_amber_rounded;
      case AlertSeverity.medium:
        return Icons.info_outline;
      case AlertSeverity.low:
        return Icons.info;
    }
  }

  String _getSeverityLabel(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return 'CRITICAL';
      case AlertSeverity.high:
        return 'HIGH';
      case AlertSeverity.medium:
        return 'MEDIUM';
      case AlertSeverity.low:
        return 'LOW';
    }
  }

  // Build calendar view based on current navigation level
  Widget _buildCalendarView(HomeController controller) {
    switch (_calendarView) {
      case 'year':
        return _buildYearSelectionView(controller);
      case 'month':
        return _buildMonthSelectionView(controller);
      case 'date':
      default:
        return _buildDateCalendarView(controller);
    }
  }

  // Year Selection View - Grid of years
  Widget _buildYearSelectionView(HomeController controller) {
    final currentYear = DateTime.now().year;
    final startYear = 2000 + (_yearPageIndex * 16);
    final years = List.generate(16, (index) => startYear + index);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with navigation arrows
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, size: 28),
                onPressed: _yearPageIndex > 0
                    ? () {
                        setState(() {
                          _yearPageIndex--;
                        });
                      }
                    : null,
                color:
                    controller.selectedCrop?.themeColor ??
                    const Color(0xFF2D5016),
              ),
              const SizedBox(width: 16),
              Text(
                '${years.first} - ${years.last}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color:
                      controller.selectedCrop?.themeColor ??
                      const Color(0xFF2D5016),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(Icons.chevron_right, size: 28),
                onPressed: () {
                  setState(() {
                    _yearPageIndex++;
                  });
                },
                color:
                    controller.selectedCrop?.themeColor ??
                    const Color(0xFF2D5016),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Year Grid - 4 rows x 4 columns = 16 years per page
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: 16,
            itemBuilder: (context, index) {
              final year = years[index];
              final isSelected = year == _selectedYear;
              final isCurrent = year == currentYear;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedYear = year;
                    _calendarView = 'month';
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? controller.selectedCrop?.themeColor ??
                              const Color(0xFF64B5F6)
                        : isCurrent
                        ? (controller.selectedCrop?.themeColor ??
                                  const Color(0xFF90CAF9))
                              .withOpacity(0.3)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      '$year',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // Today button
          TextButton(
            onPressed: () {
              setState(() {
                _calendarView = 'date';
                _selectedYear = currentYear;
                _selectedMonth = DateTime.now().month;
                _focusedDay = DateTime.now();
                _yearPageIndex = (currentYear - 2000) ~/ 16;
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text('Go to Today'),
          ),
        ],
      ),
    );
  }

  // Month Selection View - Grid of months
  Widget _buildMonthSelectionView(HomeController controller) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, size: 28),
                onPressed: () {
                  setState(() {
                    _calendarView = 'year';
                  });
                },
                color:
                    controller.selectedCrop?.themeColor ??
                    const Color(0xFF2D5016),
              ),
              const SizedBox(width: 16),
              Text(
                '$_selectedYear',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color:
                      controller.selectedCrop?.themeColor ??
                      const Color(0xFF2D5016),
                ),
              ),
              const SizedBox(width: 60),
            ],
          ),
          const SizedBox(height: 24),
          // Month Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final monthName = months[index];
              final isSelected = month == _selectedMonth;
              final isCurrent =
                  month == DateTime.now().month &&
                  _selectedYear == DateTime.now().year;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMonth = month;
                    _focusedDay = DateTime(_selectedYear, month, 1);
                    _calendarView = 'date';
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? controller.selectedCrop?.themeColor ??
                              const Color(0xFF64B5F6)
                        : isCurrent
                        ? (controller.selectedCrop?.themeColor ??
                                  const Color(0xFF90CAF9))
                              .withOpacity(0.3)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      monthName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Date Calendar View - Normal calendar with dates
  Widget _buildDateCalendarView(HomeController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, size: 28),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(
                      _focusedDay.year,
                      _focusedDay.month - 1,
                      1,
                    );
                    _selectedMonth = _focusedDay.month;
                    _selectedYear = _focusedDay.year;
                  });
                },
                color: Color(0xFF2D5016),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _calendarView = 'month';
                  });
                },
                child: Text(
                  '${_getMonthName(_focusedDay.month)} ${_focusedDay.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D5016),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(Icons.chevron_right, size: 28),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(
                      _focusedDay.year,
                      _focusedDay.month + 1,
                      1,
                    );
                    _selectedMonth = _focusedDay.month;
                    _selectedYear = _focusedDay.year;
                  });
                },
                color: Color(0xFF2D5016),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TableCalendar(
            firstDay: DateTime(_selectedYear, 1, 1),
            lastDay: DateTime(_selectedYear, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerVisible: false,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF81C784).withOpacity(0.6),
                    Color(0xFF66BB6A).withOpacity(0.6),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF4CAF50).withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              weekendTextStyle: const TextStyle(
                color: Color(0xFFE57373),
                fontWeight: FontWeight.w500,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              controller.selectDate(selectedDay);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: _homeController,
                    child: DailyActionScreen(date: selectedDay),
                  ),
                ),
              );
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
                _selectedMonth = focusedDay.month;
                _selectedYear = focusedDay.year;
              });
              controller.selectMonth(focusedDay.month);
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                return Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        color: Color(0xFF2D5016),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
              todayBuilder: (context, day, focusedDay) {
                return Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFA5D6A7).withOpacity(0.5),
                        Color(0xFF81C784).withOpacity(0.5),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFF66BB6A), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
              selectedBuilder: (context, day, focusedDay) {
                return Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF4CAF50).withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
