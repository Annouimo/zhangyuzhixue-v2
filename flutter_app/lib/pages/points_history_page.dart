import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../repositories/user_repository.dart';

/// 积分流水页
class PointsHistoryPage extends StatefulWidget {
  const PointsHistoryPage({super.key});

  @override
  State<PointsHistoryPage> createState() => _PointsHistoryPageState();
}

class _PointsHistoryPageState extends State<PointsHistoryPage> {
  List<Map<String, dynamic>>? _records;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await UserRepository.getPointsHistory();
    setState(() => _records = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('积分流水')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _records == null
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                itemCount: _records!.length,
                itemBuilder: (_, i) {
                  final r = _records![i];
                  final change = r['change'] as int? ?? 0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.paddingMedium),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r['time'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: AppTheme.fontSizeSmall)),
                                const SizedBox(height: 4),
                                Text(r['type'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text(r['note'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: AppTheme.fontSizeSmall)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                change >= 0 ? '+$change' : '$change',
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeTitle,
                                  fontWeight: FontWeight.bold,
                                  color: change >= 0 ? AppTheme.statusGreen : Colors.red,
                                ),
                              ),
                              Text('余额：${r['balance'] ?? 0}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: AppTheme.fontSizeSmall)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
