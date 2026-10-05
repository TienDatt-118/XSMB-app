import 'package:flutter/material.dart';
import '../repository/admin_repository.dart';
import '../services/storage_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _repository;
  final StorageService _storageService;

  AdminProvider(this._repository, this._storageService) {
    _loadSavedTokenAndVerify();
  }

  bool _isAdmin = false;
  bool _isExecuting = false;
  String _executionMessage = '';
  String _adminToken = '';

  bool get isAdmin => _isAdmin;
  bool get isExecuting => _isExecuting;
  String get executionMessage => _executionMessage;
  String get adminToken => _adminToken;

  // Load saved token on startup
  Future<void> _loadSavedTokenAndVerify() async {
    final token = await _storageService.getAdminToken();
    if (token != null && token.isNotEmpty) {
      _adminToken = token;
      _isAdmin = await _repository.checkAdminPermission(token);
      notifyListeners();
    }
  }

  // Verify and log in as admin
  Future<bool> loginAdmin(String token) async {
    _isExecuting = true;
    _executionMessage = 'Đang xác thực quyền Admin...';
    notifyListeners();

    try {
      final isValid = await _repository.checkAdminPermission(token);
      if (isValid) {
        _isAdmin = true;
        _adminToken = token;
        await _storageService.saveAdminToken(token);
        _executionMessage = 'Xác thực Admin thành công!';
        notifyListeners();
        return true;
      } else {
        _isAdmin = false;
        _executionMessage = 'Mã token Admin không chính xác.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _executionMessage = 'Không thể kết nối xác thực: $e';
      notifyListeners();
      return false;
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  // Run artisan commands
  Future<void> runCommand(String cmd) async {
    _isExecuting = true;
    _executionMessage = 'Đang thực thi lệnh: $cmd...';
    notifyListeners();

    try {
      final responseMsg = await _repository.executeCommand(cmd);
      _executionMessage = responseMsg;
    } catch (e) {
      _executionMessage = 'Lỗi thực thi: $e';
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  // Logout admin
  Future<void> logoutAdmin() async {
    _isAdmin = false;
    _adminToken = '';
    await _storageService.deleteAdminToken();
    _executionMessage = 'Đã thoát chế độ Admin';
    notifyListeners();
  }
}
