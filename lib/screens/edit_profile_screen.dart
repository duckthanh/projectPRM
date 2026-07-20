import 'dart:convert';

import 'package:flutter/material.dart';

import '../api/api_client.dart' show ApiClient, ApiException;
import '../api/school_class_api.dart';
import '../api/user_api.dart';
import '../models/school_class_model.dart';
import 'loginStyle.dart';

class EditProfileScreen extends StatefulWidget {
  final String initialFullName;
  final String initialPhone;
  final String? initialClassName;

  const EditProfileScreen({
    super.key,
    required this.initialFullName,
    required this.initialPhone,
    this.initialClassName,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final UserApi _userApi = UserApi(ApiClient());
  final SchoolClassApi _classApi = SchoolClassApi(ApiClient());
  late final Future<List<SchoolClassModel>> _classesFuture;
  String? _selectedClassName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialFullName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    final raw = widget.initialClassName?.trim();
    _selectedClassName = (raw == null || raw.isEmpty) ? null : raw;
    _classesFuture = _classApi.getAllClasses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String?>> _buildClassItems(List<SchoolClassModel> classes) {
    final active = classes.where((c) => c.active).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('Chưa chọn'),
      ),
    ];
    final knownNames = active.map((c) => c.name).toSet();
    if (_selectedClassName != null &&
        _selectedClassName!.isNotEmpty &&
        !knownNames.contains(_selectedClassName)) {
      items.add(
        DropdownMenuItem<String?>(
          value: _selectedClassName,
          child: Text(_selectedClassName!, overflow: TextOverflow.ellipsis),
        ),
      );
    }
    items.addAll(
      active.map(
        (c) => DropdownMenuItem<String?>(
          value: c.name,
          child: Text(c.name, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
    return items;
  }

  String? _effectiveDropdownValue(List<DropdownMenuItem<String?>> items) {
    final allowed = items.map((e) => e.value).toSet();
    if (_selectedClassName == null) return null;
    if (allowed.contains(_selectedClassName)) return _selectedClassName;
    return null;
  }

  bool _validPhone(String s) {
    final t = s.trim();
    if (t.length < 9 || t.length > 12) return false;
    return RegExp(r'^[0-9]+$').hasMatch(t);
  }

  String _errorMessage(Object e) {
    if (e is ApiException) {
      try {
        final m = jsonDecode(e.body) as Map<String, dynamic>;
        return m['message']?.toString() ?? e.body;
      } catch (_) {
        return e.body;
      }
    }
    return e.toString();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = await _userApi.updateMyProfile(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        className: _selectedClassName ?? '',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu thông tin')),
      );
      Navigator.pop(context, user);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(e)), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginStyle.backgroundColor,
      appBar: AppBar(
        title: const Text('Chỉnh sửa thông tin'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.black),
                decoration: LoginStyle.buildTextFieldDecoration(
                  hint: 'Họ và tên',
                  icon: Icons.person_outline,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập họ tên';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.black),
                decoration: LoginStyle.buildTextFieldDecoration(
                  hint: 'Số điện thoại',
                  icon: Icons.phone_outlined,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
                  if (!_validPhone(v)) return 'Số điện thoại không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<SchoolClassModel>>(
                future: _classesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Không tải danh sách lớp (${snapshot.error})',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    );
                  }
                  final classes = snapshot.data ?? [];
                  final items = _buildClassItems(classes);
                  final currentValue = _effectiveDropdownValue(items);
                  return DropdownButtonFormField<String?>(
                    key: ValueKey<String?>('$currentValue-${items.length}'),
                    initialValue: currentValue,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.black, fontSize: 15),
                    decoration: LoginStyle.buildTextFieldDecoration(
                      hint: 'Chọn lớp',
                      icon: Icons.class_outlined,
                    ),
                    items: items,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _selectedClassName = v),
                  );
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: LoginStyle.loginButtonStyle,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Lưu thay đổi', style: LoginStyle.loginButtonTextStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
