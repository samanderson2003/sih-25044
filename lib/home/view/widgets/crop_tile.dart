import 'package:flutter/material.dart';
import '../../model/crop_model.dart';

class CropTile extends StatelessWidget {
  final Crop crop;
  final bool isSelected;
  final VoidCallback onTap;

  const CropTile({
    super.key,
    required this.crop,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        decoration: BoxDecoration(
          color: isSelected ? crop.themeColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? crop.themeColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: crop.themeColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(crop.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              crop.name,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF2D5016),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
