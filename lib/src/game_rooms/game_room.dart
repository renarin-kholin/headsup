import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class WordItem {
  final String word;
  final String? imagePath;
  final String? imageBase64;

  const WordItem({required this.word, this.imagePath, this.imageBase64});

  bool get hasImage => imagePath != null || imageBase64 != null;

  Map<String, dynamic> toJson() => {
        'word': word,
        'imagePath': imagePath,
        'imageBase64': imageBase64,
      };

  factory WordItem.fromJson(Map<String, dynamic> json) => WordItem(
        word: json['word'] as String,
        imagePath: json['imagePath'] as String?,
        imageBase64: json['imageBase64'] as String?,
      );

  WordItem copyWith({String? word, String? imagePath, String? imageBase64}) =>
      WordItem(
        word: word ?? this.word,
        imagePath: imagePath ?? this.imagePath,
        imageBase64: imageBase64 ?? this.imageBase64,
      );
}

class GameRoom {
  final String id;
  final String name;
  final List<WordItem> items;
  final int difficulty;
  final DateTime createdAt;

  GameRoom({
    required this.id,
    required this.name,
    required this.items,
    this.difficulty = 5,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  List<String> get words => items.map((i) => i.word).toList();
  List<String> get imagePaths => items.map((i) => i.imagePath ?? '').toList();

  GameRoom copyWith({
    String? id,
    String? name,
    List<WordItem>? items,
    int? difficulty,
    DateTime? createdAt,
  }) {
    return GameRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((i) => i.toJson()).toList(),
      'difficulty': difficulty,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GameRoom.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? json['words'] as List? ?? [];
    final List<WordItem> items;

    if (itemsList.isNotEmpty && itemsList.first is Map<String, dynamic>) {
      items = itemsList.map((i) => WordItem.fromJson(i)).toList();
    } else {
      items = itemsList.map((word) => WordItem(word: word as String)).toList();
    }

    return GameRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      items: items,
      difficulty: json['difficulty'] as int? ?? 5,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static String encode(List<GameRoom> rooms) {
    return jsonEncode(rooms.map((r) => r.toJson()).toList());
  }

  static List<GameRoom> decode(String jsonString) {
    if (jsonString.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => GameRoom.fromJson(json)).toList();
  }

  static Future<String> get _customImagesPath async {
    final dir = await getApplicationDocumentsDirectory();
    final customDir = Directory('${dir.path}/custom_images');
    if (!await customDir.exists()) {
      await customDir.create(recursive: true);
    }
    return customDir.path;
  }

  static Future<String> saveImage(File imageFile, String roomId) async {
    final path = await _customImagesPath;
    final fileName = '${roomId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = await imageFile.copy('$path/$fileName');
    return savedFile.path;
  }

  static Future<void> deleteRoomImages(String roomId) async {
    final path = await _customImagesPath;
    final dir = Directory(path);
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.contains(roomId)) {
          await entity.delete();
        }
      }
    }
  }
}
