import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_app/core/theme.dart';

class Tag {
  final String id;
  final String name;
  final String color;

  Tag({
    required this.id,
    required this.name,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
      };

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
        id: json['id'],
        name: json['name'],
        color: json['color'],
      );
}

class TagService extends ChangeNotifier {
  static const String _key = 'tags';
  List<Tag> _tags = [];
  bool _isLoaded = false;

  List<Tag> get tags => _tags;

  List<Tag> get defaultTags => [
        Tag(id: '1', name: 'Trabajo', color: '#457b9d'),
        Tag(id: '2', name: 'Personal', color: '#2a9d8f'),
        Tag(id: '3', name: 'Urgente', color: '#e63946'),
        Tag(id: '4', name: 'Planificado', color: '#e9c46a'),
        Tag(id: '5', name: 'Recurrente', color: '#f4a261'),
      ];

  Future<void> loadTags() async {
    if (_isLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);

    if (data == null) {
      _tags = defaultTags;
      await _saveTags();
    } else {
      final List<dynamic> jsonList = jsonDecode(data);
      _tags = jsonList.map((json) => Tag.fromJson(json)).toList();
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveTags() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_tags.map((t) => t.toJson()).toList());
    await prefs.setString(_key, data);
  }

  Future<void> addTag(String name, String color) async {
    final tag = Tag(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      color: color,
    );
    _tags.add(tag);
    await _saveTags();
    notifyListeners();
  }

  Future<void> updateTag(Tag tag) async {
    final index = _tags.indexWhere((t) => t.id == tag.id);
    if (index != -1) {
      _tags[index] = tag;
      await _saveTags();
      notifyListeners();
    }
  }

  Future<void> deleteTag(String id) async {
    _tags.removeWhere((t) => t.id == id);
    await _saveTags();
    notifyListeners();
  }

  Color getTagColor(Tag tag) {
    try {
      return Color(int.parse(tag.color.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.accentBlue;
    }
  }
}
