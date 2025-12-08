import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timelines_plus/timelines_plus.dart';
import '../../model/crop_model.dart';

class CropPlanScreen extends StatelessWidget {
  final Crop crop;
  final int startMonth; // e.g., 1 for January

  const CropPlanScreen({
    super.key,
    required this.crop,
    required this.startMonth
  });

  @override
  Widget build(BuildContext context) {
    // We assume planting starts on the 1st of the selected month
    final int currentYear = DateTime.now().year;
    // If the selected month is earlier than current month, maybe user means next year?
    // For simplicity, we just use currentYear.
    final DateTime plantingDate = DateTime(currentYear, startMonth, 1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F0),
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              '${crop.name} Schedule',
              style: const TextStyle(
                  color: Color(0xFF2D5016),
                  fontWeight: FontWeight.bold,
                  fontSize: 18
              ),
            ),
            Text(
              'Starting ${DateFormat('MMMM d').format(plantingDate)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        leading: const BackButton(color: Color(0xFF2D5016)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: crop.lifecycleStages.isEmpty
            ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  "No detailed schedule available for ${crop.name}",
                  style: TextStyle(color: Colors.grey[600]),
                )
              ],
            )
        )
            : Timeline.tileBuilder(
          theme: TimelineThemeData(
            nodePosition: 0,
            color: crop.themeColor,
            connectorTheme: ConnectorThemeData(thickness: 2.5, color: Colors.grey[300]),
          ),
          builder: TimelineTileBuilder.connected(
            connectionDirection: ConnectionDirection.before,
            itemCount: crop.lifecycleStages.length,

            // The Dot/Icon
            indicatorBuilder: (_, index) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: crop.themeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: crop.themeColor, width: 2),
                ),
                child: Icon(
                    crop.lifecycleStages[index].icon,
                    color: crop.themeColor,
                    size: 20
                ),
              );
            },

            // The Line
            connectorBuilder: (_, index, __) => SolidLineConnector(
              color: crop.themeColor.withOpacity(0.5),
            ),

            // The Content (Day 5, Actions, etc)
            contentsBuilder: (context, index) {
              final stage = crop.lifecycleStages[index];
              // Calculate the actual calendar date for this stage
              final stageDate = plantingDate.add(Duration(days: stage.daysAfterPlanting - 1));

              return Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D5016).withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Date and "Day X" badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMM d, yyyy').format(stageDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2D5016),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: crop.themeColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Day ${stage.daysAfterPlanting}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Stage Name
                      Text(
                        stage.stageName,
                        style: TextStyle(
                          color: crop.themeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Main Action
                      Text(
                        stage.actionTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Description
                      Text(
                        stage.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}