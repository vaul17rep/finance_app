import '../settings/app_settings.dart';

String processAccountName(String name) {
  if (!AppSettings.limitAccountNameLength) {
    return name;
  }

  if (name.length <= AppSettings.maxAccountNameLength) {
    return name;
  }

  return name.substring(0, AppSettings.maxAccountNameLength);
}
