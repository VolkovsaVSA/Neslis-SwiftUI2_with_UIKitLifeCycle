//
//  SwiftUIView.swift
//  Neslis
//
//  Created by Sergey Volkov on 11.10.2020.
//

import SwiftUI

struct NewListView: View {
    
    private let size = UIScreen.main.bounds.width/10
    var flexibleLayout = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var colorVM: ColorSetViewModel
    @ObservedObject var iconVM: IconSetViewModel
    
    @State var newListTitle = ""
    @State var isAutoNumbering = true
    @State var isShowCheckedItem = true
    @State var isShowSublistCount = true
    
    var lvm: ListCD?
    var cd: CDStack
    
    var body: some View {
        
        NavigationView() {
            VStack {
                Toggle("Auto numbering", isOn: $isAutoNumbering)
                Toggle("Show checked item", isOn: $isShowCheckedItem)
                Toggle("Show sublist count", isOn: $isShowSublistCount)
                
                IconImageView(image: iconVM.iconSelected, color: Color(colorVM.colorSelected), imageScale: size/1.2)
                    .padding(8)
                
                TextField("New list title", text: $newListTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, size/4)
                    .padding(.bottom, size/4)
                    .font(Font.system(size: 26, weight: .regular, design: .default))
                
                ScrollView {
                    LazyVGrid(columns: flexibleLayout, spacing: size/2) {
                        ForEach(colorVM.colorSet, id: \.self) { color in
                            ColorView(colorSetVM: colorVM, localColor: .constant(color), size: size)
                        }
                    }
                    Spacer(minLength: size)
                    LazyVGrid(columns: flexibleLayout, spacing: size/2) {
                        ForEach(iconVM.iconSet, id: \.self) { icon in
                            IconView(iconSetVM: iconVM, localIcon: .constant(icon), size: size)
                        }
                    }
                    
                }
                
            }
            .padding(size/1)
            .navigationTitle("List settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAction()
                    }
                }
            }
        }
    }
    
    private func saveAction() {
        if let localLvm = self.lvm {
            localLvm.title = self.newListTitle
            localLvm.systemImage = iconVM.iconSelected
            localLvm.systemImageColor = colorVM.colorSelected.encode()!
            localLvm.isAutoNumbering = isAutoNumbering
            localLvm.isShowCheckedItem = isShowCheckedItem
            localLvm.isShowSublistCount = isShowSublistCount
        } else {
            cd.createList(title: newListTitle, systemImage: iconVM.iconSelected, systemImageColor: colorVM.colorSelected.encode()!, isAutoNumbering: isAutoNumbering, isShowCheckedItem: isShowCheckedItem, isShowSublistCount: isShowSublistCount, share: false)
        }
        cd.saveContext()
        self.presentationMode.wrappedValue.dismiss()
    }
}

