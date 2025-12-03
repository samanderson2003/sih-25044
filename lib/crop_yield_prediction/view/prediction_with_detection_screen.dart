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
          // Custom AppBar with Split Tabs
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2D5016),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Row(
              children: [
                // Crop Yield Prediction Tab
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _tabController.animateTo(0);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _tabController.index == 0
                            ? const Color(0xFFF8F6F0)
                            : Colors.transparent,
                        border: _tabController.index == 0
                            ? const Border(
                                bottom: BorderSide(
                                  color: Color(0xFF2D5016),
                                  width: 3,
                                ),
                              )
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: _tabController.index == 0
                                ? const Color(0xFF2D5016)
                                : Colors.white.withOpacity(0.9),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Crop Yield',
                            style: TextStyle(
                              color: _tabController.index == 0
                                  ? const Color(0xFF2D5016)
                                  : Colors.white.withOpacity(0.9),
                              fontSize: 15,
                              fontWeight: _tabController.index == 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Vertical Divider
                Container(
                  width: 1.5,
                  height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.4),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
                // Detection Tab
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _tabController.animateTo(1);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _tabController.index == 1
                            ? const Color(0xFFF8F6F0)
                            : Colors.transparent,
                        border: _tabController.index == 1
                            ? const Border(
                                bottom: BorderSide(
                                  color: Color(0xFF2D5016),
                                  width: 3,
                                ),
                              )
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            color: _tabController.index == 1
                                ? const Color(0xFF2D5016)
                                : Colors.white.withOpacity(0.9),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Detection',
                            style: TextStyle(
                              color: _tabController.index == 1
                                  ? const Color(0xFF2D5016)
                                  : Colors.white.withOpacity(0.9),
                              fontSize: 15,
                              fontWeight: _tabController.index == 1
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
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
}
