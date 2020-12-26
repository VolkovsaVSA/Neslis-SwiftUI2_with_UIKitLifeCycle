//
//  ColorView.swift
//  Buman
//
//  Created by Sergey Volkov on 16.06.2020.
//  Copyright © 2020 Sergei Volkov. All rights reserved.
//

import SwiftUI

struct ColorView: View {
    
    @StateObject var colorSetVM: ColorSetViewModel
    @Binding var localColor: ColorModel
    var size: CGFloat
    
    var body: some View {
        
        Button(action: {
            self.colorSetVM.colorSelected = self.localColor.color
        }) {
            LinearGradient(gradient: Gradient(colors: [Color(localColor.color).opacity(0.5), Color(localColor.color)]), startPoint: .top, endPoint: .bottom)
                .frame(width: self.size, height: self.size)
                .clipShape(Circle())
        }
        
    }
}
