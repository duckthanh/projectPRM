import 'package:flutter/material.dart';

class LoginStyle {
  // Colors
  static const Color backgroundColor = Color(0xFF5C79E0);
  static const Color primaryColor = Color(0xFF1E75F6);
  static const Color textColor = Colors.black;
  static const Color whiteColor = Colors.white;

  // Sửa lại hàm buildBackgroundLayers để có kích thước xác định
  static Widget buildBackgroundLayers(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      // Ép chiều cao cố định để Stack không bị lỗi "unbounded height"
      height: 550,
      width: screenWidth,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lớp nền thứ nhất (Dưới cùng)
          Container(
            width: screenWidth * 0.9,
            height: 520,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          // Lớp nền thứ hai (Ở giữa)
          Positioned(
            top: 20, // Tăng nhẹ khoảng cách để lộ rõ layer dưới
            child: Container(
              width: screenWidth * 0.86, // Thu nhỏ hơn layer 1 một chút
              height: 510,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Giữ nguyên các phần trang trí khác
  static BoxDecoration get mainCardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 15,
        offset: const Offset(0, 8),
      )
    ],
  );

  static InputDecoration buildTextFieldDecoration({
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      // Thêm nút ẩn/hiện mật khẩu nếu cần thiết
      suffixIcon: isPassword
          ? const Icon(Icons.visibility_off_outlined, color: Colors.grey, size: 20)
          : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  static ButtonStyle get loginButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
    shadowColor: primaryColor.withOpacity(0.4),
  );

  static ButtonStyle get ssoButtonStyle => OutlinedButton.styleFrom(
    side: const BorderSide(color: primaryColor, width: 1.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  static const TextStyle titleTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textColor,
    letterSpacing: 0.5,
  );

  static const TextStyle loginButtonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle ssoButtonTextStyle = TextStyle(
    color: primaryColor,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle forgotPasswordTextStyle = TextStyle(
    color: primaryColor,
    fontWeight: FontWeight.w500,
    fontSize: 13,
  );
}