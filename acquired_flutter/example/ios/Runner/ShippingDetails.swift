import ACQPaymentGateway
import Foundation

/// ShippingDetails - contains info on shipping options related to address changes
enum ShippingDetails {
    /// ChangedShippingContactCompletion
    ///
    /// Closure executed when the shipping contact is changed in  the ApplePay flow
    static let changedShippingContactCompletion: ChangedShippingContactCompletion = { changedContact, closure in
        if changedContact.postalAddress?.isoCountryCode != "GB" {
            let paymentRequestShippingContactUpdate = PaymentRequestShippingContactUpdate(
                errors: [],
                paymentSummaryItems: Self.nonUkOrderSummaryItems,
                shippingMethods: Self.nonUkShippingOptions
            )
            closure(paymentRequestShippingContactUpdate)
        } else {
            let paymentRequestShippingContactUpdate = PaymentRequestShippingContactUpdate(
                errors: [],
                paymentSummaryItems: Self.ukOrderSummaryItems,
                shippingMethods: Self.ukShippingOptions
            )
            closure(paymentRequestShippingContactUpdate)
        }
    }
    /// Order summary items for a UK purchase
    static let ukOrderSummaryItems: [OrderLineItem] = [
        OrderSummaryItem.item1,
        OrderSummaryItem.salesTax
    ]
    /// Order summary items for a non UK purchase
    static let nonUkOrderSummaryItems: [OrderLineItem] = [
        OrderSummaryItem.item2,
        OrderSummaryItem.item3,
        OrderSummaryItem.salesTax
    ]
    /// Shipping options for UK delivery
    static let ukShippingOptions: [ShippingMethod] = [
        ShippingMethod.option1, ShippingMethod.option2
    ]
    /// Shipping options for non UK delivery
    static let nonUkShippingOptions = [
        ShippingMethod.option3, ShippingMethod.option4
    ]
}


extension ShippingMethod {
    private static var calendar: Calendar { Calendar.current }
    static var option1: ShippingMethod {
        var shippingMethod = ShippingMethod(
            label: "Shipping Method 1",
            amount: 1001,
            state: .final,
            detail: "Details of payment method 1",
            identifier: "123"
        )
        #if os(iOS)
        if #available(iOS 15, *) {
            let today = Date()
            guard let startComponent = Self.calendar.date(byAdding: .day, value: 1, to: today),
                let endComponent = Self.calendar.date(byAdding: .day, value: 2, to: today),
                let dateRange = try? DateComponentsRange(startDate: startComponent, endDate: endComponent) else {
                return shippingMethod
            }
            shippingMethod.dateComponentsRange = dateRange
        }
        #endif
        return shippingMethod
    }
    static var option2: ShippingMethod {
        var shippingMethod = ShippingMethod(
            label: "Shipping Method 2",
            amount: 2002,
            state: .final,
            detail: "Details of shipping method 2",
            identifier: "456"
        )
        #if os(iOS)
        if #available(iOS 15, *) {
            let today = Date()
            guard let startComponent = Self.calendar.date(byAdding: .day, value: 1, to: today),
                let endComponent = Self.calendar.date(byAdding: .day, value: 3, to: today),
                let dateRange = try? DateComponentsRange(startDate: startComponent, endDate: endComponent) else {
                return shippingMethod
            }
            shippingMethod.dateComponentsRange = dateRange
        }
        #endif
        return shippingMethod
    }
    static var option3: ShippingMethod {
        var shippingMethod = ShippingMethod(
            label: "Shipping Method 3",
            amount: 3003,
            state: .final,
            detail: "Details of shipping method 3",
            identifier: "789"
        )
        #if os(iOS)
        if #available(iOS 15, *) {
            let today = Date()
            guard let startComponent = Self.calendar.date(byAdding: .day, value: 2, to: today),
                let endComponent = Self.calendar.date(byAdding: .day, value: 5, to: today),
                let dateRange = try? DateComponentsRange(startDate: startComponent, endDate: endComponent) else {
                return shippingMethod
            }
            shippingMethod.dateComponentsRange = dateRange
        }
        #endif
        return shippingMethod
    }
    static var option4: ShippingMethod {
        var shippingMethod = ShippingMethod(
            label: "Shipping Method 4",
            amount: 4004,
            state: .final,
            detail: "Details of shipping method 4",
            identifier: "012"
        )
        #if os(iOS)
        if #available(iOS 15, *) {
            let today = Date()
            guard let startComponent = Self.calendar.date(byAdding: .day, value: 2, to: today),
                let endComponent = Self.calendar.date(byAdding: .day, value: 7, to: today),
                let dateRange = try? DateComponentsRange(startDate: startComponent, endDate: endComponent) else {
                return shippingMethod
            }
            shippingMethod.dateComponentsRange = dateRange
        }
        #endif
        return shippingMethod
    }
}
