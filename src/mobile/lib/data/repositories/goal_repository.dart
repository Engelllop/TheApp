import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal.dart';

class GoalRepository {
  static const String _key = 'goals';

  Future<List<Goal>> getGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);

    if (data == null) return [];

    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => Goal.fromJson(json)).toList();
  }

  Future<void> saveGoals(List<Goal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(goals.map((g) => g.toJson()).toList());
    await prefs.setString(_key, data);
  }

  Future<void> addGoal(Goal goal) async {
    final goals = await getGoals();
    goals.add(goal);
    await saveGoals(goals);
  }

  Future<void> updateGoal(Goal goal) async {
    final goals = await getGoals();
    final index = goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      goals[index] = goal;
      await saveGoals(goals);
    }
  }

  Future<void> deleteGoal(String id) async {
    final goals = await getGoals();
    goals.removeWhere((g) => g.id == id);
    await saveGoals(goals);
  }

  Future<void> addToGoal(String id, double amount) async {
    final goals = await getGoals();
    final index = goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      goals[index] = goals[index].copyWith(
        current: goals[index].current + amount,
      );
      await saveGoals(goals);
    }
  }
}
