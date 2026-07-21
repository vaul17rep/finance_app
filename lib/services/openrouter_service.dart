import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/parsed_receipt.dart';
import '../models/receipt_item.dart';
import 'package:flutter/foundation.dart';
import '../debug/debug_logger.dart';
import '../ai/ai_profile.dart';
import '../ai/ai_key_manager.dart';
import '../ai/ai_limit_exception.dart';

class OpenRouterService {
  final AiProfile profile;

  final int maxTokens;

  OpenRouterService({required this.profile, this.maxTokens = 4000});

  Future<ParsedReceipt> analyzeReceipt(String imageBase64) async {
    DebugLogger.log("START AI ANALYZE");

    DebugLogger.log("IMAGE SIZE: ${imageBase64.length}");

    final selectedApiKey = AiKeyManager.getAvailableKey(profile);

    DebugLogger.log("AI PROFILE: ${profile.name}");

    DebugLogger.log("API KEY LENGTH: ${selectedApiKey.length}");
    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),

      headers: {
        'Authorization': 'Bearer $selectedApiKey',

        'Content-Type': 'application/json',

        'HTTP-Referer': 'http://localhost',

        'X-Title': 'Finance App',
      },

      body: jsonEncode({
        "model": profile.model,

        "temperature": 0,

        "max_tokens": maxTokens,

        "messages": [
          {
            "role": "user",

            "content": [
              {
                "type": "text",

                "text": """

Ты — система извлечения структурированных данных из кассовых чеков.

Твоя задача — максимально точно извлечь ВСЕ данные, которые присутствуют на изображении.

Верни ТОЛЬКО корректный JSON.
Не используй Markdown.
Не добавляй пояснений.
Не добавляй текст до или после JSON.

Формат:

{
"date":"ДД.ММ.ГГГГ",
"time":"ЧЧ:ММ",
"store":"",
"payment_type":"",
"total_amount":0,
"items":[
 {
  "product":"",
  "category":"",
  "quantity":0,
  "unit":"",
  "price_per_unit":0,
  "total_price":0,
  "price_before_discount":0,
  "comment":""
 }
]
}


ОБЩИЕ ПРАВИЛА:

- Заполняй максимально возможное количество полей.
- Ничего не придумывай.
- Если значение невозможно определить:
  строка = ""
  число = 0
- Не пропускай поля.
- JSON должен быть валидным.


ДАТА И ВРЕМЯ:

Найди дату и время покупки.

Дата может быть:
- возле номера чека;
- возле строки "Дата";
- возле реквизитов кассы.

Время может быть:
- рядом с датой;
- возле номера операции.

Если время видно:
укажи его в формате ЧЧ:ММ.

Не придумывай дату или время.


МАГАЗИН:

Верни название магазина.

Если на чеке указан адрес магазина, добавь его после названия.

Пример:

"Пятёрочка, ул. Ленина 10"

Не включай:
- ИНН;
- КПП;
- ОГРН;
- телефон;
- сайт;
- юридическое название организации.


ТОВАРЫ:

Каждая позиция чека должна быть отдельным элементом items.

Не объединяй одинаковые товары.

Название товара копируй максимально близко к тексту чека.

Не исправляй и не дополняй название, если оно обрезано.

Если на чеке написано сокращённое название — оставь его.


КОЛИЧЕСТВО:

Если написано:

1 x 100

значит:

quantity = 1
price_per_unit = 100
total_price = 100


Если написано:

2 x 80

значит:

quantity = 2
price_per_unit = 80
total_price = 160


Если вес:

0.523 кг × 350

значит:

quantity = 0.523
unit = "кг"
price_per_unit = 350
total_price = 183.05


Если количество не указано:

quantity = 1
unit = "шт"


ЕДИНИЦЫ:

Используй только:

шт
кг
л


ЦЕНЫ:

price_per_unit — цена одной единицы товара.

total_price — итоговая стоимость позиции.

Если total_price отсутствует, но известны quantity и price_per_unit:

total_price = quantity × price_per_unit


СКИДКИ:

price_before_discount заполняй только если старая цена реально указана.

Если старой цены нет:

price_before_discount = 0


КАТЕГОРИИ:

Используй только:

мясо
рыба
молочка
овощи
фрукты
бакалея
напитки
сладкое
бытовое
другое


Правила категорий:

Мороженое:
сладкое


Молоко, йогурты, сыр, творог, кефир:
молочка


Колбаса, мясо, курица, фарш:
мясо


Рыба, икра, рыбные продукты:
рыба


Вода, сок, газировка:
напитки


ОПЛАТА:

Карта:

Если есть:
- карта;
- терминал;
- безналичная;
- эквайринг;
- Visa;
- MasterCard;
- МИР;
- СБП.

payment_type = "карта"


Наличные:

Если есть:
- наличные;
- наличный расчёт;
- внесено;
- сдача.

payment_type = "наличные"


Кредит:

payment_type = "кредит"

только если одновременно присутствуют:

- клиент;
- кредитор;
- одобрено;

или явно указан:

- Камелот-А.


Если способ оплаты определить невозможно:

payment_type = ""


КОММЕНТАРИЙ:

Используй comment только если есть сомнение при распознавании конкретного товара.

Иначе:

comment = ""


СУММА:

total_amount должна быть итоговой суммой покупки.

Используй итоговую сумму после скидок.


Верни только JSON.
```

Я бы ещё потом отдельно проверил `max_tokens: 1500`. Если чек большой (20–40 товаров), JSON может не влезть. Возможно, лучше поднять до 2500–3000. Но сначала протестировать этим промптом.

""",
              },

              {
                "type": "image_url",

                "image_url": {"url": imageBase64},
              },
            ],
          },
        ],
      }),
    );

    print("==============================");
    print("OPENROUTER STATUS:");
    print(response.statusCode);
    DebugLogger.log("OPENROUTER STATUS: ${response.statusCode}");
    print("==============================");
    print("RAW RESPONSE:");
    print(response.body);
    DebugLogger.log("RESPONSE LENGTH: ${response.body.length}");
    if (response.statusCode != 200) {
      if (response.statusCode == 429) {
        AiKeyManager.markFailed(selectedApiKey);
      }

      if (response.statusCode == 402) {
        final body = jsonDecode(response.body);

        final message = body["error"]["message"] ?? "";

        final match = RegExp(r'only afford (\d+)').firstMatch(message);

        final available = match != null ? int.parse(match.group(1)!) : 1000;

        throw AiLimitException(available);
      }

      if (response.statusCode == 401) {
        throw Exception("Неверный AI ключ");
      }

      throw Exception("OpenRouter error ${response.statusCode}");
    }

    final data = jsonDecode(response.body);

    String text = data["choices"][0]["message"]["content"];

    text = text.replaceAll("```json", "").replaceAll("```", "").trim();

    print("==============================");
    print("AI TEXT:");
    debugPrint(text, wrapWidth: 1024);

    print("==============================");
    print("JSON PARSING...");

    var cleanText = text;

    // Оставляем только JSON
    final start = cleanText.indexOf("{");
    final end = cleanText.lastIndexOf("}");

    if (start != -1 && end != -1) {
      cleanText = cleanText.substring(start, end + 1);
    }

    dynamic json;

    try {
      json = jsonDecode(cleanText);
    } catch (e) {
      print("==============================");
      print("JSON ERROR:");
      print(e);
      print("==============================");

      print("BROKEN JSON:");
      print(cleanText);

      throw Exception("Invalid AI JSON");
    }

    print("==============================");
    print("ROOT FIELDS");
    print("DATE: ${json["date"]}");
    print("TIME: ${json["time"]}");
    print("STORE: ${json["store"]}");
    print("PAYMENT: ${json["payment_type"]}");
    print("TOTAL: ${json["total_amount"]}");
    print("==============================");
    print("==============================");
    print("PARSED JSON:");
    print(jsonEncode(json));
    print("==============================");
    print("ITEMS COUNT FROM AI:");
    print((json["items"] ?? []).length);
    print("==============================");

    List<ReceiptItem> items = [];

    for (int i = 0; i < (json["items"] ?? []).length; i++) {
      final item = json["items"][i];

      print("==============================");
      print("AI ITEM #$i");
      print("PRODUCT: ${item["product"]}");
      print("CATEGORY: ${item["category"]}");
      print("QUANTITY: ${item["quantity"]}");
      print("UNIT: ${item["unit"]}");
      print("PRICE PER UNIT: ${item["price_per_unit"]}");
      print("TOTAL PRICE: ${item["total_price"]}");
      print("BEFORE DISCOUNT: ${item["price_before_discount"]}");
      print("COMMENT: ${item["comment"]}");

      final receiptItem = ReceiptItem(
        id: "ITEM-${DateTime.now().millisecondsSinceEpoch}-$i",

        receiptId: "",

        name: item["product"] ?? "",

        quantity: double.tryParse(item["quantity"].toString()) ?? 1,

        price: double.tryParse(item["price_per_unit"].toString()) ?? 0,

        total: double.tryParse(item["total_price"].toString()) ?? 0,

        priceBeforeDiscount:
            double.tryParse(item["price_before_discount"].toString()) ?? 0,

        comment: item["comment"] ?? "",

        category: item["category"] ?? "другое",
      );

      print("DART ITEM #$i");
      print("NAME: ${receiptItem.name}");
      print("CATEGORY: ${receiptItem.category}");
      print("QUANTITY: ${receiptItem.quantity}");
      print("PRICE: ${receiptItem.price}");
      print("TOTAL: ${receiptItem.total}");
      print("DISCOUNT PRICE: ${receiptItem.priceBeforeDiscount}");
      print("COMMENT: ${receiptItem.comment}");

      items.add(receiptItem);
    }

    DateTime? date;

    String? time;

    if (json["time"] != null) {
      time = json["time"].toString();
    }

    if (json["date"] != null && json["date"].toString().isNotEmpty) {
      final parts = json["date"].toString().split(".");

      if (parts.length == 3) {
        date = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    }

    print("==============================");
    print("FINAL RESULT");

    print("SHOP:");
    print(json["store"]);

    print("DATE:");
    print(json["date"]);

    print("TIME:");
    print(json["time"]);

    print("PAYMENT:");
    print(json["payment_type"]);

    print("TOTAL:");
    print(json["total_amount"]);

    print("ITEM COUNT:");
    print(items.length);

    print("==============================");

    return ParsedReceipt(
      date: date,

      time: time,

      shop: json["store"] ?? "",

      paymentType: json["payment_type"] ?? "",

      items: items,

      totalAmount: double.tryParse(json["total_amount"].toString()) ?? 0,
    );
  }
}
