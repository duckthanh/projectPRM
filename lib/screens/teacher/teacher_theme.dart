import 'package:flutter/material.dart';

/// Màu và style đồng bộ Teacher Webapp.
class TeacherTheme {
  static const Color primary = Color(0xFF1E75F6);
  static const Color primarySoft = Color(0xFF5C79E0);
  static const Color sidebar = Color(0xFF11224F);
  static const Color sidebarAlt = Color(0xFF1B3778);
  static const Color bg = Color(0xFFEEF4FF);
  static const Color text = Color(0xFF172033);
  static const Color muted = Color(0xFF667085);
  static const Color cardShadow = Color(0x14263A7C);
  static const Color border = Color(0xFFD8E1F4);
  static const Color excellent = Color(0xFF12B76A);
  static const Color good = Color(0xFF2E90FA);
  static const Color average = Color(0xFFF79009);
  static const Color weak = Color(0xFFF04438);
  static const Color pending = Color(0xFFF79009);

  static BoxDecoration cardDecoration({double radius = 20}) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14263A7C),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      );

  static InputDecoration fieldDecoration({
    required String label,
    IconData? icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: primary) : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(fontWeight: FontWeight.w700),
  );

  static Widget pageHeader({
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: muted, height: 1.4),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  static Widget miniStat({
    required String label,
    required String value,
    Color color = primary,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: cardDecoration(radius: 16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: muted),
            ),
          ],
        ),
      ),
    );
  }

  static Color levelColor(double avg) {
    if (avg >= 8.5) return excellent;
    if (avg >= 7.0) return good;
    if (avg >= 5.0) return average;
    return weak;
  }

  static String levelLabel(double avg) {
    if (avg >= 8.5) return 'Giỏi';
    if (avg >= 7.0) return 'Khá';
    if (avg >= 5.0) return 'TB';
    return 'Yếu';
  }

  static Widget levelBadge(double avg) {
    final color = levelColor(avg);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        levelLabel(avg),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
