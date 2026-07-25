import 'dart:async';
import 'package:flutter/material.dart';

import '../../models/operation.dart';
import '../../models/account.dart';

import '../../data/repositories/operation_repository.dart';
import '../../data/repositories/account_repository.dart';

import '../../domain/entities/financial_state.dart';
import '../../domain/usecases/financial_calculator.dart';
import '../../domain/usecases/financial_service.dart';

import '/data/services/background_manager/background_task_manager.dart';
import '/data/services/background_manager/background_task.dart';
import '/data/services/background_manager/widgets/task_monitor_floating.dart';

import 'widgets/receipt_floating_button.dart';
import 'widgets/operation_history_list.dart';
import 'widgets/home_overview.dart';
import 'widgets/accounts_carousel.dart';
import 'widgets/home_app_bar.dart';

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
    viewportFraction: 0.72,
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

  Map<String, FinancialState> financialStates = {};

  Map<String, double> balances = {};

  // Состояния для кнопки монитора
  bool _monitorActive = false;
  bool _hasError = false;
  Timer? _monitorTimer;
  Timer? _errorTimer;
  final Set<String> _shownErrorIds = {};

  @override
  void initState() {
    super.initState();

    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });

    // Слушаем задачи
    BackgroundTaskManager.instance.tasks.addListener(_onTasksChanged);

    loadData();
  }

  @override
  void dispose() {
    BackgroundTaskManager.instance.tasks.removeListener(_onTasksChanged);
    _monitorTimer?.cancel();
    _errorTimer?.cancel();
    super.dispose();
  }

  void _onTasksChanged() {
    final tasks = BackgroundTaskManager.instance.tasks.value;

    // Проверяем новые ошибки
    for (final task in tasks) {
      if (task.status == BackgroundTaskStatus.failed &&
          !_shownErrorIds.contains(task.id)) {
        _shownErrorIds.add(task.id);
        _showError(task);
      }
    }

    // Если задачи есть — активируем кнопку на 2 секунды
    if (tasks.isNotEmpty) {
      _activateMonitor();
    } else {
      _deactivateMonitor();
    }
  }

  void _activateMonitor() {
    setState(() => _monitorActive = true);
    _monitorTimer?.cancel();
    _monitorTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && !_hasError) {
        setState(() => _monitorActive = false);
      }
    });
  }

  void _deactivateMonitor() {
    setState(() {
      _monitorActive = false;
      _hasError = false;
    });
    _monitorTimer?.cancel();
    _errorTimer?.cancel();
    _shownErrorIds.clear();
  }

  void _showError(BackgroundTask task) {
    setState(() {
      _hasError = true;
      _monitorActive = true; // кнопка активна, пока ошибка видна
    });

    _errorTimer?.cancel();
    // Длительность SnackBar — 3 секунды + 300 мс на анимацию исчезновения кнопки
    _errorTimer = Timer(const Duration(milliseconds: 3300), () {
      if (mounted) {
        setState(() {
          _hasError = false;
          _monitorActive = false;
        });
        _shownErrorIds.remove(task.id);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          task.message.isNotEmpty ? task.message : 'Ошибка обработки чека',
        ),
        backgroundColor: const Color(0xFFE57373),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      ),
    );
  }

  void _onMonitorTap() {
    _activateMonitor();
  }

  void _onMonitorDismissed() {
    _activateMonitor();
  }

  Future<void> reorderAccounts(List<Account> newAccounts) async {
    setState(() {
      accounts = newAccounts;
    });

    await _accountRepository.updateAccountsOrder(accounts);

    await loadData();
  }

  Future<void> loadAccountState(Account account) async {
    final loadedOperations = await _repository.getOperationsByAccount(
      account.id,
    );

    final state = await _financialService.getState(account: account);

    setState(() {
      selectedAccount = account;

      operations = loadedOperations;

      financialStates[account.id] = state;

      balances[account.id] = state.balance;
    });
  }

  Future<void> loadData() async {
    final loadedAccounts = await _accountRepository.getAccounts();

    final calculatedBalances = <String, double>{};

    final calculatedStates = <String, FinancialState>{};

    for (final account in loadedAccounts) {
      final state = await _financialService.getState(account: account);

      calculatedBalances[account.id] = state.balance;

      calculatedStates[account.id] = state;
    }

    if (widget.initialAccount != null) {
      final account = loadedAccounts.firstWhere(
        (e) => e.id == widget.initialAccount!.id,
      );

      final loadedOperations = await _repository.getOperationsByAccount(
        account.id,
      );

      setState(() {
        accounts = loadedAccounts;

        balances = calculatedBalances;

        financialStates = calculatedStates;

        selectedAccount = account;

        operations = loadedOperations;
      });

      return;
    }

    final mainAccount = await _accountRepository.getMainAccount();

    if (mainAccount == null) {
      setState(() {
        accounts = loadedAccounts;

        balances = calculatedBalances;

        financialStates = calculatedStates;

        selectedAccount = null;

        operations = [];
      });

      return;
    }

    final loadedOperations = await _repository.getOperationsByAccount(
      mainAccount.id,
    );

    setState(() {
      accounts = loadedAccounts;

      balances = calculatedBalances;

      financialStates = calculatedStates;

      selectedAccount = mainAccount;

      operations = loadedOperations;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentState = selectedAccount == null
        ? null
        : financialStates[selectedAccount!.id];

    return Scaffold(
      appBar: HomeAppBar(onRefresh: refresh),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AccountsCarousel(
                  accounts: accounts,
                  balances: balances,
                  controller: _pageController,
                  currentPage: _currentPage,
                  onAccountSelected: loadAccountState,
                  onRefresh: refresh,
                ),
                const SizedBox(height: 20),
                Divider(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  thickness: 1,
                  height: 1,
                ),
                const SizedBox(height: 16),
                HomeOverview(
                  income: currentState?.income ?? 0,
                  expenses: currentState?.expenses ?? 0,
                ),
                const SizedBox(height: 16),
                Text('🕒 История операций', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                OperationHistoryList(operations: operations.take(5).toList()),
              ],
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: TaskMonitorFloating(
              isActive: _monitorActive,
              hasError: _hasError,
              onTap: _onMonitorTap,
              onDismissed: _onMonitorDismissed,
            ),
          ),
        ],
      ),
      floatingActionButton: ReceiptFloatingButton(
        onCreated: () async {
          await loadData();
        },
      ),
    );
  }
}
