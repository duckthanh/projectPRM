class AuthStorage {
  static String? _accessToken;
  static String? _refreshToken;
  static Map<String, dynamic>? _user;

  static String? get accessToken => _accessToken;
  static String? get refreshToken => _refreshToken;
  static Map<String, dynamic>? get user => _user;

  static void saveTokens({
    required String accessToken,
    required String refreshToken,
    Map<String, dynamic>? user,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _user = user;
  }

  static void clear() {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
  }

  /// Cập nhật map user sau khi PATCH /api/users/me (giữ roles và các trường khác).
  static void mergeUserFromProfile(Map<String, dynamic> profile) {
    if (_user == null) return;
    if (profile['id'] != null) _user!['id'] = profile['id'];
    if (profile['phoneNumber'] != null) _user!['phoneNumber'] = profile['phoneNumber'];
    if (profile['fullName'] != null) _user!['fullName'] = profile['fullName'];
    if (profile.containsKey('className')) _user!['className'] = profile['className'];
    if (profile['createdAt'] != null) _user!['createdAt'] = profile['createdAt'];
    if (profile.containsKey('twoFactorEnabled')) {
      _user!['twoFactorEnabled'] = profile['twoFactorEnabled'];
    }
  }

  static void applyProfileAndTokens({
    required Map<String, dynamic> profileUser,
    String? accessToken,
    String? refreshToken,
  }) {
    if (accessToken != null &&
        refreshToken != null &&
        accessToken.isNotEmpty &&
        refreshToken.isNotEmpty) {
      final merged = Map<String, dynamic>.from(_user ?? {});
      merged['id'] = profileUser['id'] ?? merged['id'];
      merged['phoneNumber'] = profileUser['phoneNumber'] ?? merged['phoneNumber'];
      merged['fullName'] = profileUser['fullName'] ?? merged['fullName'];
      merged['className'] = profileUser['className'];
      merged['createdAt'] = profileUser['createdAt'] ?? merged['createdAt'];
      if (profileUser.containsKey('twoFactorEnabled')) {
        merged['twoFactorEnabled'] = profileUser['twoFactorEnabled'];
      }
      saveTokens(accessToken: accessToken, refreshToken: refreshToken, user: merged);
    } else {
      mergeUserFromProfile(profileUser);
    }
  }

  static bool get isLoggedIn => _accessToken != null;

  /// Lấy danh sách roles của user
  static List<String> get roles {
    if (_user == null) return [];
    final rolesList = _user!['roles'];
    if (rolesList is List) {
      return rolesList.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Kiểm tra user có role cụ thể không
  static bool hasRole(String role) {
    return roles.contains(role);
  }

  /// Kiểm tra có phải giáo viên không
  static bool get isTeacher => hasRole('TEACHER');

  /// Kiểm tra có phải admin không
  static bool get isAdmin => hasRole('ADMIN');

  /// Kiểm tra có phải học sinh không
  static bool get isStudent => hasRole('USER') || hasRole('STUDENT');
}
