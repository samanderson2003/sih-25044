import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../controller/home_controller.dart';
import '../../model/crop_model.dart';
import '../widgets/weather_indicator.dart';
import '../widgets/crop_tile.dart';
import '../widgets/weather_alerts.dart';
import 'month_detail_screen.dart';
import 'daily_action_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeController(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F0),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF2D5016),
          title: const Text(
            'Crop Management',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          actions: [
            Consumer<HomeController>(
              builder: (context, controller, _) => IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
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
                    // Weather Indicator & Alerts
                    WeatherIndicator(weather: controller.currentWeather),
                    if (controller.alerts.isNotEmpty)
                      WeatherAlerts(alerts: controller.alerts),

                    const SizedBox(height: 16),

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

                    const SizedBox(height: 12),

                    // Horizontal Crop Tiles
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: controller.crops.length,
                        itemBuilder: (context, index) {
                          final crop = controller.crops[index];
                          final isSelected =
                              controller.selectedCrop?.id == crop.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: CropTile(
                              crop: crop,
                              isSelected: isSelected,
                              onTap: () => controller.selectCrop(crop),
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

                      const SizedBox(height: 12),

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

                      const SizedBox(height: 16),

                      // Calendar
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TableCalendar(
                          firstDay: DateTime(DateTime.now().year, 1, 1),
                          lastDay: DateTime(DateTime.now().year, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          calendarFormat: CalendarFormat.month,
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: controller.selectedCrop!.themeColor
                                  .withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: controller.selectedCrop!.themeColor,
                              shape: BoxShape.circle,
                            ),
                            weekendTextStyle: const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                            controller.selectDate(selectedDay);

                            // Navigate to daily action screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChangeNotifierProvider.value(
                                      value: controller,
                                      child: DailyActionScreen(
                                        date: selectedDay,
                                      ),
                                    ),
                              ),
                            );
                          },
                          onPageChanged: (focusedDay) {
                            setState(() {
                              _focusedDay = focusedDay;
                            });
                            controller.selectMonth(focusedDay.month);
                          },
                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: (context, day, focusedDay) {
                              final suitability = controller
                                  .getSuitabilityForMonth(day.month);
                              if (suitability == null) return null;

                              return Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: suitability.color.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: suitability.color.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      color: suitability.color.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Month Tasks Preview
                      if (controller
                          .getWeeklyTasksForMonth(_focusedDay.month)
                          .isNotEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
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
                                                value: controller,
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
}
