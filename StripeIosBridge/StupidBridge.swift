//
//  StupidBridge.swift
//  StripeIosBridge
//
//  Created by Oliver Gaus on 2025-02-13.
//

import Foundation
import StripePaymentSheet
import UIKit

@objc public class StripeMerchantConfiguration: NSObject {
    @objc public var merchantDisplayName: String
    @objc public var allowsDelayedPaymentMethods: Bool
    
    @objc public init(merchantDisplayName: String, allowsDelayedPaymentMethods: Bool) {
        self.merchantDisplayName = merchantDisplayName
        self.allowsDelayedPaymentMethods = allowsDelayedPaymentMethods
    }
}

@objc public class StripeCustomerConfiguration: NSObject {
    @objc public var customerId: String
    @objc public var secret: String
    
    @objc public init(customerId: String, secret: String) {
        self.customerId = customerId
        self.secret = secret
    }
}

@objc public class StupidBridge: NSObject {
    
    @objc public func setPublishableKey(publishableKey: String) {
        STPAPIClient.shared.publishableKey = publishableKey
    }
    
    @objc public func presentPaymentSheet(
        merchantConfig: StripeMerchantConfiguration,
        customerConfig: StripeCustomerConfiguration?,
        paymentIntentClientSecret: String,
        viewController: UIViewController,
        completed: @escaping () -> Void,
        canceled: @escaping () -> Void,
        failed: @escaping (Error) -> Void
    ) {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = merchantConfig.merchantDisplayName
        configuration.allowsDelayedPaymentMethods = merchantConfig.allowsDelayedPaymentMethods
        
        if (customerConfig != nil) {
            configuration.customer = .init(id: customerConfig!.customerId, ephemeralKeySecret: customerConfig!.secret)
        }
        
        let paymentSheet = PaymentSheet(paymentIntentClientSecret: paymentIntentClientSecret, configuration: configuration)
        
        paymentSheet.present(from: viewController) { paymentResult in
            switch paymentResult {
            case .completed:
                completed()
            case .canceled:
                canceled()
            case .failed(let error):
              failed(error)
            }
        }
    }

}
