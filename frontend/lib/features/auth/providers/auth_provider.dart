import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/storage_service.dart';
import '../models/user.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);

class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final Map<String, dynamic> body = {
      'password': password,
    };
    if (identifier.contains('@')) {
      body['email'] = identifier.trim();
    } else {
      body['username'] = identifier.trim();
      body['email'] = identifier.trim();
    }

    final res = await _dio.post(
      '/api/auth/login',
      data: body,
    );

    if (res.data is Map<String, dynamic>) {
      return res.data as Map<String, dynamic>;
    }
    throw Exception('Invalid server response');
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final storage = ref.read(storageProvider);
    final token = storage.getToken();
    final role = storage.getRole();
    final userId = storage.getUserId();
    final userEmail = storage.getUserEmail();

    if (token != null && token.isNotEmpty && role != null) {
      return User(
        id: userId ?? 'restored_id',
        email: userEmail ?? 'user@restored.com',
        username: userEmail ?? 'user',
        role: role,
      );
    }
    return null;
  }

  Future<void> login(String identifier, String password) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final data = await repo.login(identifier, password);

      final token = data['token'] ?? data['accessToken'] ?? '';
      if (token.toString().isEmpty) {
        throw Exception('No authentication token received from server');
      }

      final userData = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : <String, dynamic>{'email': identifier, 'role': data['role'] ?? 'STUDENT'};

      final user = User.fromJson(userData);

      final storage = ref.read(storageProvider);
      await storage.saveToken(token.toString());
      await storage.saveRole(user.role);
      await storage.saveUserData(id: user.id, email: user.email);

      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    final storage = ref.read(storageProvider);
    await storage.clearToken();
    await storage.clearRole();
    state = const AsyncData(null);
  }
}
