class PaginatedList<T> {
  final List<T> items;
  final int page;
  final int limit;
  final bool hasMore;
  final int? total;

  const PaginatedList({
    required this.items,
    required this.page,
    required this.limit,
    required this.hasMore,
    this.total,
  });
}
