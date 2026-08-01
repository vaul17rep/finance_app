/// Вычисленное финансовое состояние.
///
/// Не хранится в БД, вычисляется на лету из операций.
///
/// Связанные документы:
/// - 03_Domain_Model — FinancialState
/// - 04_Financial_Rules — расчёт состояния

/// Вычисленное финансовое состояние.
///
/// Не хранится в БД, вычисляется на лету из операций.
class FinancialState {
  final double balance;
  final double income;
  final double expenses;

  /// Сумма переводов между счетами.
  final double transfers;

  FinancialState({
    required this.balance,
    required this.income,
    required this.expenses,
    this.transfers = 0,
  });

  double get profit => income - expenses;
}
