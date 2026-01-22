// daily_actions_screen.dart - Show AI-powered daily recommendations
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../widgets/translated_text.dart';

class DailyActionsScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Map<String, dynamic> farmData;

  const DailyActionsScreen({
    super.key,
    required this.selectedDate,
    required this.farmData,
  });

  @override
  State<DailyActionsScreen> createState() => _DailyActionsScreenState();
}

class _DailyActionsScreenState extends State<DailyActionsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _planData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final formattedDate = DateFormat(
        'EEEE, MMMM d, yyyy',
      ).format(widget.selectedDate);
      final dayOfYear =
          widget.selectedDate
              .difference(DateTime(widget.selectedDate.year, 1, 1))
              .inDays +
          1;
      final season = _getSeason(widget.selectedDate.month);

      final prompt =
          '''
You are an agricultural expert for Tamil Nadu, India. Provide daily farming recommendations for:

Date: $formattedDate (Day $dayOfYear of ${widget.selectedDate.year})
Season: $season
Farm Location: ${widget.farmData['district'] ?? 'Tamil Nadu'}

Provide practical, actionable advice for this specific day. Return ONLY valid JSON (no markdown):

{
  "morning_tasks": [
    {
      "task": "Task name",
      "description": "2-3 sentences on what to do",
      "priority": "High/Medium/Low",
      "duration": "30 mins"
    }
  ],
  "afternoon_tasks": [
    {
      "task": "Task name",
      "description": "What to do and why",
      "priority": "High/Medium/Low",
      "duration": "1 hour"
    }
  ],
  "evening_tasks": [
    {
      "task": "Task name", 
      "description": "Evening activities",
      "priority": "High/Medium/Low",
      "duration": "45 mins"
    }
  ],
  "weather_advice": "Weather-specific advice for today",
  "crop_care_tip": "One specific crop care tip for this date",
  "important_reminder": "Critical reminder for farmers today"
}

Focus on:
- Season-appropriate activities for $season
- Weather considerations for Odisha in ${DateFormat('MMMM').format(widget.selectedDate)}
- Practical tasks farmers can do today
- Keep descriptions simple and farmer-friendly
''';

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']!}',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an agricultural expert for Tamil Nadu, India. Provide practical farming advice. Return ONLY valid JSON, no markdown or extra text.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 1500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'].trim();

        // Remove markdown if present
        content = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final planData = jsonDecode(content);

        setState(() {
          _planData = planData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to get AI recommendations: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  String _getSeason(int month) {
    if (month >= 3 && month <= 5) return 'Summer (Pre-Monsoon)';
    if (month >= 6 && month <= 9) return 'Monsoon (Rainy Season)';
    if (month >= 10 && month <= 11) return 'Post-Monsoon (Autumn)';
    return 'Winter';
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red.shade600;
      case 'medium':
        return Colors.orange.shade600;
      case 'low':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TranslatedText(
          'Daily Plan - ${DateFormat('MMM dd, yyyy').format(widget.selectedDate)}',
        ),
        backgroundColor: const Color(0xFF27AE60),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset('assets/loading.json', width: 150, height: 150),
                  const SizedBox(height: 16),
                  TranslatedText(
                    'Getting your daily recommendations...',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            )
          : _error != null
          ? _buildErrorView()
          : _buildPlanView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            TranslatedText(
              'Unable to Load Plan',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            TranslatedText(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPlan,
              icon: const Icon(Icons.refresh),
              label: const TranslatedText('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanView() {
    if (_planData == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header Card
          _buildDateHeaderCard(),
          const SizedBox(height: 16),

          // Important Reminder Card
          if (_planData!['important_reminder'] != null)
            _buildReminderCard(_planData!['important_reminder']),
          if (_planData!['important_reminder'] != null)
            const SizedBox(height: 16),

          // Morning Tasks
          _buildTaskSection(
            'Morning Tasks',
            _planData!['morning_tasks'] ?? [],
            Icons.wb_sunny,
            Colors.orange.shade600,
          ),
          const SizedBox(height: 16),

          // Afternoon Tasks
          _buildTaskSection(
            'Afternoon Tasks',
            _planData!['afternoon_tasks'] ?? [],
            Icons.wb_sunny_outlined,
            Colors.amber.shade700,
          ),
          const SizedBox(height: 16),

          // Evening Tasks
          _buildTaskSection(
            'Evening Tasks',
            _planData!['evening_tasks'] ?? [],
            Icons.nightlight_round,
            Colors.indigo.shade600,
          ),
          const SizedBox(height: 16),

          // Weather Advice
          if (_planData!['weather_advice'] != null)
            _buildInfoCard(
              'Weather Advice',
              _planData!['weather_advice'],
              Icons.cloud,
              Colors.blue.shade600,
            ),
          if (_planData!['weather_advice'] != null) const SizedBox(height: 12),

          // Crop Care Tip
          if (_planData!['crop_care_tip'] != null)
            _buildInfoCard(
              'Crop Care Tip',
              _planData!['crop_care_tip'],
              Icons.eco,
              Colors.green.shade600,
            ),

          const SizedBox(height: 16),
          _buildAIPoweredBadge(),
        ],
      ),
    );
  }

  Widget _buildDateHeaderCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TranslatedText(
                        DateFormat('EEEE, MMMM d').format(widget.selectedDate),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TranslatedText(
                        _getSeason(widget.selectedDate.month),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(String reminder) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade300, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.priority_high, color: Colors.red.shade700, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    'Important Reminder',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TranslatedText(
                    reminder,
                    style: TextStyle(fontSize: 14, color: Colors.red.shade800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskSection(
    String title,
    List<dynamic> tasks,
    IconData icon,
    Color color,
  ) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            TranslatedText(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...tasks.map((task) => _buildTaskCard(task)).toList(),
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final priority = task['priority'] ?? 'Medium';
    final taskName = task['task'] ?? 'Task';
    final description = task['description'] ?? '';
    final duration = task['duration'] ?? '';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(priority),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TranslatedText(
                    taskName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              TranslatedText(
                description,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
            if (duration.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    duration,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TranslatedText(
                    content,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIPoweredBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  'Powered by OpenAI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'GPT-4o-mini with Odisha farming expertise',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
