//
//  ListColorSetViewModel.swift
//  Buman
//
//  Created by Sergey Volkov on 16.06.2020.
//  Copyright © 2020 Sergei Volkov. All rights reserved.
//

import Foundation
import SwiftUI


class ColorSetViewModel: ObservableObject {
    @Published var colorSet = ColorSet
    @Published var colorSelected = UIColor.red
    
}


