import 'package:flutter/material.dart';
import 'package:uicons/uicons.dart';
import '../variaveis/variaveis.dart';
import '../idiomas/app_localizations.dart';
import '../pages/badge_detalhe.dart';

enum BadgeCardStatus {
  aprovado,
  pendente,
  emProgresso,
  recusado,
  expirado,
}

class BadgeCard extends StatelessWidget {
  final String title;
  final String category;
  final int points;
  final IconData icon;
  final Color avatarColor;
  final BadgeCardStatus status;
  final DateTime? date;
  final int? progressPercentage;
  final String? alertMessage;

  const BadgeCard({
    super.key,
    required this.title,
    required this.category,
    required this.points,
    required this.icon,
    required this.avatarColor,
    required this.status,
    this.date,
    this.progressPercentage,
    this.alertMessage,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Map<String, dynamic> _getStatusConfig(AppLocalizations l10n) {
    switch (status) {
      case BadgeCardStatus.aprovado:
        return {
          'color': const Color(0xFF00A36C), // Green
          'icon': UIcons.boldRounded.check,
          'text': l10n.aprovado,
          'detail': date != null ? '${l10n.aprovado}: ${_formatDate(date!)}' : null,
        };
      case BadgeCardStatus.pendente:
        return {
          'color': const Color(0xFFF59E0B), // Orange
          'icon': UIcons.boldRounded.time_past,
          'text': l10n.pendente,
          'detail': date != null ? '${l10n.pendente}: ${_formatDate(date!)}' : null,
        };
      case BadgeCardStatus.emProgresso:
        return {
          'color': AppCores.azulFundo, // Blue
          'icon': UIcons.boldRounded.calendar,
          'text': l10n.emProgresso,
          'detail': progressPercentage != null ? '$progressPercentage% ${l10n.completo}' : null,
        };
      case BadgeCardStatus.recusado:
        return {
          'color': const Color(0xFFEF4444), // Red
          'icon': UIcons.boldRounded.cross,
          'text': l10n.recusado,
          'detail': date != null ? '${l10n.recusado}: ${_formatDate(date!)}' : null,
        };
      case BadgeCardStatus.expirado:
        return {
          'color': const Color(0xFFC62828), // Darker Red for expired
          'icon': UIcons.boldRounded.time_past,
          'text': l10n.expirado,
          'detail': date != null ? '${l10n.expirado}: ${_formatDate(date!)}' : null,
          'detailColor': const Color(0xFFC62828), // Detail text is red as per image
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = _getStatusConfig(l10n);

    final badgeMap = {
      'titulo': title,
      'categoria': category,
      'pontos': points,
      'icon': icon,
      'avatarColor': avatarColor,
      'estado': status.name,
      'progresso': progressPercentage ?? 0,
      'descricao': '',
    };

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BadgeDetalheScreen(badge: badgeMap),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppCores.branco,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppCores.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Circle Icon Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: avatarColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: avatarColor,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppCores.fontes,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppCores.fontes.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Points Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppCores.azulFundo,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        UIcons.boldRounded.graduation_cap,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$points pts',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: config['color'],
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        config['icon'],
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        config['text'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Detail Text (Progress or Date)
                if (config['detail'] != null)
                  Text(
                    config['detail'],
                    style: TextStyle(
                      fontSize: 12,
                      color: config['detailColor'] ?? AppCores.fontes.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            if (alertMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE8E8), // Light red background
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      UIcons.boldRounded.exclamation,
                      color: Color(0xFFC62828),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alertMessage!,
                        style: const TextStyle(
                          color: Color(0xFFC62828),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
