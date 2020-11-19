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
    
    static let shared = IAPManager()
    var products: [SKProduct] = []
    
    enum Products: String {
        case MonthSubs  = "NeslisMonthSubs"
        case YearSubs = "NeslisYearSubs"
        case Test = "NeslisTest"
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
        //print(#function, product.localizedDescription)
        let payment = SKPayment(product: product)
        
        SKPaymentQueue.default().add(payment)
    }
    public func restoreCompletedTransaction() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func validateReceipt(){
        print(#function)
        #if DEBUG
        let urlString = "https://sandbox.itunes.apple.com/verifyReceipt"
        #else
        let urlString = "https://buy.itunes.apple.com/verifyReceipt"
        #endif
        
        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            print("guard receiptURL")
            return }
        print(receiptURL)
        guard let receiptString = try? Data(contentsOf: receiptURL).base64EncodedString() else {
            print("guard receiptString")
            return }
        guard let url = URL(string: urlString) else {
            print("guard url")
            return
        }
        
        let requestData : [String : Any] = ["receipt-data" : receiptString,
                                            "password" : "d5df76523fd84d4693d01f50eb6e213f",
                                            "exclude-old-transactions" : false]
        let httpBody = try? JSONSerialization.data(withJSONObject: requestData, options: [])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        URLSession.shared.dataTask(with: request)  { (data, response, error) in
            
            print("data: \(String(describing: data))")
            print("response: \(String(describing: response))")
            print("error: \(String(describing: error))")
            
            print("dataJSON: \(String(describing: data?.description))")
        }.resume()
    }
    
    func valRec() {
        //print(#function)
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
           FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
            
            do {
                let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                print(receiptData)
                let receiptString = receiptData.base64EncodedString(options: [])
                print(receiptString)
            } catch {
                print("Couldn't read receipt data with error: " + error.localizedDescription)
            }
        } else {
            print("error valRec")
        }
    }
    
}


extension IAPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print(#function)
        for transaction in transactions {
            switch transaction.transactionState {
            case .deferred: break
            case .purchasing: break
            case .failed: failed(transaction: transaction)
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
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: ProductsState.errored.rawValue), object: nil, userInfo: ["error": transactionError])
            }
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    private func completed(transaction: SKPaymentTransaction) {
        print(#function)
        NotificationCenter.default.post(name: NSNotification.Name(ProductsState.completed.rawValue), object: nil)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    private func restored(transaction: SKPaymentTransaction) {
        print(#function)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: ProductsState.restored.rawValue), object: nil)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
}

extension IAPManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.products = response.products
        //print(#function, #line, self.products.description)
    }
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        //print("\(#function) \(error.localizedDescription)")
    }
    public func requestDidFinish(_ request: SKRequest) {
        //print("\(#function)")
    }
}
