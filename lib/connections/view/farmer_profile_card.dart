import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/farmer_model.dart';
import '../../widgets/translated_text.dart';

class FarmerProfileCard extends StatelessWidget {
  final FarmerProfile farmer;
  final bool isCurrentUser;
  final VoidCallback onClose;
  final VoidCallback onToggleFollow;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;

  const FarmerProfileCard({
    super.key,
    required this.farmer,
    required this.isCurrentUser,
    required this.onClose,
    required this.onToggleFollow,
    this.onCall,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F6F0),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Close Button
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: Color(0xFF2D5016)),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: const Color(0xFF2D5016),
                        child: Text(
                          farmer.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    farmer.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D5016),
                                    ),
                                  ),
                                ),
                                if (isCurrentUser) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D5016),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const TranslatedText(
                                      'You',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            TranslatedText(
                              '${farmer.village}, ${farmer.district}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Current Crop
                  _buildInfoRow(
                    icon: Icons.grass,
                    label: 'Current Crop',
                    value: farmer.currentCrop,
                    color: const Color(0xFF2D5016),
                  ),
                  const SizedBox(height: 16),

                  // Soil Health
                  _buildInfoRow(
                    icon: Icons.science,
                    label: 'Soil Health Status',
                    value: farmer.soilHealthStatus,
                    color: _getSoilHealthColor(farmer.soilHealthStatus),
                  ),
                  const SizedBox(height: 16),

                  // Irrigation Method
                  _buildInfoRow(
                    icon: Icons.water_drop,
                    label: 'Irrigation Method',
                    value: farmer.irrigationMethod,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 20),

                  // Risk Alerts
                  if (farmer.riskAlerts.isNotEmpty) ...[
                    _buildSectionTitle('⚠ Risk Alerts'),
                    const SizedBox(height: 8),
                    ...farmer.riskAlerts.map((alert) => _buildAlertCard(alert)),
                    const SizedBox(height: 20),
                  ],

                  // Latest Prediction
                  if (farmer.latestPrediction != null) ...[
                    _buildSectionTitle('📈 Latest Crop Prediction'),
                    const SizedBox(height: 12),
                    _buildPredictionCard(farmer.latestPrediction!),
                    const SizedBox(height: 20),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TranslatedText(
                              'No crop predictions available yet',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Contact Section
                  if (farmer.phoneVisible && !isCurrentUser) ...[
                    _buildSectionTitle('📱 Contact'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onCall,
                            icon: const Icon(Icons.phone, size: 18),
                            label: const TranslatedText('Call'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D5016),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onMessage,
                            icon: const Icon(Icons.message, size: 18),
                            label: const TranslatedText('Message'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2D5016),
                              side: const BorderSide(
                                color: Color(0xFF2D5016),
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ] else if (!farmer.phoneVisible && !isCurrentUser) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TranslatedText(
                              'Contact details not shared',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Follow Button
                  if (!isCurrentUser)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onToggleFollow,
                        icon: Icon(
                          farmer.isFollowing
                              ? Icons.person_remove
                              : Icons.person_add,
                          size: 20,
                        ),
                        label: TranslatedText(
                          farmer.isFollowing ? 'Unfollow' : 'Follow Farmer',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: farmer.isFollowing
                              ? Colors.grey[400]
                              : const Color(0xFF2D5016),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              TranslatedText(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D5016),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return TranslatedText(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D5016),
      ),
    );
  }

  Widget _buildAlertCard(String alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TranslatedText(
              alert,
              style: TextStyle(fontSize: 13, color: Colors.orange[900]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(CropPredictionData prediction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D5016).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildPredictionRow(
            'Yield',
            '${prediction.estimatedYield} tons/acre',
          ),
          const Divider(height: 20),
          _buildPredictionRow('Growth Phase', prediction.growthPhase),
          const Divider(height: 20),
          _buildPredictionRow('Weather Risk', prediction.weatherRisk),
          const Divider(height: 20),
          _buildPredictionRow(
            'Prediction Date',
            DateFormat('MMM dd, yyyy').format(prediction.predictionDate),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TranslatedText(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        TranslatedText(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D5016),
          ),
        ),
      ],
    );
  }

  Color _getSoilHealthColor(String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
