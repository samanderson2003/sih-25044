import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/home_controller.dart';
import '../../model/crop_model.dart';

class MonthDetailScreen extends StatelessWidget {
  final int month;

  const MonthDetailScreen({super.key, required this.month});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HomeController>(context);
    final weeklyTasks = controller.getWeeklyTasksForMonth(month);
    final suitability = controller.getSuitabilityForMonth(month);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2D5016),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_getMonthName(month)} - ${controller.selectedCrop?.name ?? ""}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Month Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: suitability?.color ?? Colors.grey,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getSuitabilityIcon(suitability),
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suitability?.label ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getSuitabilityDescription(suitability),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Weekly Tasks Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: Color(0xFF2D5016)),
                SizedBox(width: 8),
                Text(
                  'Weekly Task Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D5016),
                  ),
                ),
              ],
            ),
          ),

          // Weekly Tasks List
          Expanded(
            child: weeklyTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks planned for this month',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: weeklyTasks.length,
                    itemBuilder: (context, index) {
                      final task = weeklyTasks[index];
                      return _buildWeekCard(task, controller);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekCard(WeeklyTask task, HomeController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Week Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: controller.selectedCrop?.themeColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: controller.selectedCrop?.themeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Week ${task.week}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.stage,
                    style: TextStyle(
                      color: controller.selectedCrop?.themeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tasks List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tasks:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D5016),
                  ),
                ),
                const SizedBox(height: 8),
                ...task.tasks.map(
                  (taskItem) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: controller.selectedCrop?.themeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            taskItem,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF555555),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSuitabilityIcon(SeasonSuitability? suitability) {
    if (suitability == null) return Icons.help_outline;
    switch (suitability) {
      case SeasonSuitability.highCompatibility:
        return Icons.check_circle;
      case SeasonSuitability.normal:
        return Icons.circle;
      case SeasonSuitability.notRecommended:
        return Icons.warning;
    }
  }

  String _getSuitabilityDescription(SeasonSuitability? suitability) {
    if (suitability == null) return 'No data available';
    switch (suitability) {
      case SeasonSuitability.highCompatibility:
        return 'Optimal conditions for growth';
      case SeasonSuitability.normal:
        return 'Moderate growing conditions';
      case SeasonSuitability.notRecommended:
        return 'Not ideal for cultivation';
    }
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
