import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'dart:convert';

class EmbeddingModel extends Equatable {
  final String id;
  final String sourceType; // 'receipt', 'memory_note', 'operation' и др.
  final String sourceId;
  final String content; // текст, по которому ищем
  final Uint8List vector; // BLOB (Float32Array)
  final String model; // модель эмбеддинга
  final int embeddingVersion; // версия для возможности миграции
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime sourceUpdatedAt; // время последнего обновления источника
  final DateTime embeddingUpdatedAt; // время последнего обновления эмбеддинга
  final Map<String, dynamic> metadata; // JSON с метаданными для отображения

  const EmbeddingModel({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.content,
    required this.vector,
    required this.model,
    required this.embeddingVersion,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceUpdatedAt,
    required this.embeddingUpdatedAt,
    required this.metadata,
  });

  @override
  List<Object?> get props => [
    id,
    sourceType,
    sourceId,
    sourceUpdatedAt,
    embeddingUpdatedAt,
  ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'content': content,
      'vector': vector,
      'model': model,
      'embeddingVersion': embeddingVersion,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sourceUpdatedAt': sourceUpdatedAt.toIso8601String(),
      'embeddingUpdatedAt': embeddingUpdatedAt.toIso8601String(),
      'metadata': jsonEncode(metadata),
    };
  }

  factory EmbeddingModel.fromMap(Map<String, dynamic> map) {
    return EmbeddingModel(
      id: map['id'] as String,
      sourceType: map['sourceType'] as String,
      sourceId: map['sourceId'] as String,
      content: map['content'] as String,
      vector: map['vector'] as Uint8List,
      model: map['model'] as String,
      embeddingVersion: map['embeddingVersion'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      sourceUpdatedAt: DateTime.parse(map['sourceUpdatedAt'] as String),
      embeddingUpdatedAt: DateTime.parse(map['embeddingUpdatedAt'] as String),
      metadata: jsonDecode(map['metadata'] as String) as Map<String, dynamic>,
    );
  }

  // Клонирование с новым вектором и временем обновления
  EmbeddingModel copyWith({
    Uint8List? vector,
    DateTime? updatedAt,
    DateTime? embeddingUpdatedAt,
    String? content,
    Map<String, dynamic>? metadata,
  }) {
    return EmbeddingModel(
      id: id,
      sourceType: sourceType,
      sourceId: sourceId,
      content: content ?? this.content,
      vector: vector ?? this.vector,
      model: model,
      embeddingVersion: embeddingVersion,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      sourceUpdatedAt: sourceUpdatedAt,
      embeddingUpdatedAt: embeddingUpdatedAt ?? DateTime.now(),
      metadata: metadata ?? this.metadata,
    );
  }
}
