import 'paginated_list.dart';

class PaginationParser {
  const PaginationParser._();

  static PaginatedList<T> parse<T>({
    required dynamic responseData,
    required List<T> Function(List<dynamic> rawItems) mapItems,
    required int requestedPage,
    required int requestedLimit,
  }) {
    final data = responseData is Map<String, dynamic> ? responseData : <String, dynamic>{};

    final rootData = data['data'];
    final List<dynamic> rawItems;
    int page = requestedPage;
    int limit = requestedLimit;
    int? total;
    bool hasMore;

    if (rootData is Map<String, dynamic> && rootData['data'] is List) {
      rawItems = rootData['data'] as List<dynamic>;
      final meta = rootData['meta'] is Map<String, dynamic>
          ? rootData['meta'] as Map<String, dynamic>
          : (data['meta'] is Map<String, dynamic> ? data['meta'] as Map<String, dynamic> : null);
      final links = rootData['links'] is Map<String, dynamic>
          ? rootData['links'] as Map<String, dynamic>
          : (data['links'] is Map<String, dynamic> ? data['links'] as Map<String, dynamic> : null);

      page = _readInt(meta?['current_page']) ?? _readInt(rootData['current_page']) ?? requestedPage;
      limit = _readInt(meta?['per_page']) ?? _readInt(rootData['per_page']) ?? requestedLimit;
      total = _readInt(meta?['total']) ?? _readInt(rootData['total']);
      final nextPageUrl = meta?['next_page_url'] ?? links?['next'] ?? rootData['next_page_url'];
      hasMore = _resolveHasMore(rawItems.length, limit, page, total, nextPageUrl);
    } else if (rootData is List) {
      rawItems = rootData.cast<dynamic>();
      final meta = data['meta'] is Map<String, dynamic> ? data['meta'] as Map<String, dynamic> : null;
      final links = data['links'] is Map<String, dynamic> ? data['links'] as Map<String, dynamic> : null;
      page = _readInt(meta?['current_page']) ?? requestedPage;
      limit = _readInt(meta?['per_page']) ?? requestedLimit;
      total = _readInt(meta?['total']);
      final nextPageUrl = meta?['next_page_url'] ?? links?['next'];
      hasMore = _resolveHasMore(rawItems.length, limit, page, total, nextPageUrl);
    } else if (data['courses'] is List) {
      rawItems = (data['courses'] as List).cast<dynamic>();
      hasMore = rawItems.length >= requestedLimit;
    } else if (responseData is List) {
      rawItems = responseData.cast<dynamic>();
      hasMore = rawItems.length >= requestedLimit;
    } else {
      rawItems = const <dynamic>[];
      hasMore = false;
    }

    return PaginatedList<T>(
      items: mapItems(rawItems),
      page: page,
      limit: limit,
      hasMore: hasMore,
      total: total,
    );
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool _resolveHasMore(
    int itemCount,
    int limit,
    int page,
    int? total,
    dynamic nextPageUrl,
  ) {
    if (nextPageUrl != null && nextPageUrl.toString().isNotEmpty) return true;
    if (total != null) return page * limit < total;
    return itemCount >= limit;
  }
}
