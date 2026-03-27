import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedFilter {
  final String id;
  final String name;
  final String? accountId;
  final String? category;
  final bool? isExpense;
  final DateTime? fromDate;
  final DateTime? toDate;
  final double? minAmount;
  final double? maxAmount;

  SavedFilter({
    required this.id,
    required this.name,
    this.accountId,
    this.category,
    this.isExpense,
    this.fromDate,
    this.toDate,
    this.minAmount,
    this.maxAmount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'accountId': accountId,
        'category': category,
        'isExpense': isExpense,
        'fromDate': fromDate?.toIso8601String(),
        'toDate': toDate?.toIso8601String(),
        'minAmount': minAmount,
        'maxAmount': maxAmount,
      };

  factory SavedFilter.fromJson(Map<String, dynamic> json) => SavedFilter(
        id: json['id'],
        name: json['name'],
        accountId: json['accountId'],
        category: json['category'],
        isExpense: json['isExpense'],
        fromDate:
            json['fromDate'] != null ? DateTime.parse(json['fromDate']) : null,
        toDate: json['toDate'] != null ? DateTime.parse(json['toDate']) : null,
        minAmount: json['minAmount']?.toDouble(),
        maxAmount: json['maxAmount']?.toDouble(),
      );

  SavedFilter copyWith({
    String? id,
    String? name,
    String? accountId,
    String? category,
    bool? isExpense,
    DateTime? fromDate,
    DateTime? toDate,
    double? minAmount,
    double? maxAmount,
  }) {
    return SavedFilter(
      id: id ?? this.id,
      name: name ?? this.name,
      accountId: accountId ?? this.accountId,
      category: category ?? this.category,
      isExpense: isExpense ?? this.isExpense,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
    );
  }

  static SavedFilter get defaultExpenses => SavedFilter(
        id: 'default_expenses',
        name: 'Solo gastos',
        isExpense: true,
      );

  static SavedFilter get defaultIncomes => SavedFilter(
        id: 'default_incomes',
        name: 'Solo ingresos',
        isExpense: false,
      );

  static SavedFilter get thisMonth => SavedFilter(
        id: 'this_month',
        name: 'Este mes',
        fromDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
        toDate: DateTime.now(),
      );
}

class SavedFiltersService extends ChangeNotifier {
  static const String _key = 'saved_filters';
  List<SavedFilter> _filters = [];
  bool _isLoaded = false;

  List<SavedFilter> get filters => _filters;
  List<SavedFilter> get defaultFilters => [
        SavedFilter.defaultExpenses,
        SavedFilter.defaultIncomes,
        SavedFilter.thisMonth,
      ];

  List<SavedFilter> get allFilters => [...defaultFilters, ..._filters];

  Future<void> loadFilters() async {
    if (_isLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);

    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      _filters = jsonList.map((json) => SavedFilter.fromJson(json)).toList();
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_filters.map((f) => f.toJson()).toList());
    await prefs.setString(_key, data);
  }

  Future<void> addFilter(SavedFilter filter) async {
    final newFilter = SavedFilter(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: filter.name,
      accountId: filter.accountId,
      category: filter.category,
      isExpense: filter.isExpense,
      fromDate: filter.fromDate,
      toDate: filter.toDate,
      minAmount: filter.minAmount,
      maxAmount: filter.maxAmount,
    );

    _filters.add(newFilter);
    await _saveFilters();
    notifyListeners();
  }

  Future<void> updateFilter(SavedFilter filter) async {
    final index = _filters.indexWhere((f) => f.id == filter.id);
    if (index != -1) {
      _filters[index] = filter;
      await _saveFilters();
      notifyListeners();
    }
  }

  Future<void> deleteFilter(String id) async {
    _filters.removeWhere((f) => f.id == id);
    await _saveFilters();
    notifyListeners();
  }

  Future<void> reorderFilters(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final item = _filters.removeAt(oldIndex);
    _filters.insert(newIndex, item);
    await _saveFilters();
    notifyListeners();
  }
}
