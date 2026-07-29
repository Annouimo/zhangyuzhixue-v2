import 'dart:convert';

import 'app_prefs.dart';

class ContributionDraftStore {
  ContributionDraftStore({AppPrefs? prefs}) : _prefs = prefs ?? AppPrefs();

  static const _indexKey = 'contribution_draft_index_v1';
  static const _prefix = 'contribution_draft_v1_';
  final AppPrefs _prefs;

  List<Map<String, dynamic>> list() {
    final raw = _prefs.getString(_indexKey);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList()
        ..sort((a, b) => '${b['updated_at']}'.compareTo('${a['updated_at']}'));
    } catch (_) {
      return const [];
    }
  }

  Map<String, dynamic>? read(String id) {
    final raw = _prefs.getString('$_prefix$id');
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String id, Map<String, dynamic> draft) async {
    final now = DateTime.now().toIso8601String();
    final value = {...draft, 'draft_id': id, 'updated_at': now};
    await _prefs.p.setString('$_prefix$id', jsonEncode(value));
    final items = list().where((item) => item['draft_id'] != id).toList();
    items.add({
      'draft_id': id,
      'updated_at': now,
      'mode': draft['mode'],
      'summary': draft['summary'] ?? '',
    });
    await _prefs.p.setString(_indexKey, jsonEncode(items));
  }

  Future<void> remove(String id) async {
    await _prefs.p.remove('$_prefix$id');
    final items = list().where((item) => item['draft_id'] != id).toList();
    await _prefs.p.setString(_indexKey, jsonEncode(items));
  }
}
