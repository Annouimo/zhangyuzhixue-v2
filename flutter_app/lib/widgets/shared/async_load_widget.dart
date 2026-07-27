import 'package:flutter/material.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/error_placeholder.dart';
import 'package:shared/widgets/empty_placeholder.dart';

/// 泛型异步加载组件 — 统一处理 loading / error / empty / RefreshIndicator
///
/// 替代每个页面中的 ~55 行重复模板（_loading/_error/_list + _load + 三态 build）
///
/// 用法：
/// ```dart
/// AsyncLoadWidget<List<Item>>(
///   onLoad: () => _repo.getPending(),
///   builder: (ctx, list) => ListView.builder(
///     itemCount: list.length,
///     itemBuilder: (_, i) => ItemTile(...),
///   ),
///   emptyWidget: EmptyPlaceholder(icon: Icons.assignment, message: '暂无'),
/// )
/// ```
class AsyncLoadWidget<T> extends StatefulWidget {
  /// 异步数据源
  final Future<T> Function() onLoad;

  /// 数据就绪后的 UI 构建函数
  final Widget Function(BuildContext context, T data) builder;

  /// 空状态 Widget（默认 EmptyPlaceholder）
  final Widget? emptyWidget;

  /// null ≠ 空时显示的 Widget（默认 null，即显示 emptyWidget）
  /// 当数据不为 null 但 isEmpty（针对 List/Set/Map/String）时使用
  final Widget? Function(T data)? emptyWidgetBuilder;

  /// 是否启用下拉刷新（默认 true）
  final bool pullToRefresh;

  /// 首屏是否显示 loading 指示器（默认 true）
  final bool showLoadingOnInit;

  /// builder 返回的内容内部是否已经包含滚动视图。
  final bool contentIsScrollable;

  /// 错误提示文案（默认 "加载失败，请稍后重试"）
  final String errorMessage;

  /// 加载中提示文案
  final String? loadingMessage;

  const AsyncLoadWidget({
    super.key,
    required this.onLoad,
    required this.builder,
    this.emptyWidget,
    this.emptyWidgetBuilder,
    this.pullToRefresh = true,
    this.showLoadingOnInit = true,
    this.contentIsScrollable = false,
    this.errorMessage = '加载失败，请稍后重试',
    this.loadingMessage,
  });

  @override
  State<AsyncLoadWidget<T>> createState() => AsyncLoadWidgetState<T>();
}

class AsyncLoadWidgetState<T> extends State<AsyncLoadWidget<T>> {
  bool _loading = false;
  String? _error;
  T? _data;
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    if (widget.showLoadingOnInit) {
      _loading = true;
    }
    _load();
  }

  /// 公开刷新方法，供外部（如 MainShell）调用
  void refresh() => _load();

  /// 乐观更新：在异步操作完成前就地修改当前数据
  ///
  /// [update] 接收当前数据列表，返回修改后的新列表。
  /// 操作完成后建议调用 [refresh()] 与服务端同步。
  void optimisticUpdate(T Function(T data) update) {
    if (_data == null || !_initialLoadDone) return;
    setState(() {
      _data = update(_data as T);
    });
  }

  Future<void> _load() async {
    setState(() {
      if (!_initialLoadDone && widget.showLoadingOnInit) {
        _loading = true;
      } else {
        _loading = true;
      }
      _error = null;
    });
    try {
      final data = await widget.onLoad();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
        _initialLoadDone = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = widget.errorMessage;
        _loading = false;
        _initialLoadDone = true;
      });
    }
  }

  /// 检查数据是否为空（支持 List/Set/Map/String/null）
  bool _isEmpty(T? data) {
    if (data == null) return true;
    if (data is List) return data.isEmpty;
    if (data is Set) return data.isEmpty;
    if (data is Map) return data.isEmpty;
    if (data is String) return data.isEmpty;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return LoadingIndicator(message: widget.loadingMessage);
    }

    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }

    // 空状态处理
    if (_isEmpty(_data)) {
      // 优先使用 emptyWidgetBuilder
      if (widget.emptyWidgetBuilder != null) {
        final customEmpty = widget.emptyWidgetBuilder!(_data as T);
        if (customEmpty != null) return customEmpty;
      }
      return widget.emptyWidget ??
          EmptyPlaceholder(icon: Icons.inbox_outlined, message: '暂无内容');
    }

    // 数据就绪 → 构建 UI
    final content = widget.builder(context, _data as T);

    if (widget.pullToRefresh) {
      // 需要让 RefreshIndicator 能滚动，所以必须包裹可滚动的 child
      // 如果 builder 已经返回了 Scrollable，直接包 RefreshIndicator
      // 否则包一层 SingleChildScrollView
      if (widget.contentIsScrollable ||
          content is Scrollable ||
          _isScrollView(content)) {
        return RefreshIndicator(onRefresh: _load, child: content);
      }
      return RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: content,
        ),
      );
    }

    return content;
  }

  bool _isScrollView(Widget w) {
    return w is ListView ||
        w is GridView ||
        w is CustomScrollView ||
        w is SingleChildScrollView ||
        w is NestedScrollView ||
        w is PageView;
  }
}
