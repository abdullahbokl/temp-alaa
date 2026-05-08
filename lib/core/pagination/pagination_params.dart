class PaginationParams {
  final int page;
  final int limit;
  final int? offset;

  const PaginationParams({
    this.page = 1,
    this.limit = 10,
    this.offset,
  });

  Map<String, dynamic> toPerPageMap() {
    return {
      'page': page,
      'per_page': limit,
    };
  }

  Map<String, dynamic> toLimitOffsetMap() {
    return {
      'limit': limit,
      'offset': offset ?? (page - 1) * limit,
    };
  }
}
