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

class AnotherStupidWrapper : NSObject, STPAuthenticationContext {
    public func authenticationPresentingViewController() -> UIViewController {
        return viewController
    }
    
    public var viewController: UIViewController
    
    public init(viewController: UIViewController) {
        self.viewController = viewController
    }
}

@objc public class BankAccountSetup : NSObject {
    @objc public func show(
        viewController: UIViewController,
        name: String,
        email: String,
        clientSecret: String,
        returnUrl: String,
        completed: @escaping (String) -> Void,
        canceled: @escaping () -> Void,
        failed: @escaping (Error) -> Void
    ) {
        let stupidity = AnotherStupidWrapper(viewController: viewController)
        
        // Build params
        let collectParams = STPCollectBankAccountParams.collectUSBankAccountParams(with: name, email: email)

        // Calling this method will display a modal for collecting bank account information
        let bankAccountCollector = STPBankAccountCollector()
        bankAccountCollector.collectBankAccountForSetup(clientSecret: clientSecret,
                                                        returnURL: returnUrl,
                                                        params: collectParams,
                                                        from: viewController) { intent, error in
            guard let intent = intent else {
                failed(error!)
                return
            }
            if case .requiresPaymentMethod = intent.status {
                canceled()
            } else if case .requiresConfirmation = intent.status {
                // We collected an account - possibly instantly verified, but possibly
                // manually-entered.

                let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: clientSecret, paymentMethodType: .USBankAccount)

                // Confirm the SetupIntent
                STPPaymentHandler.shared().confirmSetupIntent(
                    setupIntentParams, with: stupidity
                ) { (status, intent, error) in
                    switch status {
                    case .failed:
                        failed(error ?? NSError())
                    case .canceled:
                        canceled()
                    case .succeeded:
                        completed((intent?.paymentMethod!.stripeId)!)
                    @unknown default:
                        fatalError()
                    }
                }
            }
        }
    }
}
