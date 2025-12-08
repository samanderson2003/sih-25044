import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

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
  int _selectedMonth = DateTime.now().month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _yearPageIndex = 0; // For navigating year pages

  @override
  void initState() {
    super.initState();
    // Calculate initial page index for years (starts at 2000)
    _yearPageIndex = (DateTime.now().year - 2000) ~/ 16;
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
            title: Text(
              controller.selectedCrop != null
                  ? 'Yearly Calendar - ${controller.selectedCrop!.name}'
                  : 'Yearly Calendar',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D5016),
              ),
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
                Text(
                  'Please select a crop first',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
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
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFE8F5E9),
                          Color(0xFFF1F8E9),
                          Color(0xFFFFF9E6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFC8E6C9).withOpacity(0.5),
                        width: 1.5,
                      ),
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
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }

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

  Widget _buildYearSelectionView(HomeController controller) {
    final currentYear = DateTime.now().year;
    final startYear = 2000 + (_yearPageIndex * 16);
    final years = List.generate(16, (index) => startYear + index);

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
                onPressed: _yearPageIndex > 0
                    ? () {
                  setState(() {
                    _yearPageIndex--;
                  });
                }
                    : null,
                color: controller.selectedCrop?.themeColor ?? const Color(0xFF2D5016),
              ),
              const SizedBox(width: 16),
              Text(
                '${years.first} - ${years.last}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: controller.selectedCrop?.themeColor ?? const Color(0xFF2D5016),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 28),
                onPressed: () {
                  setState(() {
                    _yearPageIndex++;
                  });
                },
                color: controller.selectedCrop?.themeColor ?? const Color(0xFF2D5016),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
                        ? controller.selectedCrop?.themeColor ?? const Color(0xFF64B5F6)
                        : isCurrent
                        ? (controller.selectedCrop?.themeColor ?? const Color(0xFF90CAF9)).withOpacity(0.3)
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
            child: const TranslatedText('Go to Today'),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelectionView(HomeController controller) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

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
                    _calendarView = 'year';
                  });
                },
                color: controller.selectedCrop?.themeColor ?? const Color(0xFF2D5016),
              ),
              const SizedBox(width: 16),
              Text(
                '$_selectedYear',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: controller.selectedCrop?.themeColor ?? const Color(0xFF2D5016),
                ),
              ),
              const SizedBox(width: 60),
            ],
          ),
          const SizedBox(height: 24),
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
              final isCurrent = month == DateTime.now().month && _selectedYear == DateTime.now().year;

              final suitability = controller.getSuitabilityForMonth(month);
              Color monthColor;

              if (isSelected) {
                monthColor = controller.selectedCrop?.themeColor ?? const Color(0xFF64B5F6);
              } else if (suitability != null) {
                monthColor = suitability.color.withOpacity(isCurrent ? 0.9 : 0.7);
              } else {
                monthColor = const Color(0xFFFFF3E0);
              }

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
                    color: monthColor,
                    borderRadius: BorderRadius.circular(24),
                    border: isCurrent ? Border.all(color: Colors.black87, width: 2) : null,
                  ),
                  child: Center(
                    child: TranslatedText(
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
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                    _selectedMonth = _focusedDay.month;
                    _selectedYear = _focusedDay.year;
                  });
                },
                color: const Color(0xFF2D5016),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _calendarView = 'month';
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
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                    _selectedMonth = _focusedDay.month;
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
              weekdayStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              weekendStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final dayNames = {
                  DateTime.monday: 'Mon', DateTime.tuesday: 'Tue', DateTime.wednesday: 'Wed',
                  DateTime.thursday: 'Thu', DateTime.friday: 'Fri', DateTime.saturday: 'Sat', DateTime.sunday: 'Sun',
                };
                return Center(
                  child: TranslatedText(
                    dayNames[day.weekday] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: day.weekday == DateTime.saturday || day.weekday == DateTime.sunday
                          ? const Color(0xFFE57373)
                          : const Color(0xFF2D5016),
                    ),
                  ),
                );
              },
              defaultBuilder: (context, day, focusedDay) {
                final suitability = controller.getSuitabilityForMonth(day.month);
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
                    border: Border.all(color: const Color(0xFF66BB6A), width: 2),
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
                    content: TranslatedText('Please complete your farm profile first'),
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