//
//  IAPManager.swift
//  Neslis
//
//  Created by Sergey Volkov on 22.08.2020.
//  Copyright © 2020 Sergei Volkov. All rights reserved.
//

import Foundation
import StoreKit

class IAPManager: NSObject {
    private override init() {}
    
    enum ReceiptValidationError: Error {
        case receiptNotFound
        case jsonResponseIsNotValid(description: String)
        case notBought
        case expired
    }
    
    static let shared = IAPManager()
    var products: [SKProduct] = []
    
    enum Products: String {
        case MonthSubs  = "NeslisMonthSubs"
        case YearSubs = "NeslisYearSubs"
    }
    
    enum ProductsState: String {
        case restored = "RestoredParchase"
        case errored = "ErroredPurchase"
        case completed = "CompletedPurchase"
    }
    
    public func setupPurchases(completion: @escaping(Bool)->()) {
        if SKPaymentQueue.canMakePayments() {
            SKPaymentQueue.default().add(self)
            completion(true)
            return
        }
        completion(false)
    }
    public func getProducts() {
        print(#function)
        let identifires: Set = [
            IAPManager.Products.MonthSubs.rawValue,
            IAPManager.Products.YearSubs.rawValue
        ]
        let productRequest = SKProductsRequest(productIdentifiers: identifires)
        productRequest.delegate = self
        productRequest.start()
    }
    public func priceOfProduct(product: SKProduct) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = product.priceLocale
        return numberFormatter.string(from: product.price) ?? ""
    }
    public func purshase(product: SKProduct) {
        let payment = SKPayment(product: product)
        
        SKPaymentQueue.default().add(payment)
    }
    public func restoreCompletedTransaction() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    
    func validateReceipt() /*throws*/ {
        
        func expirationDate(jsonResponse: [AnyHashable: Any], forProductId productId :String) -> Date? {
            guard let receiptInfo = (jsonResponse["latest_receipt_info"] as? [[AnyHashable: Any]]) else {
                return nil
            }
            let filteredReceipts = receiptInfo.filter { ($0["product_id"] as? String) == productId }
            guard let lastReceipt = filteredReceipts.first else {
                return nil
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss VV"
            if let expiresString = lastReceipt["expires_date"] as? String {
                return formatter.date(from: expiresString)
            }
            return nil
        }
        
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL, FileManager.default.fileExists(atPath: appStoreReceiptURL.path) else {
//            throw ReceiptValidationError.receiptNotFound
            print("guard appStoreReceiptURL")
            return
        }

        let receiptData = try! Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
        let receiptString = receiptData.base64EncodedString()
        let jsonObjectBody: [String : Any] = ["receipt-data" : receiptString,
                                              "password" : "d5df76523fd84d4693d01f50eb6e213f",
                                              "exclude-old-transactions" : true]

        #if DEBUG
        let url = URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")!
        #else
        let url = URL(string: "https://buy.itunes.apple.com/verifyReceipt")!
        #endif

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try! JSONSerialization.data(withJSONObject: jsonObjectBody, options: .prettyPrinted)

        let semaphore = DispatchSemaphore(value: 0)

        var validationError : ReceiptValidationError?

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil, httpResponse.statusCode == 200 else {
                validationError = ReceiptValidationError.jsonResponseIsNotValid(description: error?.localizedDescription ?? "")
                semaphore.signal()
                return
            }
            guard let jsonResponse = (try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [AnyHashable: Any] else {
                validationError = ReceiptValidationError.jsonResponseIsNotValid(description: "Unable to parse json")
                semaphore.signal()
                return
            }
//            guard let expirationDateNeslisMonthSubs = expirationDate(jsonResponse: jsonResponse, forProductId: "NeslisMonthSubs") else {
//                validationError = ReceiptValidationError.notBought
//                semaphore.signal()
//                return
//            }
            //print("jsonResponse: \(jsonResponse)")
            let expirationDateNeslisMonthSubs = expirationDate(jsonResponse: jsonResponse, forProductId: "NeslisMonthSubs")
            let expirationDateNeslisYearSubs = expirationDate(jsonResponse: jsonResponse, forProductId: "NeslisYearSubs")
            var expirationDate: Date?
            
            if let monthDate = expirationDateNeslisMonthSubs {
                if let yearDate = expirationDateNeslisYearSubs {
                    if monthDate > yearDate {
                        expirationDate = monthDate
                    } else {
                        expirationDate = yearDate
                    }
                }
            } else {
                if let yearDate = expirationDateNeslisYearSubs {
                    expirationDate = yearDate
                }
            }
            
            DispatchQueue.main.async {
                if expirationDate != nil {
                    if Date() > expirationDate! {
                        UserSettings.shared.proVersion = false
                    } else {
                        UserSettings.shared.proVersion = true
                    }
                }
                else {
                    UserSettings.shared.proVersion = false
                }
                
            }
            
            print("expirationDate: \(String(describing: expirationDate))")
            semaphore.signal()
        }
        task.resume()

        semaphore.wait()
        DispatchQueue.main.async {
            ProgressData.shared.activitySpinnerAnimate = false
        }
        
        
        if let validationError = validationError {
            print("validationError: \(validationError.localizedDescription)")
        }
    }
    
}


extension IAPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print(#function)
        for transaction in transactions {
            switch transaction.transactionState {
            case .deferred:
                print("deferred")
                break
            case .purchasing:
                print("purchasing")
                break
            case .failed:
                print("failed")
            case .purchased: completed(transaction: transaction)
            case .restored: restored(transaction: transaction)
            @unknown default:
                print("unknown")
                break
            }
        }
    }
    private func failed(transaction: SKPaymentTransaction) {
        //print(#function)
        if let transactionError = transaction.error as NSError? {
            if transactionError.code != SKError.paymentCancelled.rawValue {
                print("transaction error \(transactionError.localizedDescription)")
            }
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    private func completed(transaction: SKPaymentTransaction) {
        print(#function)
        SKPaymentQueue.default().finishTransaction(transaction)
        UserSettings.shared.proVersion = true
    }
    private func restored(transaction: SKPaymentTransaction) {
        print(#function)
        SKPaymentQueue.default().finishTransaction(transaction)
        validateReceipt()
    }
}

extension IAPManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.products = response.products
        print(#function, #line, self.products.description)
    }
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        //print("\(#function) \(error.localizedDescription)")
    }
    public func requestDidFinish(_ request: SKRequest) {
        //print("\(#function)")
    }
}

