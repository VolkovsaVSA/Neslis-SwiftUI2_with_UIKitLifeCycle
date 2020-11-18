//
//  ColorView.swift
//  Buman
//
//  Created by Sergey Volkov on 16.06.2020.
//  Copyright © 2020 Sergei Volkov. All rights reserved.
//

import SwiftUI

struct ColorView: View {
    
    @ObservedObject var colorSetVM: ColorSetViewModel
    @Binding var localColor: ColorModel
    var size: CGFloat
    
    var body: some View {
        
        Button(action: {
            self.colorSetVM.colorSelected = self.localColor.color
            print(self.colorSetVM.colorSelected.description)
        }) {
//            Circle()
//            .frame(width: self.size, height: self.size)
//            .foregroundColor(Color(localColor.color))
            LinearGradient(gradient: Gradient(colors: [Color(localColor.color).opacity(0.5), Color(localColor.color)]), startPoint: .top, endPoint: .bottom)
                .frame(width: self.size, height: self.size)
                .clipShape(Circle())
        }
        
    }
}

struct ColorView_Previews: PreviewProvider {
    static var previews: some View {
        ColorView(colorSetVM: ColorSetViewModel(), localColor: .constant(ColorSetViewModel().colorSet.first!), size: UIScreen.main.bounds.width/10)
    }
}
