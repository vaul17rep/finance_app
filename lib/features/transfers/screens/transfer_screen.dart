/// Экран для создания перевода между счетами.
///
/// Позволяет выбрать счёт-источник, счёт-назначение,
/// ввести сумму и комментарий.
///
/// Связанные документы:
/// - 07_Functional_Requirements — сценарий перевода
/// - 03_Domain_Model — Transfer

import 'package:flutter/material.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../domain/usecases/transfer_service.dart';
import '../../../models/account.dart';
import '../../../core/theme/app_dimensions.dart';

/// Экран для создания перевода между счетами.
class TransferScreen extends StatefulWidget {
  /// ID счёта-источника (опционально, если переходим с карточки)
  final String? initialSourceAccountId;

  const TransferScreen({super.key, this.initialSourceAccountId});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final AccountRepository _accountRepository = AccountRepository();
  final TransferService _transferService = TransferService();

  List<Account> _accounts = [];
  List<Account> _availableToAccounts = [];
  Account? _sourceAccount;
  Account? _destinationAccount;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _accountRepository.getAccounts();
      setState(() {
        _accounts = accounts;

        if (widget.initialSourceAccountId != null) {
          final exists = _accounts.any(
            (a) => a.id == widget.initialSourceAccountId,
          );
          if (exists) {
            _sourceAccount = _accounts.firstWhere(
              (a) => a.id == widget.initialSourceAccountId,
            );
          } else {
            _sourceAccount = _accounts.isNotEmpty ? _accounts.first : null;
          }
        } else if (_accounts.isNotEmpty) {
          _sourceAccount = _accounts.first;
        }

        _updateToAccounts();
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки счетов: $e';
      });
    }
  }

  void _updateToAccounts() {
    setState(() {
      _availableToAccounts = _accounts
          .where((account) => account.id != _sourceAccount?.id)
          .toList();

      if (_destinationAccount != null &&
          !_availableToAccounts.any(
            (a) => a.id == _destinationAccount!.id,
          )) {
        _destinationAccount = null;
      }
    });
  }

  bool get _isValid {
    return _sourceAccount != null &&
        _destinationAccount != null &&
        _sourceAccount!.id != _destinationAccount!.id &&
        _amountController.text.isNotEmpty &&
        double.tryParse(_amountController.text) != null &&
        double.parse(_amountController.text) > 0;
  }

  Future<void> _createTransfer() async {
    if (!_isValid) return;

    final amount = double.parse(_amountController.text);
    final comment = _commentController.text.isNotEmpty
        ? _commentController.text
        : null;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final request = TransferRequest(
        sourceAccountId: _sourceAccount!.id,
        destinationAccountId: _destinationAccount!.id,
        amount: amount,
        date: DateTime.now(),
        comment: comment,
      );

      await _transferService.createTransfer(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Перевод выполнен успешно'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Перевод между счетами'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ошибка
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),

                  if (_error != null) const SizedBox(height: 16),

                  // Счёт-источник
                  DropdownButtonFormField<Account>(
                    value: _sourceAccount,
                    decoration: const InputDecoration(
                      labelText: 'Счёт-источник',
                      border: OutlineInputBorder(),
                    ),
                    items: _accounts.map((account) {
                      return DropdownMenuItem(
                        value: account,
                        child: Text(account.name),
                      );
                    }).toList(),
                    onChanged: (account) {
                      setState(() {
                        _sourceAccount = account;
                        _updateToAccounts();
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Счёт-назначение
                  DropdownButtonFormField<Account>(
                    value: _destinationAccount,
                    decoration: const InputDecoration(
                      labelText: 'Счёт-назначение',
                      border: OutlineInputBorder(),
                    ),
                    items: _availableToAccounts.map((account) {
                      return DropdownMenuItem(
                        value: account,
                        child: Text(account.name),
                      );
                    }).toList(),
                    onChanged: (account) {
                      setState(() {
                        _destinationAccount = account;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Сумма
                  TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Сумма',
                      border: OutlineInputBorder(),
                      prefixText: '₽ ',
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 16),

                  // Комментарий (опционально)
                  TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      labelText: 'Комментарий (опционально)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 32),

                  // Кнопка перевода
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isValid && !_isLoading
                          ? _createTransfer
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMedium,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Перевести',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}