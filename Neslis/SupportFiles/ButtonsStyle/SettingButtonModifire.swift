//
//  SettingButtonModifire.swift
//  NesLis
//
//  Created by Sergey Volkov on 18.07.2020.
//  Copyright © 2020 Sergei Volkov. All rights reserved.
//

import Foundation
import SwiftUI

struct SettingButtonModifire: ViewModifier {
   
    var disable: Bool
    
    func body(content: Content) -> some View {
        content
            .buttonStyle(SettingButtonStyle(disable: disable))
            .cornerRadius(6)
    }
}
struct SettingDeleteButtonModifire: ViewModifier {
   
    func body(content: Content) -> some View {
        content
            .buttonStyle(SettingButtonDeleteStyle())
            .cornerRadius(6)
    }
}
struct PurchaseButtonModifire: ViewModifier {
   
    func body(content: Content) -> some View {
        content
            .buttonStyle(PurchaseButtonStyle())
            .cornerRadius(12)
    }
}








