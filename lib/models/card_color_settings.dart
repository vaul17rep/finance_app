// lib/models/card_color_settings.dart
class CardColorSettings {
  final String id;
  final int cardLightStart;
  final int cardLightEnd;
  final int cashLightStart;
  final int cashLightEnd;
  final int creditLightStart;
  final int creditLightEnd;
  final int otherLightStart;
  final int otherLightEnd;
  final int cardDarkStart;
  final int cardDarkEnd;
  final int cashDarkStart;
  final int cashDarkEnd;
  final int creditDarkStart;
  final int creditDarkEnd;
  final int otherDarkStart;
  final int otherDarkEnd;

  // Пользовательские типы (до 5)
  final String custom1Name;
  final int custom1LightStart;
  final int custom1LightEnd;
  final int custom1DarkStart;
  final int custom1DarkEnd;

  final String custom2Name;
  final int custom2LightStart;
  final int custom2LightEnd;
  final int custom2DarkStart;
  final int custom2DarkEnd;

  final String custom3Name;
  final int custom3LightStart;
  final int custom3LightEnd;
  final int custom3DarkStart;
  final int custom3DarkEnd;

  final String custom4Name;
  final int custom4LightStart;
  final int custom4LightEnd;
  final int custom4DarkStart;
  final int custom4DarkEnd;

  final String custom5Name;
  final int custom5LightStart;
  final int custom5LightEnd;
  final int custom5DarkStart;
  final int custom5DarkEnd;

  CardColorSettings({
    required this.id,
    required this.cardLightStart,
    required this.cardLightEnd,
    required this.cashLightStart,
    required this.cashLightEnd,
    required this.creditLightStart,
    required this.creditLightEnd,
    required this.otherLightStart,
    required this.otherLightEnd,
    required this.cardDarkStart,
    required this.cardDarkEnd,
    required this.cashDarkStart,
    required this.cashDarkEnd,
    required this.creditDarkStart,
    required this.creditDarkEnd,
    required this.otherDarkStart,
    required this.otherDarkEnd,
    this.custom1Name = '',
    this.custom1LightStart = 0xFFB3C6E7,
    this.custom1LightEnd = 0xFF8BA7D4,
    this.custom1DarkStart = 0xFF2D3A5A,
    this.custom1DarkEnd = 0xFF1E2A44,
    this.custom2Name = '',
    this.custom2LightStart = 0xFFB3C6E7,
    this.custom2LightEnd = 0xFF8BA7D4,
    this.custom2DarkStart = 0xFF2D3A5A,
    this.custom2DarkEnd = 0xFF1E2A44,
    this.custom3Name = '',
    this.custom3LightStart = 0xFFB3C6E7,
    this.custom3LightEnd = 0xFF8BA7D4,
    this.custom3DarkStart = 0xFF2D3A5A,
    this.custom3DarkEnd = 0xFF1E2A44,
    this.custom4Name = '',
    this.custom4LightStart = 0xFFB3C6E7,
    this.custom4LightEnd = 0xFF8BA7D4,
    this.custom4DarkStart = 0xFF2D3A5A,
    this.custom4DarkEnd = 0xFF1E2A44,
    this.custom5Name = '',
    this.custom5LightStart = 0xFFB3C6E7,
    this.custom5LightEnd = 0xFF8BA7D4,
    this.custom5DarkStart = 0xFF2D3A5A,
    this.custom5DarkEnd = 0xFF1E2A44,
  });

  CardColorSettings copyWith({
    int? cardLightStart,
    int? cardLightEnd,
    int? cashLightStart,
    int? cashLightEnd,
    int? creditLightStart,
    int? creditLightEnd,
    int? otherLightStart,
    int? otherLightEnd,
    int? cardDarkStart,
    int? cardDarkEnd,
    int? cashDarkStart,
    int? cashDarkEnd,
    int? creditDarkStart,
    int? creditDarkEnd,
    int? otherDarkStart,
    int? otherDarkEnd,
    String? custom1Name,
    int? custom1LightStart,
    int? custom1LightEnd,
    int? custom1DarkStart,
    int? custom1DarkEnd,
    String? custom2Name,
    int? custom2LightStart,
    int? custom2LightEnd,
    int? custom2DarkStart,
    int? custom2DarkEnd,
    String? custom3Name,
    int? custom3LightStart,
    int? custom3LightEnd,
    int? custom3DarkStart,
    int? custom3DarkEnd,
    String? custom4Name,
    int? custom4LightStart,
    int? custom4LightEnd,
    int? custom4DarkStart,
    int? custom4DarkEnd,
    String? custom5Name,
    int? custom5LightStart,
    int? custom5LightEnd,
    int? custom5DarkStart,
    int? custom5DarkEnd,
  }) {
    return CardColorSettings(
      id: id,
      cardLightStart: cardLightStart ?? this.cardLightStart,
      cardLightEnd: cardLightEnd ?? this.cardLightEnd,
      cashLightStart: cashLightStart ?? this.cashLightStart,
      cashLightEnd: cashLightEnd ?? this.cashLightEnd,
      creditLightStart: creditLightStart ?? this.creditLightStart,
      creditLightEnd: creditLightEnd ?? this.creditLightEnd,
      otherLightStart: otherLightStart ?? this.otherLightStart,
      otherLightEnd: otherLightEnd ?? this.otherLightEnd,
      cardDarkStart: cardDarkStart ?? this.cardDarkStart,
      cardDarkEnd: cardDarkEnd ?? this.cardDarkEnd,
      cashDarkStart: cashDarkStart ?? this.cashDarkStart,
      cashDarkEnd: cashDarkEnd ?? this.cashDarkEnd,
      creditDarkStart: creditDarkStart ?? this.creditDarkStart,
      creditDarkEnd: creditDarkEnd ?? this.creditDarkEnd,
      otherDarkStart: otherDarkStart ?? this.otherDarkStart,
      otherDarkEnd: otherDarkEnd ?? this.otherDarkEnd,
      custom1Name: custom1Name ?? this.custom1Name,
      custom1LightStart: custom1LightStart ?? this.custom1LightStart,
      custom1LightEnd: custom1LightEnd ?? this.custom1LightEnd,
      custom1DarkStart: custom1DarkStart ?? this.custom1DarkStart,
      custom1DarkEnd: custom1DarkEnd ?? this.custom1DarkEnd,
      custom2Name: custom2Name ?? this.custom2Name,
      custom2LightStart: custom2LightStart ?? this.custom2LightStart,
      custom2LightEnd: custom2LightEnd ?? this.custom2LightEnd,
      custom2DarkStart: custom2DarkStart ?? this.custom2DarkStart,
      custom2DarkEnd: custom2DarkEnd ?? this.custom2DarkEnd,
      custom3Name: custom3Name ?? this.custom3Name,
      custom3LightStart: custom3LightStart ?? this.custom3LightStart,
      custom3LightEnd: custom3LightEnd ?? this.custom3LightEnd,
      custom3DarkStart: custom3DarkStart ?? this.custom3DarkStart,
      custom3DarkEnd: custom3DarkEnd ?? this.custom3DarkEnd,
      custom4Name: custom4Name ?? this.custom4Name,
      custom4LightStart: custom4LightStart ?? this.custom4LightStart,
      custom4LightEnd: custom4LightEnd ?? this.custom4LightEnd,
      custom4DarkStart: custom4DarkStart ?? this.custom4DarkStart,
      custom4DarkEnd: custom4DarkEnd ?? this.custom4DarkEnd,
      custom5Name: custom5Name ?? this.custom5Name,
      custom5LightStart: custom5LightStart ?? this.custom5LightStart,
      custom5LightEnd: custom5LightEnd ?? this.custom5LightEnd,
      custom5DarkStart: custom5DarkStart ?? this.custom5DarkStart,
      custom5DarkEnd: custom5DarkEnd ?? this.custom5DarkEnd,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cardLightStart': cardLightStart,
      'cardLightEnd': cardLightEnd,
      'cashLightStart': cashLightStart,
      'cashLightEnd': cashLightEnd,
      'creditLightStart': creditLightStart,
      'creditLightEnd': creditLightEnd,
      'otherLightStart': otherLightStart,
      'otherLightEnd': otherLightEnd,
      'cardDarkStart': cardDarkStart,
      'cardDarkEnd': cardDarkEnd,
      'cashDarkStart': cashDarkStart,
      'cashDarkEnd': cashDarkEnd,
      'creditDarkStart': creditDarkStart,
      'creditDarkEnd': creditDarkEnd,
      'otherDarkStart': otherDarkStart,
      'otherDarkEnd': otherDarkEnd,
      'custom1Name': custom1Name,
      'custom1LightStart': custom1LightStart,
      'custom1LightEnd': custom1LightEnd,
      'custom1DarkStart': custom1DarkStart,
      'custom1DarkEnd': custom1DarkEnd,
      'custom2Name': custom2Name,
      'custom2LightStart': custom2LightStart,
      'custom2LightEnd': custom2LightEnd,
      'custom2DarkStart': custom2DarkStart,
      'custom2DarkEnd': custom2DarkEnd,
      'custom3Name': custom3Name,
      'custom3LightStart': custom3LightStart,
      'custom3LightEnd': custom3LightEnd,
      'custom3DarkStart': custom3DarkStart,
      'custom3DarkEnd': custom3DarkEnd,
      'custom4Name': custom4Name,
      'custom4LightStart': custom4LightStart,
      'custom4LightEnd': custom4LightEnd,
      'custom4DarkStart': custom4DarkStart,
      'custom4DarkEnd': custom4DarkEnd,
      'custom5Name': custom5Name,
      'custom5LightStart': custom5LightStart,
      'custom5LightEnd': custom5LightEnd,
      'custom5DarkStart': custom5DarkStart,
      'custom5DarkEnd': custom5DarkEnd,
    };
  }

  static CardColorSettings fromMap(Map<String, dynamic> map) {
    return CardColorSettings(
      id: map['id'] as String,
      cardLightStart: map['cardLightStart'] as int,
      cardLightEnd: map['cardLightEnd'] as int,
      cashLightStart: map['cashLightStart'] as int,
      cashLightEnd: map['cashLightEnd'] as int,
      creditLightStart: map['creditLightStart'] as int,
      creditLightEnd: map['creditLightEnd'] as int,
      otherLightStart: map['otherLightStart'] as int,
      otherLightEnd: map['otherLightEnd'] as int,
      cardDarkStart: map['cardDarkStart'] as int,
      cardDarkEnd: map['cardDarkEnd'] as int,
      cashDarkStart: map['cashDarkStart'] as int,
      cashDarkEnd: map['cashDarkEnd'] as int,
      creditDarkStart: map['creditDarkStart'] as int,
      creditDarkEnd: map['creditDarkEnd'] as int,
      otherDarkStart: map['otherDarkStart'] as int,
      otherDarkEnd: map['otherDarkEnd'] as int,
      custom1Name: map['custom1Name'] as String? ?? '',
      custom1LightStart: map['custom1LightStart'] as int? ?? 0xFFB3C6E7,
      custom1LightEnd: map['custom1LightEnd'] as int? ?? 0xFF8BA7D4,
      custom1DarkStart: map['custom1DarkStart'] as int? ?? 0xFF2D3A5A,
      custom1DarkEnd: map['custom1DarkEnd'] as int? ?? 0xFF1E2A44,
      custom2Name: map['custom2Name'] as String? ?? '',
      custom2LightStart: map['custom2LightStart'] as int? ?? 0xFFB3C6E7,
      custom2LightEnd: map['custom2LightEnd'] as int? ?? 0xFF8BA7D4,
      custom2DarkStart: map['custom2DarkStart'] as int? ?? 0xFF2D3A5A,
      custom2DarkEnd: map['custom2DarkEnd'] as int? ?? 0xFF1E2A44,
      custom3Name: map['custom3Name'] as String? ?? '',
      custom3LightStart: map['custom3LightStart'] as int? ?? 0xFFB3C6E7,
      custom3LightEnd: map['custom3LightEnd'] as int? ?? 0xFF8BA7D4,
      custom3DarkStart: map['custom3DarkStart'] as int? ?? 0xFF2D3A5A,
      custom3DarkEnd: map['custom3DarkEnd'] as int? ?? 0xFF1E2A44,
      custom4Name: map['custom4Name'] as String? ?? '',
      custom4LightStart: map['custom4LightStart'] as int? ?? 0xFFB3C6E7,
      custom4LightEnd: map['custom4LightEnd'] as int? ?? 0xFF8BA7D4,
      custom4DarkStart: map['custom4DarkStart'] as int? ?? 0xFF2D3A5A,
      custom4DarkEnd: map['custom4DarkEnd'] as int? ?? 0xFF1E2A44,
      custom5Name: map['custom5Name'] as String? ?? '',
      custom5LightStart: map['custom5LightStart'] as int? ?? 0xFFB3C6E7,
      custom5LightEnd: map['custom5LightEnd'] as int? ?? 0xFF8BA7D4,
      custom5DarkStart: map['custom5DarkStart'] as int? ?? 0xFF2D3A5A,
      custom5DarkEnd: map['custom5DarkEnd'] as int? ?? 0xFF1E2A44,
    );
  }

  static CardColorSettings defaultSettings() {
    return CardColorSettings(
      id: 'default',
      cardLightStart: 0xFFB3C6E7,
      cardLightEnd: 0xFF8BA7D4,
      cashLightStart: 0xFFA8D5BA,
      cashLightEnd: 0xFF81C784,
      creditLightStart: 0xFFD1C4E9,
      creditLightEnd: 0xFFB39DDB,
      otherLightStart: 0xFFFFE0B2,
      otherLightEnd: 0xFFFFCC80,
      cardDarkStart: 0xFF2D3A5A,
      cardDarkEnd: 0xFF1E2A44,
      cashDarkStart: 0xFF1E3B2E,
      cashDarkEnd: 0xFF15271F,
      creditDarkStart: 0xFF3A2E4C,
      creditDarkEnd: 0xFF261E33,
      otherDarkStart: 0xFF4A3A2A,
      otherDarkEnd: 0xFF33281C,
    );
  }
}
