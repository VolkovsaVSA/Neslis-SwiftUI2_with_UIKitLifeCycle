//
//  ProgressData.swift
//  Neslis
//
//  Created by Sergey Volkov on 22.11.2020.
//

import SwiftUI

class ProgressData: ObservableObject {
    static let shared = ProgressData()
    @Published var value = 0.0
    var counter = 0 {
        didSet {
            if allItemsCount != 0 {
                DispatchQueue.main.async {
                    let tempValue = Double(self.counter) / Double(self.allItemsCount) * 100
                    self.value = tempValue < 100 ? tempValue : 100
                }
            }
            //print("ProgressData.value: \(value)")
        }
    }
    var allItemsCount = 0
    func setZero() {
        DispatchQueue.main.async {
            self.allItemsCount = 0
            self.value = 0
            self.counter = 0
        }
    }
    @Published var activitySpinnerAnimate = false
    @Published var activitySpinnerText = ""
    @Published var showProgressBar = false
//    @Published var finishMessage = ""
//    @Published var finishButtonShow = false
    
    
}
