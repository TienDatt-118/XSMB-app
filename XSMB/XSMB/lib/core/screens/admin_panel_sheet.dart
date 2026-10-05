import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../theme/app_theme.dart';

class AdminPanelSheet extends StatelessWidget {
  const AdminPanelSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '⚙️ BẢNG ĐIỀU KHIỂN ADMIN',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.red, size: 20),
                    onPressed: () {
                      provider.logoutAdmin();
                      Navigator.pop(context);
                    },
                    tooltip: 'Đăng xuất Admin',
                  ),
                ],
              ),
              const Divider(height: 16),
              
              const Text(
                'Kích hoạt các lệnh Artisan chạy ngầm trên máy chủ Laravel:',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Command list
              _buildCmdButton(
                context,
                provider,
                title: 'Chạy Live Watch (xsmb:live-watch)',
                sub: 'Giám sát và cào kết quả trực tiếp thời gian thực.',
                cmd: 'xsmb:live-watch',
                icon: Icons.live_tv,
              ),
              const SizedBox(height: 8),
              _buildCmdButton(
                context,
                provider,
                title: 'Cào hôm nay (crawl:today)',
                sub: 'Cào ngay lập tức kết quả của ngày hôm nay.',
                cmd: 'crawl:today',
                icon: Icons.download_rounded,
              ),
              const SizedBox(height: 8),
              _buildCmdButton(
                context,
                provider,
                title: 'Tính toán thống kê (stat:calculate)',
                sub: 'Cập nhật lại tần suất, lô gan, đầu đuôi.',
                cmd: 'stat:calculate',
                icon: Icons.calculate_outlined,
              ),
              const SizedBox(height: 8),
              _buildCmdButton(
                context,
                provider,
                title: 'Trích xuất Phân Tích (xsmb:extract-analysis)',
                sub: 'Trích xuất ma trận số, gợi ý và bộ số.',
                cmd: 'xsmb:extract-analysis',
                icon: Icons.analytics_outlined,
              ),
              
              const SizedBox(height: 20),

              // Status console log
              if (provider.executionMessage.isNotEmpty) ...[
                const Text(
                  'Phản hồi từ Laravel server:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black38 : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      if (provider.isExecuting) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryRed),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          provider.executionMessage,
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: provider.isExecuting
                                ? Colors.grey
                                : (provider.executionMessage.contains('Lỗi') ? Colors.red : Colors.green),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              ElevatedButton(
                onPressed: provider.isExecuting ? null : () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Đóng'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCmdButton(
    BuildContext context,
    AdminProvider provider, {
    required String title,
    required String sub,
    required String cmd,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: provider.isExecuting ? null : () => provider.runCommand(cmd),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryRed, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
