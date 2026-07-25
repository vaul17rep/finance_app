import 'package:flutter/material.dart';
import '../../models/card_color_settings.dart';
import '../../data/repositories/card_color_settings_repository.dart';

class ColorSettingsNotifier extends ChangeNotifier {
  final CardColorSettingsRepository _repository = CardColorSettingsRepository();

  CardColorSettings _settings = CardColorSettings.defaultSettings();
  CardColorSettings _tempSettings = CardColorSettings.defaultSettings();

  CardColorSettings get settings => _settings;
  CardColorSettings get tempSettings => _tempSettings;

  Future<void> loadSettings() async {
    _settings = await _repository.getSettings();
    _tempSettings = _settings;
    notifyListeners();
  }

  void updateColor(String field, Color color) {
    final value = color.toARGB32();
    switch (field) {
      case 'cardLightStart':
        _tempSettings = _tempSettings.copyWith(cardLightStart: value);
        break;
      case 'cardLightEnd':
        _tempSettings = _tempSettings.copyWith(cardLightEnd: value);
        break;
      case 'cashLightStart':
        _tempSettings = _tempSettings.copyWith(cashLightStart: value);
        break;
      case 'cashLightEnd':
        _tempSettings = _tempSettings.copyWith(cashLightEnd: value);
        break;
      case 'creditLightStart':
        _tempSettings = _tempSettings.copyWith(creditLightStart: value);
        break;
      case 'creditLightEnd':
        _tempSettings = _tempSettings.copyWith(creditLightEnd: value);
        break;
      case 'otherLightStart':
        _tempSettings = _tempSettings.copyWith(otherLightStart: value);
        break;
      case 'otherLightEnd':
        _tempSettings = _tempSettings.copyWith(otherLightEnd: value);
        break;
      case 'cardDarkStart':
        _tempSettings = _tempSettings.copyWith(cardDarkStart: value);
        break;
      case 'cardDarkEnd':
        _tempSettings = _tempSettings.copyWith(cardDarkEnd: value);
        break;
      case 'cashDarkStart':
        _tempSettings = _tempSettings.copyWith(cashDarkStart: value);
        break;
      case 'cashDarkEnd':
        _tempSettings = _tempSettings.copyWith(cashDarkEnd: value);
        break;
      case 'creditDarkStart':
        _tempSettings = _tempSettings.copyWith(creditDarkStart: value);
        break;
      case 'creditDarkEnd':
        _tempSettings = _tempSettings.copyWith(creditDarkEnd: value);
        break;
      case 'otherDarkStart':
        _tempSettings = _tempSettings.copyWith(otherDarkStart: value);
        break;
      case 'otherDarkEnd':
        _tempSettings = _tempSettings.copyWith(otherDarkEnd: value);
        break;
      // Custom 1
      case 'custom1LightStart':
        _tempSettings = _tempSettings.copyWith(custom1LightStart: value);
        break;
      case 'custom1LightEnd':
        _tempSettings = _tempSettings.copyWith(custom1LightEnd: value);
        break;
      case 'custom1DarkStart':
        _tempSettings = _tempSettings.copyWith(custom1DarkStart: value);
        break;
      case 'custom1DarkEnd':
        _tempSettings = _tempSettings.copyWith(custom1DarkEnd: value);
        break;
      // Custom 2
      case 'custom2LightStart':
        _tempSettings = _tempSettings.copyWith(custom2LightStart: value);
        break;
      case 'custom2LightEnd':
        _tempSettings = _tempSettings.copyWith(custom2LightEnd: value);
        break;
      case 'custom2DarkStart':
        _tempSettings = _tempSettings.copyWith(custom2DarkStart: value);
        break;
      case 'custom2DarkEnd':
        _tempSettings = _tempSettings.copyWith(custom2DarkEnd: value);
        break;
      // Custom 3
      case 'custom3LightStart':
        _tempSettings = _tempSettings.copyWith(custom3LightStart: value);
        break;
      case 'custom3LightEnd':
        _tempSettings = _tempSettings.copyWith(custom3LightEnd: value);
        break;
      case 'custom3DarkStart':
        _tempSettings = _tempSettings.copyWith(custom3DarkStart: value);
        break;
      case 'custom3DarkEnd':
        _tempSettings = _tempSettings.copyWith(custom3DarkEnd: value);
        break;
      // Custom 4
      case 'custom4LightStart':
        _tempSettings = _tempSettings.copyWith(custom4LightStart: value);
        break;
      case 'custom4LightEnd':
        _tempSettings = _tempSettings.copyWith(custom4LightEnd: value);
        break;
      case 'custom4DarkStart':
        _tempSettings = _tempSettings.copyWith(custom4DarkStart: value);
        break;
      case 'custom4DarkEnd':
        _tempSettings = _tempSettings.copyWith(custom4DarkEnd: value);
        break;
      // Custom 5
      case 'custom5LightStart':
        _tempSettings = _tempSettings.copyWith(custom5LightStart: value);
        break;
      case 'custom5LightEnd':
        _tempSettings = _tempSettings.copyWith(custom5LightEnd: value);
        break;
      case 'custom5DarkStart':
        _tempSettings = _tempSettings.copyWith(custom5DarkStart: value);
        break;
      case 'custom5DarkEnd':
        _tempSettings = _tempSettings.copyWith(custom5DarkEnd: value);
        break;
      default:
        throw ArgumentError('Unknown field: $field');
    }
    notifyListeners();
  }

  void updateCustomName(int index, String name) {
    switch (index) {
      case 1:
        _tempSettings = _tempSettings.copyWith(custom1Name: name);
        break;
      case 2:
        _tempSettings = _tempSettings.copyWith(custom2Name: name);
        break;
      case 3:
        _tempSettings = _tempSettings.copyWith(custom3Name: name);
        break;
      case 4:
        _tempSettings = _tempSettings.copyWith(custom4Name: name);
        break;
      case 5:
        _tempSettings = _tempSettings.copyWith(custom5Name: name);
        break;
      default:
        return;
    }
    notifyListeners();
  }

  void resetToDefault() {
    _tempSettings = CardColorSettings.defaultSettings();
    notifyListeners();
  }

  Future<void> saveSettings() async {
    _settings = _tempSettings;
    await _repository.saveSettings(_settings);
    notifyListeners();
  }
}
