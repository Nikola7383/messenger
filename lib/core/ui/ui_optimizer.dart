import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class UIOptimizer {
  // Minimalno vreme između UI update-a (ms)
  static const int minUpdateInterval = 16; // ~60fps
  
  // Maksimalan broj item-a po stranici
  static const int maxItemsPerPage = 20;
  
  // Threshold za infinite scroll
  static const double scrollThreshold = 0.8;
  
  // Debounce timeri
  static final Map<String, Timer> _debounceTimers = {};
  
  // Throttle timestamps
  static final Map<String, DateTime> _throttleTimestamps = {};

  /// Optimizuje rebuild-ove za listu
  static Widget optimizeListView<T>({
    required List<T> items,
    required Widget Function(BuildContext, T) itemBuilder,
    required String listKey,
    ScrollController? controller,
    bool enableInfiniteScroll = false,
    VoidCallback? onLoadMore,
  }) {
    return ListView.builder(
      key: Key(listKey),
      controller: controller,
      itemCount: items.length,
      itemBuilder: (context, index) {
        // Proveri da li treba učitati još
        if (enableInfiniteScroll &&
            index == items.length - 1 &&
            controller != null) {
          final position = controller.position;
          final maxScroll = position.maxScrollExtent;
          final currentScroll = position.pixels;
          
          if (currentScroll >= maxScroll * scrollThreshold) {
            onLoadMore?.call();
          }
        }

        // Optimizuj item build
        return _OptimizedListItem(
          key: ValueKey('${listKey}_$index'),
          child: itemBuilder(context, items[index]),
        );
      },
    );
  }

  /// Optimizuje grid prikaz
  static Widget optimizeGridView<T>({
    required List<T> items,
    required Widget Function(BuildContext, T) itemBuilder,
    required String gridKey,
    required int crossAxisCount,
    ScrollController? controller,
    bool enableInfiniteScroll = false,
    VoidCallback? onLoadMore,
  }) {
    return GridView.builder(
      key: Key(gridKey),
      controller: controller,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        // Proveri da li treba učitati još
        if (enableInfiniteScroll &&
            index == items.length - 1 &&
            controller != null) {
          final position = controller.position;
          final maxScroll = position.maxScrollExtent;
          final currentScroll = position.pixels;
          
          if (currentScroll >= maxScroll * scrollThreshold) {
            onLoadMore?.call();
          }
        }

        // Optimizuj item build
        return _OptimizedGridItem(
          key: ValueKey('${gridKey}_$index'),
          child: itemBuilder(context, items[index]),
        );
      },
    );
  }

  /// Debounce funkcija za UI update-e
  static void debounce(
    String key,
    VoidCallback action, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    if (_debounceTimers.containsKey(key)) {
      _debounceTimers[key]?.cancel();
    }

    _debounceTimers[key] = Timer(duration, action);
  }

  /// Throttle funkcija za UI update-e
  static void throttle(
    String key,
    VoidCallback action, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final now = DateTime.now();
    if (!_throttleTimestamps.containsKey(key) ||
        now.difference(_throttleTimestamps[key]!) > duration) {
      action();
      _throttleTimestamps[key] = now;
    }
  }

  /// Optimizuje animacije
  static void optimizeAnimation(
    TickerProvider vsync,
    AnimationController controller,
  ) {
    // Prilagodi frame rate based on device capabilities
    final deviceFrameRate = SchedulerBinding.instance.schedulerPhase == 
      SchedulerPhase.idle ? 60 : 30;
    
    controller.duration = Duration(
      milliseconds: (controller.duration?.inMilliseconds ?? 300) * 
        (60 / deviceFrameRate).round(),
    );
  }

  /// Optimizuje image loading
  static Widget optimizeImage(
    String imageUrl, {
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }

  /// Čisti sve timere
  static void dispose() {
    _debounceTimers.forEach((_, timer) => timer.cancel());
    _debounceTimers.clear();
    _throttleTimestamps.clear();
  }
}

/// Optimizovani list item koji sprečava nepotrebne rebuild-ove
class _OptimizedListItem extends StatelessWidget {
  final Widget child;

  const _OptimizedListItem({
    required Key key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child,
    );
  }
}

/// Optimizovani grid item koji sprečava nepotrebne rebuild-ove
class _OptimizedGridItem extends StatelessWidget {
  final Widget child;

  const _OptimizedGridItem({
    required Key key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child,
    );
  }
} 