import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';

class AccountRepository {
  static const String _key = 'accounts';

  Future<List<Account>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);

    if (data == null) {
      final defaults = Account.getDefaultAccounts();
      await saveAccounts(defaults);
      return defaults;
    }

    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => Account.fromJson(json)).toList();
  }

  Future<void> saveAccounts(List<Account> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await prefs.setString(_key, data);
  }

  Future<void> addAccount(Account account) async {
    final accounts = await getAccounts();
    accounts.add(account);
    await saveAccounts(accounts);
  }

  Future<void> updateAccount(Account account) async {
    final accounts = await getAccounts();
    final index = accounts.indexWhere((a) => a.id == account.id);
    if (index != -1) {
      accounts[index] = account;
      await saveAccounts(accounts);
    }
  }

  Future<void> deleteAccount(String id) async {
    final accounts = await getAccounts();
    accounts.removeWhere((a) => a.id == id);
    await saveAccounts(accounts);
  }

  Future<Account?> getAccountById(String id) async {
    final accounts = await getAccounts();
    try {
      return accounts.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }
}
