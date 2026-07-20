import '../database/database_helper.dart';
import '../models/account.dart';

class AccountRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Account>> getAccounts() async {
    final data = await _dbHelper.getAccounts();

    return data.map((json) => Account.fromMap(json)).toList();
  }

  Future<void> insertAccount(Account account) async {
    await _dbHelper.insertAccount(account.toMap());
  }

  Future<void> updateAccount(Account account) async {
    await _dbHelper.updateAccount(account);
  }

  Future<void> deleteAccount(String id) async {
    final accounts = await getAccounts();

    final account = accounts.firstWhere((a) => a.id == id);

    if (account.isMain) {
      throw Exception('Нельзя удалить основной счёт');
    }

    await _dbHelper.deleteAccount(id);
  }

  Future<void> setMainAccount(String id) async {
    final accounts = await getAccounts();

    for (final account in accounts) {
      if (account.isMain) {
        await updateAccount(account.copyWith(isMain: false));
      }
    }

    final selected = accounts.firstWhere((account) => account.id == id);

    await updateAccount(selected.copyWith(isMain: true));
  }

  Future<Account?> getMainAccount() async {
    final accounts = await getAccounts();

    try {
      return accounts.firstWhere((account) => account.isMain);
    } catch (_) {
      return null;
    }
  }
}
