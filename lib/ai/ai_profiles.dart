import '../secrets.dart';
import 'ai_profile.dart';

class AiProfiles {
  static final free = AiProfile(
    id: 'free',
    name: 'Бесплатный',
    keys: Secrets.openRouterFreeKeys,
    model: 'openai/gpt-4.1-mini',
  );

  static final paid = AiProfile(
    id: 'paid',
    name: 'Платный',
    keys: [Secrets.openRouterPaidKey],
    model: 'openai/gpt-4.1-mini',
  );

  static final List<AiProfile> all = [free, paid];
}
