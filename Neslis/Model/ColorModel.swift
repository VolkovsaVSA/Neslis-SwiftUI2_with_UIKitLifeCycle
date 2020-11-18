//
//  ListColorSetModel.swift
//  Buman
//
//  Created by Sergey Volkov on 15.06.2020.
//  Copyright © 2020 Sergei Volkov. All rights reserved.
//

import Foundation
import UIKit

struct ColorModel: Identifiable, Hashable {
    let id = UUID()
    let color: UIColor
    var isSelected: Bool
}

var ColorSet = [
    ColorModel(color: .red, isSelected: false),
    ColorModel(color: .systemPink, isSelected: false),
    ColorModel(color: .orange, isSelected: false),
    ColorModel(color: .systemYellow, isSelected: false),
    ColorModel(color: .green, isSelected: false),
    ColorModel(color: .systemGreen, isSelected: false),
    ColorModel(color: .cyan, isSelected: false),
    ColorModel(color: .systemTeal, isSelected: false),
    ColorModel(color: .systemBlue, isSelected: false),
    ColorModel(color: .blue, isSelected: false),
    ColorModel(color: .systemIndigo, isSelected: false),
    ColorModel(color: .purple, isSelected: false),
    ColorModel(color: .magenta, isSelected: false),
    ColorModel(color: .brown, isSelected: false),
    ColorModel(color: .darkGray, isSelected: false)
]

