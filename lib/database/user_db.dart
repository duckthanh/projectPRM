import '../models/user_model.dart';
import 'database_helper.dart';

class UserDB {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertUser(UserModel user) async {
    final db = await _dbHelper.database;
    return await db.insert('users', user.toMap());
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await _dbHelper.database;
    final result = await db.query('users');
    return result.map((map) => UserModel.fromMap(map)).toList();
  }

  Future<int> updateUser(UserModel user) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<UserModel?> login(String phoneNumber, String password) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'users',
      where: 'phone_number = ? AND password = ?',
      whereArgs: [phoneNumber, password],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  Future<UserModel?> getUserByPhone(String phoneNumber) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'users',
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  Future<bool> isPhoneNumberExists(String phoneNumber) async {
    final user = await getUserByPhone(phoneNumber);
    return user != null;
  }

  Future<int> getUsersCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return result.first['count'] as int? ?? 0;
  }
}
