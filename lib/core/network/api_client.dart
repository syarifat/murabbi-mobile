import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_endpoints.dart';
import '../theme/app_colors.dart';
import '../../features/auth/login_screen.dart';

class ApiClient {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          // Dynamic baseUrl update
          if (!options.path.startsWith('http')) {
            options.baseUrl = ApiEndpoints.baseUrl;
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // If token expired / unauthorized (HTTP 401) and not on a login attempt
          final isLoginRequest = e.requestOptions.path.contains('/login');
          if (e.response?.statusCode == 401 && !isLoginRequest) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('auth_token');
            await prefs.remove('user_role');
            await prefs.remove('user_name');

            final currentCtx = navigatorKey.currentContext;
            if (currentCtx != null && currentCtx.mounted) {
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
              ScaffoldMessenger.of(currentCtx).showSnackBar(
                const SnackBar(
                  content: Text('Sesi Anda telah berakhir. Silakan masuk kembali.'),
                  backgroundColor: AppColors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
          return handler.next(e);
        },
      ),
    );
  }
}
