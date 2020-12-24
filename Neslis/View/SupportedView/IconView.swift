//
//  IconView.swift
//  Buman
//
//  Created by Sergey Volkov on 16.06.2020.
//  Copyright © 2020 Sergei Volkov. All rights reserved.
//

import SwiftUI

struct IconView: View {
    
    @StateObject var iconSetVM: IconSetViewModel
    @Binding var localIcon: IconModel
    var size: CGFloat
    
    var body: some View {
        
        Button(action: {
            self.iconSetVM.iconSelected = self.localIcon.icon
        }) {
            IconImageView(image: localIcon.icon, color: Color(.systemGray2), imageScale: self.size/2)
            .frame(width: self.size, height: self.size)
        }
        
    }
}
