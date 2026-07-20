class CategoryService {
  static String getName(String? id) {
    switch (id) {
      case 'food':
        return 'Продукты';

      case 'transport':
        return 'Транспорт';

      case 'home':
        return 'Дом';

      case 'health':
        return 'Здоровье';

      case 'entertainment':
        return 'Развлечения';

      case 'salary':
        return 'Зарплата';

      case 'education':
        return 'Образование';

      case 'other':
        return 'Другое';

      default:
        return 'Без категории';
    }
  }
}
