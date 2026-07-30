class SearchTestCase {
  final String query;

  /// Проверка содержимого результата
  final String? expectedContentSubstring;

  /// Проверка типа источника (obsidian, receipt, operation и т.д.)
  final String? sourceType;

  /// Дополнительная кастомная проверка результата
  final bool Function(dynamic result)? validator;

  const SearchTestCase({
    required this.query,
    this.expectedContentSubstring,
    this.sourceType,
    this.validator,
  });
}

final List<SearchTestCase> searchTestCases = [
  const SearchTestCase(query: 'молоко', expectedContentSubstring: 'молоко'),

  const SearchTestCase(query: 'кефир', expectedContentSubstring: 'кефир'),

  const SearchTestCase(query: 'овощи', expectedContentSubstring: 'помидор'),

  const SearchTestCase(
    query: 'пятерочка',
    expectedContentSubstring: 'Пятёрочка',
  ),

  SearchTestCase(
    query: 'вчера',
    validator: (result) {
      final yesterday = DateTime.now()
          .subtract(const Duration(days: 1))
          .day
          .toString();

      return result.content.contains(yesterday);
    },
  ),

  SearchTestCase(
    query: 'дороже 1000',
    validator: (result) {
      // Проверка суммы будет реализована после добавления
      // финансовых фильтров в SearchResult
      return true;
    },
  ),

  const SearchTestCase(query: 'зарплата', sourceType: 'operation'),

  const SearchTestCase(query: 'планы', sourceType: 'obsidian'),

  const SearchTestCase(
    query: 'идея приложения',
    expectedContentSubstring: 'приложение',
    sourceType: 'obsidian',
  ),

  const SearchTestCase(
    query: 'покупка',
    expectedContentSubstring: 'куп',
    sourceType: 'receipt',
  ),

  const SearchTestCase(query: 'еда', expectedContentSubstring: 'еда'),
];
