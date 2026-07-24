class AiProfile {
  final String id;
  final String name;
  final String model;
  final List<String> keys;

  const AiProfile({
    required this.id,
    required this.name,
    required this.model,
    required this.keys,
  });

  String get fallbackKey {
    return keys.first;
  }
}
