import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 通用条款 / 政策展示页
/// 通过 [sections] 传入若干 (标题, 段落列表) 段
class LegalPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<({String heading, List<String> paragraphs})> sections;
  final DateTime? updatedAt;

  const LegalPage({
    super.key,
    required this.title,
    required this.sections,
    this.subtitle,
    this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        titleTextStyle: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            if (subtitle != null) ...[
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (updatedAt != null) ...[
              Text(
                '更新日期：${_fmtDate(updatedAt!)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
            ] else
              const SizedBox(height: 20),
            for (final s in sections) ...[
              Text(
                s.heading,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              for (final p in s.paragraphs) ...[
                Text(
                  p,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}
