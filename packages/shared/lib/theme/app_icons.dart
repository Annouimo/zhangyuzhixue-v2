import 'package:flutter/material.dart';

/// 章鱼智学 V1.0 图标令牌 — 主导航与通用操作
///
/// 分离图标引用便于后续支持 SVG 或自定义图标字体替换。
abstract final class AppIcons {
  // ── 主导航 ──
  static const IconData home = Icons.home_outlined;
  static const IconData homeSelected = Icons.home;

  static const IconData recommendation = Icons.auto_awesome_outlined;
  static const IconData recommendationSelected = Icons.auto_awesome;

  static const IconData learning = Icons.school_outlined;
  static const IconData learningSelected = Icons.school;

  static const IconData exam = Icons.description_outlined;
  static const IconData examSelected = Icons.description;

  static const IconData profile = Icons.person_outline;
  static const IconData profileSelected = Icons.person;

  // ── 通用操作 ──
  static const IconData back = Icons.arrow_back_ios_new;
  static const IconData close = Icons.close;
  static const IconData more = Icons.more_vert;
  static const IconData search = Icons.search;
  static const IconData settings = Icons.settings_outlined;
  static const IconData refresh = Icons.refresh;
  static const IconData share = Icons.share_outlined;
  static const IconData favorite = Icons.favorite_outline;
  static const IconData favoriteFilled = Icons.favorite;
  static const IconData like = Icons.favorite_outline;
  static const IconData likeSelected = Icons.favorite;
  static const IconData bookmark = Icons.bookmark_outline;
  static const IconData bookmarkFilled = Icons.bookmark;
  static const IconData info = Icons.info_outline;
  static const IconData error = Icons.error_outline;
  static const IconData warning = Icons.warning_amber_outlined;
  static const IconData success = Icons.check_circle_outline;
  static const IconData sync = Icons.sync;
  static const IconData download = Icons.download_outlined;
  static const IconData upload = Icons.upload_outlined;
  static const IconData filter = Icons.filter_list;
  static const IconData sort = Icons.sort;
  static const IconData add = Icons.add;
  static const IconData edit = Icons.edit_outlined;
  static const IconData delete = Icons.delete_outline;
  static const IconData check = Icons.check;
  static const IconData chevronRight = Icons.chevron_right;
  static const IconData arrowForward = Icons.arrow_forward;
  static const IconData chevronLeft = Icons.chevron_left;
  static const IconData expandMore = Icons.expand_more;
  static const IconData expandLess = Icons.expand_less;
}
