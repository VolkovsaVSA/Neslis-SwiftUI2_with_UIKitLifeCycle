//
//  SwiftUIView.swift
//  Neslis
//
//  Created by Sergey Volkov on 11.10.2020.
//

import SwiftUI

struct NewListView: View {
    
    var size : CGFloat
    var flexibleLayout = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject var colorVM: ColorSetViewModel
    @StateObject var iconVM: IconSetViewModel
    
    @State var newListTitle = ""
    @State var isAutoNumbering = true
    @State var isShowCheckedItem = true
    @State var isShowSublistCount = true
    
    var lvm: ListCD?
    
    var body: some View {
        
        NavigationView() {
            VStack {
                Toggle(TxtLocal.Toggle.autoNumbering, isOn: $isAutoNumbering)
                Toggle(TxtLocal.Toggle.showCheckedItem, isOn: $isShowCheckedItem)
                Toggle(TxtLocal.Toggle.showSublistCount, isOn: $isShowSublistCount)
                
                IconImageView(image: iconVM.iconSelected, color: Color(colorVM.colorSelected), imageScale: size/1.5)
                    .padding(6)
                
                TextField(TxtLocal.TextField.newListTitle, text: $newListTitle)
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
            .padding([.horizontal, .top], size/1.5)
            .navigationTitle(TxtLocal.Navigation.Title.listSettings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(TxtLocal.Button.save) {
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
            CDStack.shared.createList(title: newListTitle, systemImage: iconVM.iconSelected, systemImageColor: colorVM.colorSelected.encode()!, isAutoNumbering: isAutoNumbering, isShowCheckedItem: isShowCheckedItem, isShowSublistCount: isShowSublistCount, share: false, context: viewContext)
        }
        CDStack.shared.saveContext(context: viewContext)
        self.presentationMode.wrappedValue.dismiss()
    }
}

