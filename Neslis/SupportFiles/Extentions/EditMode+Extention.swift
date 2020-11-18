//
//  EditMode+Extention.swift
//  Neslis
//
//  Created by Sergey Volkov on 07.11.2020.
//

import SwiftUI

extension EditMode {
    mutating func toggle() {
        self = self == .active ? .inactive : .active
    }
}
