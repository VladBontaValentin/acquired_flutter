import 'package:example/repo/acquired_repo.dart';
import 'package:flutter/material.dart';

import 'model/payment_method.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Acquired Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Acquired Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AcquiredRepo acquiredRepo = AcquiredRepo();
  List<PaymentMethod> _paymentMethods = [];

  void _applePay() async {
    await acquiredRepo.payByNativePay();

  }

  void _cardPay() async {
    await acquiredRepo.payByCard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _availablePaymentsButton(),
            _paymentMethodsWidget(),

          ],
        ),
      ),
    );
  }

  Widget _payButton(bool nativePayment) {
    return TextButton(
      child: Container(
        decoration: BoxDecoration(
          // color: Colors.red,
          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
          border: Border.all(color: Colors.black),
        ),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(
          nativePayment ? "Pay with Apple Pay" : "Pay by card",
        ),
      ),
      onPressed: () {
        if (nativePayment) {
          _applePay();
        } else {
          _cardPay();
        }
      },
    );
  }

  Widget _availablePaymentsButton() {
    return TextButton(
      child: Container(
        decoration: BoxDecoration(
          // color: Colors.red,
          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
          border: Border.all(color: Colors.black),
        ),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(
          "Fetch available payment methods",
        ),
      ),
      onPressed: () {
        acquiredRepo.getAvailablePaymentMethods().then((paymentMethods) {
          setState(() {
            _paymentMethods = paymentMethods;
          });
        });
      },
    );
  }

  Widget _paymentMethodsWidget() {

    List<Widget> payments = [];
    if (_paymentMethods.map((t) => t.nameKey).contains("apple_pay")) {
      payments.add(_payButton(true));
    }
    if (_paymentMethods.map((t) => t.nameKey).contains("card")) {
      payments.add(_payButton(false));
    }
    return Column(
      children: payments,
    );
  }
}
