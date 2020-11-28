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
            if allItesCount != 0 {
                DispatchQueue.main.async {
                    self.value = Double(self.counter) / Double(self.allItesCount) * 100
                }
            }
            print("ProgressData.value: \(value)")
        }
    }
    var allItesCount = 0
    func setZero() {
        DispatchQueue.main.async {
            self.allItesCount = 0
            self.value = 0
            self.counter = 0
        }
    }
    
}
