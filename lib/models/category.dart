enum CategoryType {
  food,
  transport,
  home,
  health,
  entertainment,
  salary,
  education,
  other,
}

class Category {
  final String id;

  final String name;

  final CategoryType type;

  final bool isIncome;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.isIncome,
  });

  static const food = Category(
    id: 'food',
    name: 'Продукты',
    type: CategoryType.food,
    isIncome: false,
  );

  static const transport = Category(
    id: 'transport',
    name: 'Транспорт',
    type: CategoryType.transport,
    isIncome: false,
  );

  static const salary = Category(
    id: 'salary',
    name: 'Зарплата',
    type: CategoryType.salary,
    isIncome: true,
  );

  static const other = Category(
    id: 'other',
    name: 'Другое',
    type: CategoryType.other,
    isIncome: false,
  );
}
