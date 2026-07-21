class AiLimitException implements Exception {
  final int availableTokens;
  final String message;

  AiLimitException(
    this.availableTokens, {
    this.message = 'Недостаточно токенов',
  });
}
