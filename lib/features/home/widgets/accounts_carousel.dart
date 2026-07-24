import 'package:flutter/material.dart';

import '../../../models/account.dart';
import '../../../data/repositories/account_repository.dart';

import '../../accounts/widgets/account_card.dart';
import '../../accounts/widgets/create_account_dialog.dart';
import '../../accounts/account_details_screen.dart';

import '../../../core/utils/custom_page_scroll_physics.dart';

class AccountsCarousel extends StatefulWidget {
  final List<Account> accounts;
  final Map<String, double> balances;

  final PageController controller;
  final double currentPage;

  final Future<void> Function(Account account) onAccountSelected;
  final Future<void> Function() onRefresh;

  const AccountsCarousel({
    super.key,
    required this.accounts,
    required this.balances,
    required this.controller,
    required this.currentPage,
    required this.onAccountSelected,
    required this.onRefresh,
  });

  @override
  State<AccountsCarousel> createState() => _AccountsCarouselState();
}

class _AccountsCarouselState extends State<AccountsCarousel> {
  final AccountRepository _accountRepository = AccountRepository();

  Future<void> createAccount() async {
    final account = await showCreateAccountDialog(
      context,
      isMain: widget.accounts.isEmpty,
    );

    if (account == null) return;

    await _accountRepository.insertAccount(account);

    await widget.onRefresh();

    final newIndex = widget.accounts.indexWhere((e) => e.id == account.id);

    if (newIndex != -1) {
      widget.controller.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      await widget.onAccountSelected(account);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.68;

    return SizedBox(
      height: cardWidth / AccountCard.aspectRatio,

      child: PageView.builder(
        physics: const CustomPageScrollPhysics(),

        controller: widget.controller,

        clipBehavior: Clip.none,

        padEnds: false,

        itemCount: widget.accounts.length + 1,

        onPageChanged: (index) {
          if (index >= widget.accounts.length) {
            return;
          }

          widget.onAccountSelected(widget.accounts[index]);
        },

        itemBuilder: (context, index) {
          if (index == widget.accounts.length) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),

              child: GestureDetector(
                onTap: createAccount,

                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),

                    color: Colors.grey.withValues(alpha: 0.25),
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
              ),
            );
          }

          final account = widget.accounts[index];

          final scale = (1 - ((widget.currentPage - index).abs() * 0.05)).clamp(
            0.9,
            1.0,
          );

          return Padding(
            padding: const EdgeInsets.only(right: 16),

            child: AnimatedScale(
              scale: scale,

              duration: const Duration(milliseconds: 200),

              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (_) => AccountDetailsScreen(account: account),
                    ),
                  );
                },

                child: AccountCard(
                  account: account,

                  balance: widget.balances[account.id] ?? 0,

                  width: cardWidth,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
