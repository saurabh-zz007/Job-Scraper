import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class FormattedJobDescription extends StatelessWidget {
  final String description;

  const FormattedJobDescription({super.key, required this.description});

  static String _cleanText(String input) {
    var text = input;
    // Replace common HTML entities
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&rdquo;', '"')
        .replaceAll('&ldquo;', '"')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&gt;', '>')
        .replaceAll('&lt;', '<');

    // Replace <br>, <p> tags if present
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</?p>', caseSensitive: false), '\n');
    return text.trim();
  }

  static bool _isHeader(String line) {
    final lower = line.toLowerCase().trim();
    if (lower.startsWith('### ') || lower.startsWith('## ') || lower.startsWith('# ')) {
      return true;
    }

    // Common job section headers
    final headerKeywords = [
      'about the role',
      'about us',
      'about the company',
      'who we are',
      'about the team',
      'overview',
      'role overview',
      'position summary',
      'responsibilities',
      'what you will do',
      "what you'll do",
      'key responsibilities',
      'core responsibilities',
      'your day-to-day',
      'in this role',
      'requirements',
      'what we are looking for',
      "what we're looking for",
      'qualifications',
      'basic qualifications',
      'minimum qualifications',
      'preferred qualifications',
      'required skills',
      'skills & experience',
      'who you are',
      'nice to have',
      'bonus points',
      'benefits',
      'what we offer',
      'perks',
      'benefits & perks',
      'compensation',
      'salary & benefits',
      'equal opportunity',
      'diversity & inclusion',
    ];

    final stripped = lower.replaceAll(RegExp(r'[:#*]'), '').trim();
    for (final kw in headerKeywords) {
      if (stripped == kw || stripped.startsWith('$kw:') || stripped == '$kw.') {
        return true;
      }
    }

    // Short lines ending in colon with all-caps or title-case (e.g. "Requirements:")
    if (line.endsWith(':') && line.length < 50 && !line.startsWith('http')) {
      return true;
    }

    return false;
  }

  static String _extractHeaderText(String line) {
    return line
        .replaceFirst(RegExp(r'^#+\s*'), '')
        .replaceAll(RegExp(r'[*_:]'), '')
        .trim();
  }

  static IconData _getHeaderIcon(String headerText) {
    final lower = headerText.toLowerCase();
    if (lower.contains('about') || lower.contains('overview') || lower.contains('who we')) {
      return Icons.info_outline_rounded;
    }
    if (lower.contains('responsibilit') || lower.contains('what you') || lower.contains('day-to-day')) {
      return Icons.task_alt_rounded;
    }
    if (lower.contains('require') || lower.contains('qualification') || lower.contains('look') || lower.contains('skills')) {
      return Icons.verified_outlined;
    }
    if (lower.contains('preferred') || lower.contains('nice') || lower.contains('bonus')) {
      return Icons.star_outline_rounded;
    }
    if (lower.contains('benefit') || lower.contains('offer') || lower.contains('perk') || lower.contains('compensation') || lower.contains('salary')) {
      return Icons.card_giftcard_rounded;
    }
    if (lower.contains('equal') || lower.contains('diversity')) {
      return Icons.people_outline_rounded;
    }
    return Icons.label_outline_rounded;
  }

  static bool _isBullet(String line) {
    final trimmed = line.trim();
    if (trimmed.startsWith('•') ||
        trimmed.startsWith('- ') ||
        trimmed.startsWith('* ') ||
        trimmed.startsWith('– ') ||
        trimmed.startsWith('— ') ||
        trimmed.startsWith('o ')) {
      return true;
    }
    // Numbered list: "1. ", "2. ", etc.
    if (RegExp(r'^\d+\.\s+').hasMatch(trimmed)) {
      return true;
    }
    return false;
  }

  static String _extractBulletText(String line) {
    var trimmed = line.trim();
    if (trimmed.startsWith('•')) {
      trimmed = trimmed.substring(1).trim();
    } else if (trimmed.startsWith('- ') ||
        trimmed.startsWith('* ') ||
        trimmed.startsWith('– ') ||
        trimmed.startsWith('— ') ||
        trimmed.startsWith('o ')) {
      trimmed = trimmed.substring(2).trim();
    } else {
      trimmed = trimmed.replaceFirst(RegExp(r'^\d+\.\s+'), '').trim();
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final clean = _cleanText(description);

    if (clean.isEmpty) {
      return const Text(
        'No detailed description provided.',
        style: TextStyle(
          fontSize: 13.5,
          color: AppTheme.textMuted,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final rawLines = clean.split('\n');
    final contentWidgets = <Widget>[];

    String? currentHeader;
    final currentSectionWidgets = <Widget>[];

    void flushSection() {
      if (currentSectionWidgets.isEmpty && currentHeader == null) return;

      if (currentHeader != null) {
        final icon = _getHeaderIcon(currentHeader!);
        contentWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 16, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    currentHeader!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (currentSectionWidgets.isNotEmpty) {
        contentWidgets.addAll(currentSectionWidgets);
        currentSectionWidgets.clear();
      }
      currentHeader = null;
    }

    for (var i = 0; i < rawLines.length; i++) {
      final line = rawLines[i].trim();

      if (line.isEmpty) {
        continue;
      }

      if (_isHeader(line)) {
        flushSection();
        currentHeader = _extractHeaderText(line);
      } else if (_isBullet(line)) {
        final bulletText = _extractBulletText(line);
        currentSectionWidgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 7, right: 10),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    bulletText,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.55,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Regular paragraph text
        currentSectionWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SelectableText(
              line,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }
    }

    flushSection();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contentWidgets,
    );
  }
}

