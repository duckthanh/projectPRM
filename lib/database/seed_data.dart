import '../models/user_model.dart';
import '../models/score_model.dart';
import '../models/timetable_model.dart';
import 'user_db.dart';
import 'database_helper.dart';
import 'package:sqflite/sqflite.dart';

class SeedData {
  static final UserDB _userDB = UserDB();
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Khởi tạo dữ liệu mẫu
  static Future<void> initializeSampleData() async {
    try {
      final db = await _dbHelper.database;
      
      // Kiểm tra xem đã có dữ liệu chưa
      final usersCount = await _userDB.getUsersCount();
      if (usersCount > 0) {
        return;
      }

      // Tạo user mẫu
      final user1 = UserModel(
        password: '123456',
        phoneNumber: '0123456789',
        fullName: 'Đỗ Xuan Phong',
        className: 'SE9999VJ',
        createdAt: DateTime.now().toIso8601String(),
      );
      final userId1 = await _userDB.insertUser(user1);

      final user2 = UserModel(
        password: '123456',
        phoneNumber: '0987654321',
        fullName: 'Phạm Đức Thành',
        className: 'SE9999VJ',
        createdAt: DateTime.now().toIso8601String(),
      );
      final userId2 = await _userDB.insertUser(user2);

    // Thêm điểm cho user1
    final scores1 = [
      ScoreModel(
        userId: userId1,
        subject: 'Toán',
        score: 8.5,
        coefficient: 2.0,
        createdAt: DateTime.now().toIso8601String(),
      ),
      ScoreModel(
        userId: userId1,
        subject: 'Ngữ văn',
        score: 7.8,
        coefficient: 2.0,
        createdAt: DateTime.now().toIso8601String(),
      ),
      ScoreModel(
        userId: userId1,
        subject: 'Tiếng Anh',
        score: 9.0,
        coefficient: 1.5,
        createdAt: DateTime.now().toIso8601String(),
      ),
      ScoreModel(
        userId: userId1,
        subject: 'Vật lý',
        score: 7.2,
        coefficient: 1.5,
        createdAt: DateTime.now().toIso8601String(),
      ),
      ScoreModel(
        userId: userId1,
        subject: 'Hóa học',
        score: 8.0,
        coefficient: 1.5,
        createdAt: DateTime.now().toIso8601String(),
      ),
      ScoreModel(
        userId: userId1,
        subject: 'Sinh học',
        score: 7.0,
        coefficient: 1.0,
        createdAt: DateTime.now().toIso8601String(),
      ),
      ScoreModel(
        userId: userId1,
        subject: 'Lịch sử',
        score: 8.3,
        coefficient: 1.0,
        createdAt: DateTime.now().toIso8601String(),
      ),
      ScoreModel(
        userId: userId1,
        subject: 'Địa lý',
        score: 8.1,
        coefficient: 1.0,
        createdAt: DateTime.now().toIso8601String(),
      ),
    ];

    for (var score in scores1) {
      await db.insert('scores', score.toMap());
    }

    // Thêm thời khóa biểu cho user1
    final timetable1 = [
      TimeTableModel(
        userId: userId1,
        dayOfWeek: 'Thứ 2',
        slot: 'Slot 1',
        subject: 'MLN122',
        room: 'BE217',
      ),
      TimeTableModel(
        userId: userId1,
        dayOfWeek: 'Thứ 2',
        slot: 'Slot 2',
        subject: 'PRM393',
        room: 'BE310',
      ),
      TimeTableModel(
        userId: userId1,
        dayOfWeek: 'Thứ 3',
        slot: 'Slot 1',
        subject: 'EXE201',
        room: 'DE315',
      ),
      TimeTableModel(
        userId: userId1,
        dayOfWeek: 'Thứ 4',
        slot: 'Slot 2',
        subject: 'MSS301',
        room: 'DE-C405',
      ),
      TimeTableModel(
        userId: userId1,
        dayOfWeek: 'Thứ 5',
        slot: 'Slot 1',
        subject: 'PRM393',
        room: 'DE-C405',
      ),
      TimeTableModel(
        userId: userId1,
        dayOfWeek: 'Thứ 5',
        slot: 'Slot 2',
        subject: 'MLN122',
        room: 'BE217',
      ),
      TimeTableModel(
        userId: userId1,
        dayOfWeek: 'Thứ 6',
        slot: 'Slot 1',
        subject: 'MSS301',
        room: 'DE-C405',
      ),
      TimeTableModel(
        userId: userId1,
        dayOfWeek: 'Thứ 7',
        slot: 'Slot 1',
        subject: 'Sinh hoạt lớp',
        room: 'P101',
      ),
      TimeTableModel(
        userId: userId1,
        dayOfWeek: 'Thứ 7',
        slot: 'Slot 2',
        subject: 'Hoạt động ngoại khóa',
        room: 'Sân trường',
      ),
    ];

      for (var tt in timetable1) {
        await db.insert('timetable', tt.toMap());
      }

      print('Đã tạo dữ liệu mẫu thành công!');
      print('User 1: 0123456789 / 123456');
      print('User 2: 0987654321 / 123456');
    } catch (e) {
      print('Lỗi khi khởi tạo database: $e');
    }
  }

  // Xóa tất cả dữ liệu (dùng để test)
  static Future<void> clearAllData() async {
    final db = await _dbHelper.database;
    await db.delete('scores');
    await db.delete('timetable');
    await db.delete('users');
    print('Đã xóa tất cả dữ liệu');
  }
}
