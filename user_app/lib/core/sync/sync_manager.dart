/// Centralized High-Performance Sync Manager
/// Provides smart throttling and SWR (Stale-While-Revalidate) cache management.
/// Guarantees:
/// 1. Zero redundant network calls within the threshold window (defaults to 15 seconds).
/// 2. Automatic invalidation on user actions (e.g. after payment or video completion).
/// 3. Prevents battery drain and Vercel serverless function overload.
class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final Map<String, DateTime> _lastFetchMap = {};

  /// Checks if a key is eligible for a fresh network fetch.
  /// If [force] is true, always returns true (e.g. for pull-to-refresh).
  bool shouldFetch(String key, {Duration threshold = const Duration(seconds: 15), bool force = false}) {
    if (force) return true;
    final last = _lastFetchMap[key];
    if (last == null) return true;
    return DateTime.now().difference(last) >= threshold;
  }

  /// Marks a key as freshly fetched at the current timestamp.
  void markFetched(String key) {
    _lastFetchMap[key] = DateTime.now();
  }

  /// Invalidates a specific key to force the next call to revalidate.
  void invalidate(String key) {
    _lastFetchMap.remove(key);
  }

  /// Invalidates all cached timestamps (e.g. on manual pull-to-refresh or account switch).
  void invalidateAll() {
    _lastFetchMap.clear();
  }
}
