import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/parsed_receipt.dart';
import '../models/receipt_item.dart';

class OpenRouterService {
  final String apiKey;

  OpenRouterService({required this.apiKey});

  Future<ParsedReceipt> analyzeReceipt(String imageBase64) async {
    print("IMAGE SIZE:");
    print(imageBase64.length);
    print("API KEY START:");
    print(apiKey.substring(0, 15));
    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),

      headers: {
        'Authorization': 'Bearer $apiKey',

        'Content-Type': 'application/json',

        'HTTP-Referer': 'http://localhost',

        'X-Title': 'Finance App',
      },

      body: jsonEncode({
        "model": "openai/gpt-4.1-mini",

        "temperature": 0,

        "max_tokens": 1500,

        "messages": [
          {
            "role": "user",

            "content": [
              {
                "type": "text",

                "text": """

Распознай кассовый чек.

Верни ТОЛЬКО JSON без markdown.

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


ПРАВИЛА:


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

Верни только название магазина.
Без адреса.
Без ИНН.
Без лишнего текста.


ТОВАРЫ:

Каждая позиция чека должна быть отдельным элементом items.

Название товара копируй максимально близко к чеку.


КОЛИЧЕСТВО:

Если написано:

1 x 100

значит:

quantity = 1
price_per_unit = 100
total_price = 100


Если вес:

0.523 кг × 350

значит:

quantity = 0.523
unit = "кг"
price_per_unit = 350


ЕДИНИЦЫ:

шт - штуки
кг - вес
л - объём


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

Мороженое всегда:
сладкое

Молоко, йогурты, сыр, творог:
молочка

Колбаса, мясо:
мясо

Вода, сок, газировка:
напитки


СКИДКИ:

price_before_discount заполняй только если старая цена реально указана.


ОПЛАТА:

Карта:
если есть:
карта
терминал
безналичная
СБП


Кредит:
только если есть одновременно:
клиент
кредитор
одобрено


Если не уверен:
оставь comment.


СУММА:

total_amount должна быть итоговой суммой покупки с чека.


Верни только JSON.
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

    if (response.statusCode != 200) {
      print("STATUS:");
      print(response.statusCode);

      print("BODY:");
      print(response.body);

      throw Exception("OpenRouter error");
    }

    final data = jsonDecode(response.body);

    String text = data["choices"][0]["message"]["content"];

    text = text.replaceAll("```json", "").replaceAll("```", "").trim();

    final json = jsonDecode(text);

    List<ReceiptItem> items = [];

    for (final item in json["items"]) {
      items.add(
        ReceiptItem(
          id: "ITEM-${DateTime.now().millisecondsSinceEpoch}",

          receiptId: "",

          name: item["product"] ?? "",

          quantity: (item["quantity"] ?? 1).toDouble(),

          unit: item["unit"] ?? "шт",

          price: (item["price_per_unit"] ?? 0).toDouble(),

          total: (item["total_price"] ?? 0).toDouble(),

          category: item["category"] ?? "другое",
        ),
      );
    }

    DateTime? date;

    String? time;

    if (json["time"] != null) {
      time = json["time"].toString();
    }

    if (json["date"] != null && json["date"].toString().isNotEmpty) {
      final parts = json["date"].toString().split(".");

      date = DateTime(
        int.parse(parts[2]),

        int.parse(parts[1]),

        int.parse(parts[0]),
      );
    }

    return ParsedReceipt(
      date: date,

      time: time,

      shop: json["store"] ?? "",

      paymentType: json["payment_type"] ?? "",

      items: items,

      totalAmount: (json["total_amount"] ?? 0).toDouble(),
    );
  }
}
