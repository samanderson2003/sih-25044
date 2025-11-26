import 'package:flutter/material.dart';
import '../controller/farm_data_controller.dart';
import '../model/farm_data_model.dart';

class SoilTestCentersScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const SoilTestCentersScreen({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<SoilTestCentersScreen> createState() => _SoilTestCentersScreenState();
}

class _SoilTestCentersScreenState extends State<SoilTestCentersScreen> {
  final _controller = FarmDataController();
  List<SoilTestCenter>? _testCenters;
  bool _isLoading = true;

  static const primaryColor = Color(0xFF2D5016);
  static const backgroundColor = Color(0xFFF8F6F0);
  static const textColor = Color(0xFF4A4A4A);

  @override
  void initState() {
    super.initState();
    _loadTestCenters();
  }

  Future<void> _loadTestCenters() async {
    final centers = await _controller.getNearbyTestCenters(
      widget.latitude,
      widget.longitude,
    );

    setState(() {
      _testCenters = centers;
      _isLoading = false;
    });
  }

  void _makePhoneCall(String phone) {
    // In a real app, use url_launcher package:
    // final Uri launchUri = Uri(scheme: 'tel', path: phone);
    // await launchUrl(launchUri);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Calling $phone...')));
  }

  void _openMaps(double lat, double lng) {
    // In a real app, use url_launcher or maps_launcher package
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening in maps...')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Nearby Soil Test Centers'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _testCenters == null || _testCenters!.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                Container(
                  color: primaryColor,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Visit any center below to get accurate soil test',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _testCenters!.length,
                    itemBuilder: (context, index) {
                      final center = _testCenters![index];
                      return _buildCenterCard(center);
                    },
                  ),
                ),
                _buildBottomButton(),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: textColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No test centers found nearby',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can manually enter soil data or use satellite estimates',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterCard(SoilTestCenter center) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.science, color: primaryColor, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        center.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: textColor.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${center.distance.toStringAsFixed(1)} km away',
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Address
            _buildInfoRow(Icons.place_outlined, center.address),

            // Phone
            if (center.phone != null)
              _buildInfoRow(Icons.phone_outlined, center.phone!),

            // Timings
            if (center.timing != null)
              _buildInfoRow(Icons.access_time, center.timing!),
            const SizedBox(height: 12),

            Row(
              children: [
                if (center.phone != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _makePhoneCall(center.phone!),
                      icon: const Icon(Icons.phone),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _openMaps(center.latitude, center.longitude),
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: textColor.withOpacity(0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: BorderSide(color: primaryColor),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Fill Data Later',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
