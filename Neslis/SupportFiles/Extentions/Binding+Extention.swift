//
//  Binding+Extention.swift
//  Neslis
//
//  Created by Sergey Volkov on 28.11.2020.
//

import SwiftUI

extension Binding {
    func didSet(execute: @escaping (Value) -> Void) -> Binding {
        return Binding(
            get: {
                return self.wrappedValue
            },
            set: {
                self.wrappedValue = $0
                execute($0)
            }
        )
    }
}
