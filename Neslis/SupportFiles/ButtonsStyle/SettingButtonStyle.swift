//
//  SettingButtonStyle.swift
//  NesLis
//
//  Created by Sergey Volkov on 18.07.2020.
//  Copyright © 2020 Sergei Volkov. All rights reserved.
//

import Foundation
import SwiftUI


struct SettingButtonStyle: ButtonStyle {
    
    var disable: Bool
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            //.contentShape(Rectangle())
            .foregroundColor(disable ? Color.white.opacity(0.5) : configuration.isPressed ? Color.white.opacity(0.5) : Color.white)
            .background(disable ? Color.gray.opacity(0.5) : configuration.isPressed ? Color.blue.opacity(0.5) : Color.blue)
    }
}

struct SettingButtonDeleteStyle: ButtonStyle {
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .foregroundColor(configuration.isPressed ? Color.white.opacity(0.5) : Color.white)
            .background(configuration.isPressed ? Color.red.opacity(0.5) : Color.red)
            .background(Color.red)
    }
}

struct PurchaseButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: 300, maxHeight: 50, alignment: .center)
            .foregroundColor(configuration.isPressed ? Color.white.opacity(0.5) : Color.white)
            .background(configuration.isPressed ? Color.red.opacity(0.5) : Color.green)
            .background(Color.green)
    }
}

struct FeedbackButtonStyle: ButtonStyle {
    
    var disable: Bool
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .foregroundColor(disable ? Color(UIColor.label).opacity(0.5) : configuration.isPressed ? Color(UIColor.label).opacity(0.5) : Color(UIColor.label))
            .disabled(disable)
            .multilineTextAlignment(.leading)
    }
}
