import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:lottie/lottie.dart';

// Import your app's specific files
import '../../controller/home_controller.dart';
import '../../model/crop_model.dart';
import 'daily_actions_screen.dart';
import '../../../services/ml_api_service.dart';
import '../../../prior_data/controller/farm_data_controller.dart';
import '../../../widgets/translated_text.dart';

class CalendarFullScreen extends StatefulWidget {
  const CalendarFullScreen({super.key});

  @override
  State<CalendarFullScreen> createState() => _CalendarFullScreenState();
}

class _CalendarFullScreenState extends State<CalendarFullScreen> {
  String _calendarView = 'year'; // 'year', 'month', or 'date'
  int _selectedYear = DateTime.now().year;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final ScrollController _yearScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _yearScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F6F0),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFFF8F6F0),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF2D5016)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TranslatedText(
                  'Yearly Calendar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D5016),
                  ),
                ),
                if (controller.selectedCrop != null) ...[
                  const Text(
                    ' - ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D5016),
                    ),
                  ),
                  TranslatedText(
                    controller.selectedCrop!.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D5016),
                    ),
                  ),
                ],
              ],
            ),
            centerTitle: true,
          ),
          body: controller.selectedCrop == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.crop, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 24),
                      const TranslatedText(
                        'Please select a crop first',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Legend
                        Row(
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
                        const SizedBox(height: 24),
                        // Calendar Container
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: _buildCalendarView(controller),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
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
        TranslatedText(
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

  Widget _buildCalendarView(HomeController controller) {
    switch (_calendarView) {
      case 'year':
        return _buildYearSelectionView(controller);
      case 'month':
        return _buildMonthCalendarView(controller);
      case 'date':
      default:
        return _buildDateCalendarView(controller);
    }
  }

  Widget _buildYearSelectionView(HomeController controller) {
    final currentYear = DateTime.now().year;
    final startYear = 2005;
    final availableYears = List.generate(
      currentYear - startYear + 1,
      (index) => startYear + index,
    ).reversed.toList(); // Most recent years first

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Yearly Calendar',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D5016),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _calendarView = 'date';
                    _selectedYear = currentYear;
                    _focusedDay = DateTime.now();
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4CAF50),
                ),
                child: const TranslatedText('Go to Today'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Year selection in calendar grid format (2005-2025)
          Container(
            height: 200,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.2,
              ),
              itemCount: availableYears.length,
              itemBuilder: (context, index) {
                final year = availableYears[index];
                final isSelected = year == _selectedYear;
                final isCurrent = year == currentYear;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedYear = year;
                      _calendarView = 'month'; // Navigate to month view
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? controller.selectedCrop?.themeColor ??
                                const Color(0xFF4CAF50)
                          : isCurrent
                          ? (controller.selectedCrop?.themeColor ??
                                    const Color(0xFF4CAF50))
                                .withOpacity(0.2)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected || isCurrent
                            ? controller.selectedCrop?.themeColor ??
                                  const Color(0xFF4CAF50)
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$year',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          const Divider(height: 32, thickness: 1),

          // Best Crops by Month Timeline
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TranslatedText(
                'Best Crops by Month',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D5016),
                ),
              ),
              Text(
                ' - $_selectedYear',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D5016),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMonthlyTimelineView(controller),
        ],
      ),
    );
  }

  // Build monthly timeline view similar to home screen
  Widget _buildMonthlyTimelineView(HomeController controller) {
    final months = List.generate(12, (index) => index + 1);

    return Timeline.tileBuilder(
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
            final monthNum = months[index];
            final nextMonthNum = months[index + 1];
            final crops = _getCropsForMonth(controller, monthNum);
            final nextCrops = _getCropsForMonth(controller, nextMonthNum);

            if (crops.isNotEmpty || nextCrops.isNotEmpty) {
              // Use first crop's color or blend colors
              final color = crops.isNotEmpty
                  ? crops.first.themeColor
                  : nextCrops.first.themeColor;
              return SolidLineConnector(color: color.withOpacity(0.5));
            }
          }
          return SolidLineConnector(color: Colors.grey.shade200);
        },
        indicatorBuilder: (context, index) {
          final monthNum = months[index];
          final suitableCrops = _getCropsForMonth(controller, monthNum);

          Widget indicator;
          Color borderColor;
          List<Color>? gradientColors;

          if (suitableCrops.isNotEmpty) {
            // Use first crop's color
            borderColor = suitableCrops.first.themeColor;

            // If multiple crops, create gradient border
            if (suitableCrops.length > 1) {
              gradientColors = suitableCrops
                  .take(3)
                  .map((c) => c.themeColor)
                  .toList();
            }

            // Use first crop's icon as Lottie animation with larger size
            indicator = Lottie.asset(
              _getLottieAssetForMonth(monthNum),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.spa, color: borderColor, size: 36);
              },
            );
          } else {
            borderColor = Colors.grey.shade300;
            indicator = Icon(
              Icons.bedtime,
              color: Colors.grey.shade400,
              size: 30,
            );
          }

          return Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: gradientColors != null
                  ? null
                  : Border.all(
                      color: borderColor,
                      width: suitableCrops.isNotEmpty ? 3 : 1.5,
                    ),
              gradient: gradientColors != null
                  ? LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              boxShadow: [
                if (suitableCrops.isNotEmpty)
                  BoxShadow(
                    color: borderColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: gradientColors != null
                ? Container(
                    margin: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: indicator),
                  )
                : Center(child: indicator),
          );
        },
        contentsBuilder: (context, index) {
          final monthNum = months[index];
          final monthName = _getMonthName(monthNum);
          final suitableCrops = _getCropsForMonth(controller, monthNum);
          final hasCrops = suitableCrops.isNotEmpty;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: GestureDetector(
              onTap: () {
                if (hasCrops) {
                  setState(() {
                    _focusedDay = DateTime(_selectedYear, monthNum, 1);
                    _calendarView = 'date';
                  });
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
                      color: hasCrops ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (hasCrops) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getContrastBackgroundColor(
                          suitableCrops.first.themeColor,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: suitableCrops.first.themeColor.withOpacity(
                            0.4,
                          ),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${suitableCrops.length} ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _getContrastTextColor(
                                suitableCrops.first.themeColor,
                              ),
                            ),
                          ),
                          TranslatedText(
                            suitableCrops.length > 1 ? 'crops' : 'crop',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _getContrastTextColor(
                                suitableCrops.first.themeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Show crop icons
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      alignment: index % 2 == 0
                          ? WrapAlignment.end
                          : WrapAlignment.start,
                      children: suitableCrops.take(4).map((crop) {
                        return Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: crop.themeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            crop.icon,
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                    ),
                  ] else
                    const TranslatedText(
                      'No crops',
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper to get Lottie asset based on month (seasonal)
  String _getLottieAssetForMonth(int month) {
    // Spring months (March-May): sowing
    if (month >= 3 && month <= 5) {
      return 'assets/sowing.json';
    }
    // Summer/Monsoon (June-September): growing/rainy
    else if (month >= 6 && month <= 9) {
      return month >= 6 && month <= 8
          ? 'assets/Rainy.json'
          : 'assets/growing.json';
    }
    // Autumn (October-November): harvest
    else if (month >= 10 && month <= 11) {
      return 'assets/harvest.json';
    }
    // Winter (December-February): preparation
    else {
      return 'assets/land preparation.json';
    }
  }

  // Helper to get contrasting background color for better visibility
  Color _getContrastBackgroundColor(Color color) {
    // Calculate luminance to determine if color is light or dark
    final luminance = color.computeLuminance();

    // For light colors (yellow, light green, etc.), use darker background
    if (luminance > 0.5) {
      return color.withOpacity(0.3);
    }
    // For dark colors, use lighter background
    return color.withOpacity(0.15);
  }

  // Helper to get contrasting text color
  Color _getContrastTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();

    // For light/yellow colors, use darker text
    if (luminance > 0.5) {
      return backgroundColor.computeLuminance() > 0.7
          ? Colors.grey.shade800
          : backgroundColor;
    }
    // For dark colors, use the original color
    return backgroundColor;
  }

  // Get crops suitable for a specific month
  List<Crop> _getCropsForMonth(HomeController controller, int month) {
    final allCrops = controller.crops;
    final suitableCrops = <Crop>[];

    for (final crop in allCrops) {
      // Check if this crop has high compatibility for this month
      // Access monthSuitability directly without calling selectCrop
      final suitability = crop.monthSuitability[month];

      if (suitability == SeasonSuitability.highCompatibility) {
        suitableCrops.add(crop);
      }
    }

    return suitableCrops;
  }

  // Get month suitability for selected crop
  SeasonSuitability _getMonthSuitability(HomeController controller, int month) {
    if (controller.selectedCrop == null) {
      return SeasonSuitability.notRecommended;
    }
    return controller.selectedCrop!.monthSuitability[month] ??
        SeasonSuitability.notRecommended;
  }

  // Build month calendar view with color highlighting
  Widget _buildMonthCalendarView(HomeController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 24),
                onPressed: () {
                  setState(() {
                    _calendarView = 'year';
                  });
                },
                color: const Color(0xFF2D5016),
              ),
              Text(
                '${controller.selectedCrop?.name ?? "Crop"} Calendar - $_selectedYear',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D5016),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _calendarView = 'date';
                    _selectedYear = DateTime.now().year;
                    _focusedDay = DateTime.now();
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4CAF50),
                ),
                child: const TranslatedText('Today'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 12 Month Grid with Color Highlighting
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final monthNum = index + 1;
              final monthName = _getMonthName(monthNum);
              final suitability = _getMonthSuitability(controller, monthNum);
              final isCurrentMonth =
                  monthNum == DateTime.now().month &&
                  _selectedYear == DateTime.now().year;

              Color backgroundColor;
              Color borderColor;
              Color textColor;

              switch (suitability) {
                case SeasonSuitability.highCompatibility:
                  backgroundColor = SeasonSuitability.highCompatibility.color
                      .withOpacity(0.2);
                  borderColor = SeasonSuitability.highCompatibility.color;
                  textColor = SeasonSuitability.highCompatibility.color;
                  break;
                case SeasonSuitability.normal:
                  backgroundColor = SeasonSuitability.normal.color.withOpacity(
                    0.2,
                  );
                  borderColor = SeasonSuitability.normal.color;
                  textColor = SeasonSuitability.normal.color;
                  break;
                case SeasonSuitability.notRecommended:
                  backgroundColor = SeasonSuitability.notRecommended.color
                      .withOpacity(0.1);
                  borderColor = SeasonSuitability.notRecommended.color;
                  textColor = Colors.grey.shade600;
                  break;
              }

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _focusedDay = DateTime(_selectedYear, monthNum, 1);
                    _calendarView = 'date';
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrentMonth
                          ? Colors.green.shade700
                          : borderColor,
                      width: isCurrentMonth ? 3 : 2,
                    ),
                    boxShadow:
                        suitability == SeasonSuitability.highCompatibility
                        ? [
                            BoxShadow(
                              color: borderColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        monthName.substring(0, 3),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        _getIconForSuitability(suitability),
                        color: borderColor,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getLabelForSuitability(suitability),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getIconForSuitability(SeasonSuitability suitability) {
    switch (suitability) {
      case SeasonSuitability.highCompatibility:
        return Icons.star;
      case SeasonSuitability.normal:
        return Icons.check_circle_outline;
      case SeasonSuitability.notRecommended:
        return Icons.cancel_outlined;
    }
  }

  String _getLabelForSuitability(SeasonSuitability suitability) {
    switch (suitability) {
      case SeasonSuitability.highCompatibility:
        return 'Peak Season';
      case SeasonSuitability.normal:
        return 'Moderate';
      case SeasonSuitability.notRecommended:
        return 'Not Ideal';
    }
  }

  Widget _buildDateCalendarView(HomeController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 28),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(
                      _focusedDay.year,
                      _focusedDay.month - 1,
                      1,
                    );
                    _selectedYear = _focusedDay.year;
                  });
                },
                color: const Color(0xFF2D5016),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _calendarView = 'year';
                  });
                },
                child: TranslatedText(
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
                icon: const Icon(Icons.chevron_right, size: 28),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(
                      _focusedDay.year,
                      _focusedDay.month + 1,
                      1,
                    );
                    _selectedYear = _focusedDay.year;
                  });
                },
                color: const Color(0xFF2D5016),
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
            daysOfWeekHeight: 40,
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              weekendStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final dayNames = {
                  DateTime.monday: 'Mon',
                  DateTime.tuesday: 'Tue',
                  DateTime.wednesday: 'Wed',
                  DateTime.thursday: 'Thu',
                  DateTime.friday: 'Fri',
                  DateTime.saturday: 'Sat',
                  DateTime.sunday: 'Sun',
                };
                return Center(
                  child: TranslatedText(
                    dayNames[day.weekday] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color:
                          day.weekday == DateTime.saturday ||
                              day.weekday == DateTime.sunday
                          ? const Color(0xFFE57373)
                          : const Color(0xFF2D5016),
                    ),
                  ),
                );
              },
              defaultBuilder: (context, day, focusedDay) {
                final suitability = controller.getSuitabilityForMonth(
                  day.month,
                );
                Color backgroundColor = Colors.white.withOpacity(0.5);
                if (suitability != null) {
                  backgroundColor = suitability.color.withOpacity(0.3);
                }
                return Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: backgroundColor,
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
                        const Color(0xFFA5D6A7).withOpacity(0.5),
                        const Color(0xFF81C784).withOpacity(0.5),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF66BB6A),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        color: Color(0xFF2D5016),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF81C784).withOpacity(0.6),
                    const Color(0xFF66BB6A).withOpacity(0.6),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.4),
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
            onDaySelected: (selectedDay, focusedDay) async {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              controller.selectDate(selectedDay);

              // Get farm data for ML API
              final farmDataController = FarmDataController();
              final farmData = await farmDataController.getFarmData();

              if (farmData == null) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: TranslatedText(
                      'Please complete your farm profile first',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              // Prepare data for ML API
              final apiData = MLApiService.prepareFarmDataForAPI(
                farmBasics: farmData.farmBasics.toJson(),
                soilQuality: farmData.soilQuality.toJson(),
                climateData: farmData.climateData?.toJson() ?? {},
                plantingDate: DateTime.now()
                    .subtract(const Duration(days: 30))
                    .toIso8601String()
                    .split('T')[0],
              );

              if (!mounted) return;
              // Navigate to daily actions
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DailyActionsScreen(
                    key: ValueKey('daily_plan_${selectedDay.toString()}'),
                    selectedDate: selectedDay,
                    farmData: apiData,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
