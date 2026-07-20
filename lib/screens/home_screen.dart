import 'package:flutter/material.dart';

import '../models/operation.dart';
import '../models/operation_type.dart';

import '../domain/services/financial_calculator.dart';
import '../domain/services/financial_service.dart';
import '../domain/entities/financial_state.dart';

import '../repositories/operation_repository.dart';

import 'add_operation_screen.dart';
import 'receipts_screen.dart';
import 'operations_screen.dart';
import '../models/account.dart';
import '../repositories/account_repository.dart';
import 'accounts_screen.dart';
import 'widgets/account_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'account_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final Account? initialAccount;

  const HomeScreen({super.key, this.initialAccount});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _currentPage = 0;
  List<Operation> operations = [];
  final PageController _pageController = PageController(
    viewportFraction: 0.82,
    initialPage: 0,
  );

  final AccountRepository _accountRepository = AccountRepository();

  List<Account> accounts = [];
  Account? selectedAccount;

  final OperationRepository _repository = OperationRepository();

  late final FinancialService _financialService = FinancialService(
    _repository,
    FinancialCalculator(),
  );

  FinancialState? financialState;

  @override
  void initState() {
    super.initState();

    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });

    loadData();
  }

  void onAccountChanged(int index) {
    final account = accounts[index];

    loadAccountState(account);
  }

  Future<void> loadAccountState(Account account) async {
    final loadedOperations = await _repository.getOperationsByAccount(
      account.id,
    );

    final state = await _financialService.getState(accountId: account.id);

    setState(() {
      selectedAccount = account;
      operations = loadedOperations;
      financialState = state;
    });
  }

  Future<void> loadData() async {
    final loadedAccounts = await _accountRepository.getAccounts();

    final updatedAccounts = await Future.wait(
      loadedAccounts.map((account) async {
        final state = await _financialService.getState(accountId: account.id);

        return account.copyWith(balance: state.balance);
      }),
    );
    if (widget.initialAccount != null) {
      final account = loadedAccounts.firstWhere(
        (e) => e.id == widget.initialAccount!.id,
      );

      final loadedOperations = await _repository.getOperationsByAccount(
        account.id,
      );

      final state = await _financialService.getState(accountId: account.id);

      setState(() {
        accounts = updatedAccounts;
        selectedAccount = account;
        operations = loadedOperations;
        financialState = state;
      });

      return;
    }
    final mainAccount = await _accountRepository.getMainAccount();

    if (mainAccount == null) {
      final loadedOperations = await _repository.getOperations();
      final state = await _financialService.getState();

      setState(() {
        accounts = updatedAccounts;
        selectedAccount = null;
        operations = loadedOperations;
        financialState = state;
      });

      return;
    }

    final loadedOperations = await _repository.getOperationsByAccount(
      mainAccount.id,
    );

    final state = await _financialService.getState(accountId: mainAccount.id);

    setState(() {
      accounts = updatedAccounts;
      selectedAccount = mainAccount;
      operations = loadedOperations;
      financialState = state;
    });
  }

  Future<void> loadOperations() async {
    if (selectedAccount != null) {
      await loadAccountState(selectedAccount!);
    } else {
      await loadData();
    }
  }

  Future<void> refresh() async {
    await loadData();
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),

      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.card,
        ),

        child: Column(
          children: [
            Icon(icon, size: 26),

            const SizedBox(height: 6),

            Text(title, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.68;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Finance App',
          style: AppTextStyles.title.copyWith(fontSize: 26, letterSpacing: 1.5),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: refresh,

        child: ListView(
          padding: const EdgeInsets.all(16),

          children: [
            SizedBox(
              height: cardWidth / AccountCard.aspectRatio,

              child: PageView.builder(
                allowImplicitScrolling: true,
                controller: _pageController,
                clipBehavior: Clip.none,
                itemCount: accounts.length + 1,

                padEnds: false,

                pageSnapping: true,

                onPageChanged: (index) {
                  if (index >= accounts.length) return;

                  final account = accounts[index];

                  loadAccountState(account);
                },

                itemBuilder: (context, index) {
                  if (index == accounts.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),

                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.grey.withOpacity(0.25),
                        ),

                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_circle_outline, size: 40),
                              SizedBox(height: 8),
                              Text(
                                "Создать счёт",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final account = accounts[index];

                  return SizedBox(
                    width: cardWidth + 40,

                    child: Align(
                      alignment: Alignment.centerLeft,

                      child: RepaintBoundary(
                        child: AnimatedScale(
                          scale: 1 - ((_currentPage - index).abs() * 0.05),

                          duration: const Duration(milliseconds: 200),

                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AccountDetailsScreen(account: account),
                                ),
                              );
                            },

                            child: AccountCard(
                              account: account,

                              balance: account.id == selectedAccount?.id
                                  ? (financialState?.balance ?? 0)
                                  : account.balance,

                              width: cardWidth,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            Container(height: 1, color: AppColors.divider),

            const SizedBox(height: 16),

            Text("Обзор", style: AppTextStyles.title),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Доходы',
                            style: AppTextStyles.secondary.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(financialState?.income ?? 0).toStringAsFixed(0)} ₽',
                            style: AppTextStyles.balance,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Расходы',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(financialState?.expenses ?? 0).toStringAsFixed(0)} ₽',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _menuCard(
                    icon: Icons.receipt,
                    title: 'Чеки',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReceiptsScreen(),
                        ),
                      );

                      await loadData();
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _menuCard(
                    icon: Icons.list,
                    title: 'Операции',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OperationsScreen(),
                        ),
                      );

                      await loadData();
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _menuCard(
                    icon: Icons.account_balance,
                    title: 'Счета',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountsScreen(),
                        ),
                      );

                      await loadData();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text('🕒 История операций', style: AppTextStyles.title),

            const SizedBox(height: 16),

            if (operations.isEmpty)
              const Center(child: Text('Операций пока нет'))
            else
              ...operations.map(
                (op) => ListTile(
                  title: Text(
                    op.comment.isEmpty ? op.type.toString() : op.comment,
                  ),

                  subtitle: Text(op.type.toString()),

                  trailing: Text(
                    '${op.type == OperationType.expense ? "-" : "+"}'
                    '${op.amount.toStringAsFixed(0)} ₽',
                  ),
                ),
              ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        heroTag: 'operation',

        onPressed: () async {
          final result = await Navigator.push<Operation>(
            context,

            MaterialPageRoute(
              builder: (context) =>
                  AddOperationScreen(account: selectedAccount),
            ),
          );

          if (result != null) {
            await _repository.insertOperation(result);

            await loadOperations();
          }
        },

        child: const Icon(Icons.add),
      ),
    );
  }
}
