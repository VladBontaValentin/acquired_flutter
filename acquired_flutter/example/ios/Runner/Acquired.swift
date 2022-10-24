//
//  Acquired.swift
//  Runner
//
//  Created by Vlad Bonta on 19.10.2022.
//
import ACQPaymentGateway
import Foundation
import ACQNetworkSecurity
import Core
import TrustKit
import ACQPaymentGateway
import SwiftUI


extension Configuration {
    static func acquired() -> Configuration {
        guard let baseUrl = URL(string: "https://qaapi.acquired.com"),
              let baseHppRL = URL(string: "https://qahpp.acquired.com") else {
            fatalError("Acquired base URLAddresses must create URLs")
        }
        return Configuration(
            companyId: "459",
            companyPass: "re3vKdCG",
            companyHash: "cXaFMLbH",
            companyMidId: "1687",
            baseUrl: baseUrl,
            baseHppUrl: baseHppRL,
            // Rationale: constant needed
            // swiftlint:disable:next avoid_hardcoded_constants
            requestRetryAttempts: 3
        )
    }
}


import ACQPaymentGateway

// Rationale: Constants needed here
// swiftlint:disable avoid_hardcoded_constants
extension OrderSummaryItem {
    static let item1 = OrderSummaryItem(
        label: "Item 1",
        amount: 1802,
        state: .final
    )
    static let item2 = OrderSummaryItem(
        label: "Item 2",
        amount: 1000,
        state: .final
    )
    static let item3 = OrderSummaryItem(
        label: "Item 3",
        amount: 3000,
        state: .final
    )
    static let salesTax = OrderSummaryItem(
        label: "Sales tax",
        amount: 200,
        state: .final
    )
    static let creditCardSurcharge = OrderSummaryItem(
        label: "Credit Card Surcharge",
        amount: 300,
        state: .final
    )
    static let couponDiscountItem = OrderSummaryItem(
        label: "Coupon Discount Applied",
        amount: -300,
        state: .final
    )
}




/// TrustKit Certifcate Pinner - Uses Trustkit to Pin SSL certifcates during network communication
public class TrustKitCertificatePinner: CertificatePinner {
    private var trustKit: TrustKit
    /// A dictionary of SSL pinning results keyed by domain
    public private(set) var pinningResults: [String: PinningResult] = [:]
    
    /// Initilaize a new instance
    /// - Parameter config: A configuration file to set up the certificate pinning
    public init(_ config: PinningConfiguration) {
        if config.isLoggingEnabled {
            TrustKit.setLoggerBlock { message in
                PaymentSDKLogger.log(string: "\(message)", category: .certPinning, level: .debug)
            }
        }
        let trustKitConfig: [String: Any] = [
            kTSKSwizzleNetworkDelegates: false,
            kTSKPinnedDomains: config.domains.reduce(
                into: [:], { result, next in
                    result[next.domainName] = [
                        kTSKIncludeSubdomains: next.includeSubdomains,
                        kTSKExpirationDate: next.expirationDate,
                        kTSKPublicKeyHashes: next.publicKeyHashes,
                        kTSKReportUris: next.reportURIs
                    ]
                }
            )
        ]
        trustKit = TrustKit(configuration: trustKitConfig)
        trustKit.pinningValidatorCallback = { [weak self] result, _, _ in
            switch result.finalTrustDecision {
            case .shouldBlockConnection:
                self?.pinningResults[result.serverHostname] = .pinningFailed
                
            case .domainNotPinned:
                self?.pinningResults[result.serverHostname] = .notPinned
                
            case .shouldAllowConnection:
                self?.pinningResults[result.serverHostname] = .pinned
                
            @unknown default:
                assertionFailure("TrustKit returned an unknown finalTrustDecision")
            }
        }
    }
    /// Helper method for handling authentication challenges received within a `NSURLSessionDelegate`,
    /// `NSURLSessionTaskDelegate` or `WKNavigationDelegate`
    /// - Parameters:
    ///   - challenge: The authentication challenge,
    ///   supplied by the URL loading system to the delegate's challenge handler method.
    ///   - completionHandler: A closure to invoke to respond to the challenge,
    ///   supplied by the URL loading system to the delegate's challenge handler method.
    /// - Returns: YES` if the challenge was handled and the `completionHandler` was successfuly invoked. `
    /// NO` if the challenge could not be handled because it was not for server certificate validation
    /// (ie. the challenge's `authenticationMethod` was not `NSURLAuthenticationMethodServerTrust`).
    public func handle(
        _ challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) -> Bool {
        return trustKit.pinningValidator.handle(challenge, completionHandler: completionHandler)
    }
}





/// PaymentManager - a class to handle the payment logic outside of the View
@available(iOS 13.0, *)
class PaymentManager {
    
    enum Failure: Error {
        case unexpectedNilObject
        case windowNotASceneDelegate
    }
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
    /// Payment Gateway - The entry point for making payments with the SDK
    lazy var paymentGateway: PaymentGateway = {
        let gateway = PaymentGateway(
            configuration: Configuration.acquired(),
            certificatePinner: TrustKitCertificatePinner(.acquired),
            changedPaymentCardCompletion: cardChangeCompletion,
            presentationOptions: ViewControllerPresentationOptions(hasDismissButton: true)
        )
        if #available(iOS 15.0, *) {
            gateway.changedCouponCodeCompletion = { _, update in
                var summaryItems = ShippingDetails.ukOrderSummaryItems
                summaryItems.append(OrderSummaryItem.couponDiscountItem)
                let shippingMethods = ShippingDetails.ukShippingOptions
                let couponCodeUpdate = PaymentRequestCouponCodeUpdate(
                    errors: [],
                    paymentSummaryItems: summaryItems,
                    shippingMethods: shippingMethods
                )
                update(couponCodeUpdate)
            }
        }
        return gateway
    }()
    /// Summary of the order that the user is paying for
    @ObservedObject var orderSummary: OrderSummary = {
        return OrderSummary(
            lineItems: ShippingDetails.ukOrderSummaryItems,
            shippingMethods: ShippingDetails.ukShippingOptions,
            recipientName: "Acquired.com"
        )
    }()
    /// BillingContact for the payment
    var billingContact: Contact?
    
    /// Get the Payment Data
    func getPaymentData(
        completion: @escaping (Result<PaymentData, Error>) -> Void
    ) {
        paymentGateway.getPaymentData {
            switch $0 {
            case .success(let paymentData):
                completion(
                    .success(paymentData)
                )
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    private func createContact() -> Contact {
        let address = PostalAddress(
            street: "Street",
            subLocality: nil,
            city: "CITY",
            subAdministrativeArea: nil,
            administrativeArea: nil,
            postalCode: "407280",
            country: "RO",
            isoCountryCode: "RO"
        )
        return Contact(
            name: nil,
            postalAddress: address,
            phoneNumber: "0753832894",
            emailAddress: "vlad.bonta@gmail.com"
        )
    }
    /// Pay
    /// - Parameters:
    ///   - paymentMethod: The PaymentMethod to use for the payment
    ///   - completion: Details of the Order or Error
    func pay(
    withWindow window: UIWindow,
    with paymentMethod: PaymentMethod,
   completion: @escaping (Result<Order, Error>)-> Void)
    {
        
        //        guard let delegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
        //            let window = delegate.window else {
        //                completion(.failure(Failure.windowNotASceneDelegate))
        //            return
        //        }
//        guard let window = window,
//        else {
//            completion(.failure(Failure.windowNotASceneDelegate))
//            return
//        }
        billingContact = createContact()
        paymentGateway.pay(
            orderSummary: orderSummary,
            method: paymentMethod,
            transaction: ACQTransaction.uniqueExample(),
            window: window,
            shippingContact: Contact.sampleShipping,
            shippingOption: .enabled(
                completion: ShippingDetails.changedShippingContactCompletion
            ),
            billingContact: billingContact
        ) { [weak self] result in
            guard let self = self else {
                completion(.failure(Failure.unexpectedNilObject))
                return
            }
            completion(result)
            self.orderSummary.update(
                lineItems: ShippingDetails.ukOrderSummaryItems,
                shippingMethods: ShippingDetails.ukShippingOptions
            )
            self.billingContact = nil
        }
    }
}


extension ACQTransaction {
    static func uniqueExample() -> ACQTransaction {
        // This must be unique for each request
        // So using timeIntervalSince1970, removing "." which is not allowed
        var merchantOrderId = Date().timeIntervalSince1970.description
        // Rationale: Constants needed here and force try OK
        // swiftlint:disable:next avoid_hardcoded_constants force_try
        let dateOfBirth = try! CalendarDate(year: 1970, month: 3, day: 7)
        merchantOrderId = merchantOrderId.filter { $0 != "." }
        return ACQTransaction(
            transactionType: .authCapture,
            subscriptionType: .initial,
            merchantOrderId: merchantOrderId,
            merchantCustomerId: "5678",
            customerDateOfBirth: dateOfBirth,
            merchantContactUrl: "https://www.acquired.com",
            merchantCustom1: "custom1",
            merchantCustom2: "custom2",
            merchantCustom3: "custom3"
        )
    }
}



extension Contact {
    static let sampleShipping: Contact = {
        var name = PersonNameComponents()
        name.givenName = "Joe"
        name.familyName = "Bloggs"
        let address = PostalAddress(
            street: "A Street",
            subLocality: "A Sublocality",
            city: "A City",
            subAdministrativeArea: "A SubArea",
            administrativeArea: "A County",
            postalCode: "HP1 1AA",
            country: "UK",
            isoCountryCode: "GB"
        )
        return Contact(
            name: name,
            postalAddress: address,
            phoneNumber: "+447803177715",
            emailAddress: "test@test.com"
        )
    }()
}




import ACQPaymentGateway
import SwiftUI

@available(iOS 13.0, *)
struct AvailablePaymentsView: View {
    private let paymentManager = PaymentManager()
    // Rationale: Constants needed here
    // swiftlint:disable avoid_hardcoded_constants
    private let declinedCode = 301
    private let tdsFailureCode = 540
    // swiftlint:enable avoid_hardcoded_constants
    @State private var showModal = false
    @State private var shouldShowStatusAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var paymentMethods: [PaymentMethod] = []
    @State private var currency: Currency?
    
    private var total: AnyView {
        AnyView(
            HStack {
                Text(localizedString(from: "order_total"))
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(currency?.formatted(from: paymentManager.orderSummary.totalAmount) ?? "Error")
                    .bold()
            }
        )
    }
    
    private var itemslist: AnyView {
        AnyView(
            ForEach(Array(paymentManager.orderSummary.items.enumerated()), id: \.element.label) { item in
                HStack {
                    Text(item.element.label).frame(maxWidth: .infinity, alignment: .leading)
                    Text(currency?.formatted(from: item.element.amount) ?? "Error")
                }
            }
        )
    }
    
    private var paymentMethodsList: AnyView {
        AnyView(
            VStack {
                ForEach(paymentMethods, id: \.nameKey) { paymentMethod in
                    listItem(for: paymentMethod)
                        .onTapGesture {
                            if paymentMethod.isAdditionalDataInputRequired {
                                showModal = true
                                return
                            }
                            cellTapped(paymentMethod)
                        }
                }
            }
        )
    }
    
    private var alert: Alert {
        Alert(
            title: Text(alertTitle),
            message: Text(alertMessage),
            dismissButton: .default(Text(localizedString(from: "ok")))
        )
    }
    
    var body: some View {
        VStack {
            Text(localizedString(from: "payment_summary")).font(.title)
            itemslist.padding()
            total.padding()
            Spacer()
            Text(localizedString(from: "available_payment_types")).font(.title)
            paymentMethodsList
                .padding()
                .onAppear(perform: getData)
                .alert(isPresented: $shouldShowStatusAlert) { alert }
            Spacer()
            Text(versionAndBuild).font(.footnote)
        }
    }
    
    func listItem(for paymentMethod: PaymentMethod) -> AnyView {
        if paymentMethod as? ApplePayPaymentMethod != nil {
            return applePayListItem(for: paymentMethod)
        } else {
            return cardListItem(for: paymentMethod)
        }
    }
    
    func applePayListItem(for paymentMethod: PaymentMethod) -> AnyView {
        AnyView(
            HStack {
                textView(from: paymentMethod)
                ApplePayButton(type: .buy, style: .black, action: {}).fixedSize()
            }
        )
    }
    
    func cardListItem(for paymentMethod: PaymentMethod) -> AnyView {
        AnyView(
            HStack {
                textView(from: paymentMethod)
                Button(
                    localizedString(from: "pay"),
                    action: {
                        showModal = paymentMethod.isAdditionalDataInputRequired
                    }
                )
                .sheet(isPresented: $showModal) {
                    //                    createCustomerInputView(for: paymentMethod)
                    //                    .onDisappear(
                    //                        perform: {
                    //                            guard paymentManager.billingContact != nil else {
                    //                                display(error: PaymentError(.userCancelled))
                    //                                return
                    //                            }
                    //                            cellTapped(paymentMethod)
                    //                        }
                    //                    )
                }
            }
        )
    }
    
    private func textView(from paymentMethod: PaymentMethod) -> AnyView {
        var key = paymentMethod.nameKey
        if key.isEmpty {
            key = "unmapped_payment_type"
        }
        // Rationale: dynamic strings required
        // swiftlint:disable:next nslocalizedstring_key
        let textString = NSLocalizedString(key, comment: key)
        return AnyView(
            Text(textString)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.systemBackground))
        )
    }
    
    //    private func createCustomerInputView(for paymentMethod: PaymentMethod) -> CustomerInputView? {
    //        if paymentMethod as? ACQWebCardPaymentMethod != nil {
    //            return CustomerInputView {
    //                paymentManager.billingContact = $0
    //                showModal = false
    //            }
    //        }
    //        return nil
    //    }
    
    private func cellTapped(_ paymentMethod: PaymentMethod) {
        pay(with: paymentMethod)
    }
    
    func getData() {
        paymentManager.getPaymentData {
            switch $0 {
            case let .success(paymentData):
                paymentMethods = paymentData.availablePaymentMethods.filter({ $0.isActive == true })
                currency = paymentData.currency
                
            case let .failure(error):
                display(error: error)
            }
        }
    }
    
    func pay(with paymentMethod: PaymentMethod) {
//        paymentManager.pay( with: paymentMethod) { result in
//            switch result {
//            case .success(let data):
//                print("data: \(String(describing: data))")
//                displaySuccess()
//                
//            case .failure(let error):
//                display(error: error)
//            }
//        }
    }
    
    private func display(error: Error) {
        shouldShowStatusAlert = true
        alertTitle = localizedString(from: "error")
        switch error {
        case let declined as PaymentAuthorizationError.Declined where declined.errorCode == declinedCode:
            alertMessage = localizedString(from: "declined_301_message")
            
        case let tdsFailure as PaymentAuthorizationError.TdsFailure where tdsFailure.errorCode == tdsFailureCode:
            var endString = "."
            if let info = tdsFailure.transactionDetails.cardholderResponseInfo {
                endString = " - \(info)."
            }
            alertMessage = String.localizedStringWithFormat(
                "%@%@",
                localizedString(from: "blocked_540_message"),
                endString
            )
            
        default:
            var baseErrorMessage = "\(localizedString(from: "details")))"
            if case let baseError as BaseTransactionError = error {
                baseErrorMessage += ": \(String(describing: error))"
                baseErrorMessage += "\ncode = \(baseError.transactionDetails.responseCode ?? "")"
                baseErrorMessage += "\nmessage = \(baseError.transactionDetails.responseMessage ?? "")"
            } else {
                let description = error.localizedDescription
                baseErrorMessage += ": \(description)"
            }
            alertMessage = baseErrorMessage
        }
    }
    
    private func displaySuccess() {
        shouldShowStatusAlert = true
        alertMessage = localizedString(from: "payment_authorized")
        alertTitle = localizedString(from: "success")
    }
    
    private func localizedString(from key: String) -> String {
        let comment = key.replacingOccurrences(of: "_", with: " ").capitalized
        // Rationale: NSLocalized Strings are needed here
        // swiftlint:disable:next nslocalizedstring_key
        return NSLocalizedString(key, comment: comment)
    }
}

@available(iOS 13.0, *)
struct AvailablePaymentsView_Previews: PreviewProvider {
    static var previews: some View {
        AvailablePaymentsView()
    }
}

extension PaymentMethod {
    var isAdditionalDataInputRequired: Bool {
        return nameKey == "card"
    }
}

extension Currency {
    /// Currency string formatted using  currncy digits and iso code
    func formatted(from amount: Int) -> String {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = currencyCode
        let number = NSDecimalNumber(
            mantissa: UInt64(amount),
            exponent: -Int16(currencyDigits),
            isNegative: false
        )
        guard let priceString = currencyFormatter.string(from: number) else {
            return "Error"
        }
        return priceString
    }
}
let versionAndBuild: String = {
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    
    var versionString = "Version: "
    if let app = appVersion {
        versionString += app
    }
    if let build = buildVersion {
        versionString += ", build: \(build)"
    }
    return versionString
}()
