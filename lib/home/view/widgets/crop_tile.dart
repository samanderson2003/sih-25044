import 'package:flutter/material.dart';
import '../../model/crop_model.dart';
import '../../../widgets/translated_text.dart';

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
        duration: const Duration(milliseconds: 250),
        width: 100,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    crop.themeColor.withOpacity(0.25),
                    crop.themeColor.withOpacity(0.15),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.white,
                    const Color(0xFFFFFDE7).withOpacity(0.3),
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? crop.themeColor.withOpacity(0.5)
                : const Color(0xFFD0D0D0).withOpacity(0.6),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: crop.themeColor.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              crop.icon,
              style: TextStyle(
                fontSize: 36,
                shadows: isSelected
                    ? [
                        Shadow(
                          color: Colors.black.withOpacity(0.1),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            TranslatedText(
              crop.name,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF2D5016),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
