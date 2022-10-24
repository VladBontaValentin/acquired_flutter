import 'dart:core';

class PaymentMethod {
  final String nameKey;
  final bool isActive;
  final List<String> supportedNetworks;
  final bool isAdditionalDataInputRequired;

  PaymentMethod(
    this.nameKey,
    this.isActive,
    this.supportedNetworks,
    this.isAdditionalDataInputRequired,
  );

  factory PaymentMethod.fromJson(Map<String, dynamic> data) {
    // List<String> supportedNetworks= data["supportedNetworks"];
    print("DATA :${data}");
    return PaymentMethod(
      data["nameKey"] ?? "",
      BoolExtension.boolValueFromString(data["isActive"]),
      [],
      BoolExtension.boolValueFromString(data["isAdditionalDataInputRequired"]),
    );
  }
}

extension PaymentMethodList on List<PaymentMethod> {
  static List<PaymentMethod> paymentMethodsFromJson(List<dynamic> data) {
    List<PaymentMethod> array = [];
    data.forEach((paymentMethodJson) {
      print(" paymentMethodJson: ${paymentMethodJson.runtimeType} ${paymentMethodJson}");
      if (paymentMethodJson is Map<String, dynamic>) {
        array.add(
            PaymentMethod.fromJson(paymentMethodJson as Map<String, dynamic>));
      }
    });
    return array;
  }
}

extension BoolExtension on bool {
  static boolValueFromString(String? data) {
    if (data == "true") {
      return true;
    }
    return false;
  }
}
