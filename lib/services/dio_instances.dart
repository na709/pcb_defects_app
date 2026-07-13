// lib/services/dio_instances.dart
import 'package:dio/dio.dart';
import 'package:doan_local/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:doan_local/utils/device_helper.dart';

class DioClient {
  //static final Dio deviceDio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:3000/api'));

  //static final Dio adminDio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:3000/api'));

  static final Dio deviceDio = Dio(BaseOptions(baseUrl: 'https://ckc.cntt.cloud:14019/api'));

  static final Dio adminDio = Dio(BaseOptions(baseUrl: 'https://ckc.cntt.cloud:14019/api'));

  // static final Dio deviceDio = Dio(BaseOptions(baseUrl: 'http://ckc.cntt.cloud:14011/api'));
  //
  // static final Dio adminDio = Dio(BaseOptions(baseUrl: 'http://ckc.cntt.cloud:14011/api'));

  static void setup() {
    debugPrint("--- ĐÃ KHỞI TẠO DIO INTERCEPTORS ---");
    deviceDio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final String? deviceId = await DeviceHelper.getDeviceId();
        options.headers['x-device-id'] = deviceId ?? "unknown";
        return handler.next(options);
      },
    ));

    adminDio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        String? token = await StorageService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          try {
            String? refreshToken = await StorageService.getRefreshToken();

            final response = await adminDio.post('/admin/refresh-token', data: {
              'refreshToken': refreshToken
            });

            final newAccessToken = response.data['accessToken'];
            await StorageService.saveAccessToken(newAccessToken);

            final options = e.requestOptions;
            options.headers['Authorization'] = 'Bearer $newAccessToken';

            final retryResponse = await adminDio.fetch(options);
            return handler.resolve(retryResponse);

          } catch (refreshError) {
            await StorageService.clearAll();
            debugPrint("Refresh token thất bại, vui lòng đăng nhập lại.");
            return handler.next(e);
          }
        }
        return handler.next(e);
      },
    ));
  }
}