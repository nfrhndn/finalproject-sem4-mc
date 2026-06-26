import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local data source for managing search history
abstract class SearchLocalDataSource {
  /// Get recent search queries
  Future<List<String>> getRecentSearches();

  /// Add a search query to recent searches
  Future<void> addRecentSearch(String query);

  /// Remove a specific search query
  Future<void> removeRecentSearch(String query);

  /// Clear all recent searches
  Future<void> clearRecentSearches();
}

/// Implementation of SearchLocalDataSource using SharedPreferences
class SearchLocalDataSourceImpl implements SearchLocalDataSource {
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 4;

  @override
  Future<List<String>> getRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searchesJson = prefs.getString(_recentSearchesKey);
      if (searchesJson == null) return [];

      final List<dynamic> decoded = json.decode(searchesJson);
      final List<String> searches = decoded.cast<String>();

      // Limit to max items (in case old data has more)
      if (searches.length > _maxRecentSearches) {
        return searches.sublist(0, _maxRecentSearches);
      }
      return searches;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> addRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = await getRecentSearches();

      // Remove if already exists to move it to top
      searches.remove(query);

      // Add to beginning
      searches.insert(0, query);

      // Keep only max items
      if (searches.length > _maxRecentSearches) {
        searches.removeRange(_maxRecentSearches, searches.length);
      }

      await prefs.setString(_recentSearchesKey, json.encode(searches));
    } catch (_) {
      // Silently fail
    }
  }

  @override
  Future<void> removeRecentSearch(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = await getRecentSearches();

      searches.remove(query);

      await prefs.setString(_recentSearchesKey, json.encode(searches));
    } catch (_) {
      // Silently fail
    }
  }

  @override
  Future<void> clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);
    } catch (_) {
      // Silently fail
    }
  }
}
