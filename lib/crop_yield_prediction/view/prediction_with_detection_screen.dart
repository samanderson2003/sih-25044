import 'package:flutter/material.dart';
import 'crop_yield_prediction_screen.dart';
import '../../crop_diseases_detection/view/crop_detection_screen.dart';

class PredictionWithDetectionScreen extends StatefulWidget {
  const PredictionWithDetectionScreen({super.key});

  @override
  State<PredictionWithDetectionScreen> createState() =>
      _PredictionWithDetectionScreenState();
}

class _PredictionWithDetectionScreenState
    extends State<PredictionWithDetectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      body: Column(
        children: [
          // Transparent AppBar with Custom Tab Buttons
          Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
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
                // Crop Yield Tab
                Expanded(
                  child: _buildTabButton(
                    index: 0,
                    icon: Icons.trending_up_rounded,
                    label: 'Crop Yield',
                  ),
                ),
                const SizedBox(width: 12),
                // Detection Tab
                Expanded(
                  child: _buildTabButton(
                    index: 1,
                    icon: Icons.camera_alt_rounded,
                    label: 'Detection',
                  ),
                ),
              ],
            ),
          ),
          // TabBarView Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                CropYieldPredictionScreen(),
                CropDetectionScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _tabController.index == index;

    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2D5016).withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2D5016).withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF2D5016)
                  : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF2D5016)
                      : Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}