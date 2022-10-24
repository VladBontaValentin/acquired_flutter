import UIKit
import Flutter
import ACQPaymentGateway


@available(iOS 13.0, *)
@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    private let paymentManager = PaymentManager()
    private var paymentMethods: [PaymentMethod] = []
    private var currency: Currency?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        getData()
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let batteryChannel = FlutterMethodChannel(name: "acquired_flutter/method_calls",
                                                  binaryMessenger: controller.binaryMessenger)
        batteryChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            switch call.method{
            case "getBatteryLevel":
                self?.receiveBatteryLevel(result: result)
                return
            case "getAvailablePaymentMethods":
                self?.getAvailablePaymentMethods(result: result)
                
                return
            default:
                result(FlutterMethodNotImplemented)
                
                return
            }
            
        })
        
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: UISceneSession Lifecycle
    
    //    override func application(
    //        _ application: UIApplication,
    //        configurationForConnecting connectingSceneSession: UISceneSession,
    //        options: UIScene.ConnectionOptions
    //    ) -> UISceneConfiguration {
    //        // Called when a new scene session is being created.
    //        // Use this method to select a configuration to create the new scene with.
    //        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    //    }
    //
    //    override func application(
    //        _ application: UIApplication,
    //        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    //    ) {
    //        // Called when the user discards a scene session.
    //        // If any sessions were discarded while the application was not running, this will be called shortly
    //        // after application:didFinishLaunchingWithOptions.
    //        // Use this method to release any resources that were specific to the discarded scenes,
    //        // as they will not return.
    //    }
    //
    
    private let cardChangeCompletion: ChangedPaymentCardCompletion = { paymentCard, update in
        var summaryItems = ShippingDetails.ukOrderSummaryItems
        if case .credit = paymentCard.type {
            summaryItems.append(OrderSummaryItem.creditCardSurcharge)
        }
        let paymentRequestPaymentCardUpdate = PaymentRequestPaymentCardUpdate(
            errors: [],
            paymentSummaryItems: summaryItems
        )
        update(paymentRequestPaymentCardUpdate)
    }
    private func receiveBatteryLevel(result: FlutterResult) {
        
        var paymentMethod = paymentMethods.last;
        if (paymentMethod != nil){
            paymentManager.pay(withWindow: window, with: paymentMethod!) { result in
                switch result {
                case .success(let data):
                    print("data: \(String(describing: data))")
                    //                displaySuccess()
                    
                case .failure(let error):
                    print("ERRROR")
                    //                display(error: error)
                }
            }
        }
        
        
        //      let device = UIDevice.current
        //      device.isBatteryMonitoringEnabled = true
        //      if device.batteryState == UIDevice.BatteryState.unknown {
        //        result(FlutterError(code: "UNAVAILABLE",
        //                            message: "Battery level not available.",
        //                            details: nil))
        //      } else {
        //        result(Int(device.batteryLevel * 100))
        //      }
    }
    
    private func getAvailablePaymentMethods(result:@escaping FlutterResult) {
        
        
        paymentManager.getPaymentData {
            switch $0 {
            case let .success(paymentData):
                self.paymentMethods = paymentData.availablePaymentMethods.filter({ $0.isActive == true })
                self.currency = paymentData.currency
                var array: Array<Dictionary<String, String>> = Array()
                self.paymentMethods.forEach { method in
                    array.append(self.paymentMethodJson(from: method));
                }
                
                
                result(self.json(from: array))
                
            case let .failure(error):
                print("ERROR GET PAYMENTS DATA: \(String(describing: error))")
                
                result(FlutterError(code: "UNAVAILABLE",
                                    message: "Available payment methods not available",
                                    details: error))
                //                display(error: error)
            }
        }
        
    }
    
    func json(from object:Any) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return nil
        }
        return String(data: data, encoding: String.Encoding.utf8)
    }
    func paymentMethodJson(from paymentMethod:PaymentMethod) -> Dictionary<String, String> {
        var supportedNetworks : Array<String> = paymentMethod.supportedNetworks.map({ network in
            
            return network.rawValue;
        });
        return [
            "isAdditionalDataInputRequired":"\(paymentMethod.isAdditionalDataInputRequired)",
            "nameKey":paymentMethod.nameKey,
            "isActive":"\(paymentMethod.isActive)",
            "supportedNetworks":"\(self.json(from:supportedNetworks))",
        ]
    }
    
    func getData() {
        paymentManager.getPaymentData {
            switch $0 {
            case let .success(paymentData):
                self.paymentMethods = paymentData.availablePaymentMethods.filter({ $0.isActive == true })
                self.currency = paymentData.currency
                
            case let .failure(error):
                print("ERROR GET PAYMENTS DATA: \(String(describing: error))")
                
                //                display(error: error)
            }
        }
    }
    
    /// Pay
    /// - Parameters:
    ///   - paymentMethod: The PaymentMethod to use for the payment
    ///   - completion: Details of the Order or Error
    func pay(
        with paymentMethod: PaymentMethod,
        completion: @escaping (Result<Order, Error>) -> Void
    ) {
        
        var paymentManager = PaymentManager();
        paymentManager.pay(withWindow: window, with: paymentMethod, completion: completion)
        
        
    }
    
}




