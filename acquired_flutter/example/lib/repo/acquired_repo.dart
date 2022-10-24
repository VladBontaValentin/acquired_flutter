import 'dart:convert';

import 'package:example/model/payment_method.dart';
import 'package:flutter/services.dart';

class AcquiredRepo {
  final methodChannel = const MethodChannel('acquired_flutter/method_calls');

  Future<void> payByCard() async {
    try {
      var success = await methodChannel.invokeMethod('getBatteryLevel', []);
      print('PAYMENT RESPONSE: ${success}');
      if (success) {
        print('SUCCESS PAYMENT');
      } else {
        print('FAILURE PAYMENT');
      }
    } catch (e) {
      print(e);
    }
  }
  Future<void> payByNativePay() async {
    try {
      var success = await methodChannel.invokeMethod('nativePay', []);
      print('PAYMENT RESPONSE: ${success}');
      if (success) {
        print('SUCCESS PAYMENT');
      } else {
        print('FAILURE PAYMENT');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<List<PaymentMethod>> getAvailablePaymentMethods() async {
    try {
      var paymentMethodsResponse =
          await methodChannel.invokeMethod('getAvailablePaymentMethods', []);

      List<dynamic> paymentMethodsList = [];
      if (paymentMethodsResponse is String) {
        if (json.decode(paymentMethodsResponse) is List<dynamic>) {
          paymentMethodsList =
              json.decode(paymentMethodsResponse) as List<dynamic>;
        }
      }
      List<PaymentMethod> paymentMethods =
          PaymentMethodList.paymentMethodsFromJson(paymentMethodsList);
      return paymentMethods;
    } catch (e) {
      print("ERRROR: $e ${e.runtimeType}");
      if (e is CastError) {
        print("ERRROR: ${e.stackTrace}");
      }
    }
    return [];
  }
}
