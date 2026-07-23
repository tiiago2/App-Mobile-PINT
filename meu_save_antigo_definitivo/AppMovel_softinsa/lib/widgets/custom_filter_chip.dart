import 'package:flutter/material.dart';
import '../variaveis/variaveis.dart';

class CustomFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const CustomFilterChip({
    super.key,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 16.0, right: 8.0, top: 8.0, bottom: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? AppCores.azulFundo : AppCores.branco,
          borderRadius: BorderRadius.circular(AppBorders.pilulas),
          border: isSelected
              ? null
              : Border.all(color: AppCores.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppCores.branco : AppCores.fontes,
                fontSize: 14.0,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppCores.branco.withOpacity(0.2)
                    : AppCores.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppBorders.padrao),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? AppCores.branco : AppCores.fontes,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
