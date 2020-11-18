//
//  LIstView.swift
//  Neslis
//
//  Created by Sergey Volkov on 22.10.2020.
//

import SwiftUI

struct ListView: View {
    var cd: CDStack
    
    @ObservedObject var colorVM: ColorSetViewModel
    @ObservedObject var iconVM: IconSetViewModel
    @ObservedObject var list: ListCD
    
    @State var selectedRows = Set<ListItemCD>()
    @State var editMode: EditMode = .inactive
    
    @State var showModal = false
    @State var sharingButton: CloudSharingButton?
    @State var addNewSublist = false
    @State var expand = false
    
    var body: some View {
        ZStack {
            List(selection: $selectedRows) {
                Section {
                    if let array = list.childrenArray {
                        ForEach(cd.prepareArrayListItem(array: array, list: list), id: \.self) { localItem in
                            ListItemView(cd: cd, isExpand: true, list: list, item: localItem)
                                .onReceive(localItem.objectWillChange) { _ in
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            self.list.objectWillChange.send()
                                        }
                                }
                        }
                        .onDelete(perform: onDelete)
                        .onMove(perform: onMove)
                    }
                    
                    NewListItemView(cd: cd, list: list, firstLevel: true, parentList: list, parentListItem: nil, addNewsublist: $addNewSublist)
                }
            }
            
            VStack {
                Spacer()
                Text(" \(cd.nonCompleteCount(list: list.childrenArray ?? [])) / \(list.childrenArray?.count ?? 0) completed ")
                    .font(.subheadline)
                    .background(cd.nonCompleteCount(list: list.childrenArray ?? []) == (list.childrenArray?.count ?? 0) ? Color.green : Color(UIColor.systemBackground), alignment: .center)
                    .cornerRadius(6)
                    
            }
        }
        
        
        .navigationTitle(list.title)
        .navigationBarItems(
            leading: sharingButton,
            trailing:
            HStack {
                
                if editMode == .active {
                    Button {
                        withAnimation {
                            deleteObjects(objects: selectedRows)
                            editMode.toggle()
                        }
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                } else {
                    Button {
                        expand.toggle()
                        expandAll(array: list.childrenArray ?? [], expand: expand)
                        cd.saveContext()
                    } label: {
                        Image(systemName:"chevron.right.circle")
                            .font(Font.system(size: 20, weight: .regular, design: .default))
                            .rotationEffect(.degrees(expand ? 90 : 0))
                            .animation(.spring())
                    }
                }
                
                Button(action: {
                    editMode.toggle()
                    selectedRows = Set<ListItemCD>()
                }) {
                    if editMode == .active {
                        Image(systemName: "checkmark.circle")
                            .font(Font.system(size: 20, weight: .regular, design: .default))
                    } else {
                        Image(systemName: "pencil.circle")
                            .font(Font.system(size: 20, weight: .regular, design: .default))
                    }
                }
                Button(action: {
                    colorVM.colorSelected = UIColor.color(data: list.systemImageColor) ?? .red
                    iconVM.iconSelected = list.systemImage
                    showModal = true
                }, label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(Font.system(size: 20, weight: .regular, design: .default))
                })
        })
        .sheet(isPresented: $showModal) {
            NewListView(colorVM: colorVM, iconVM: iconVM, newListTitle: list.title, isAutoNumbering: list.isAutoNumbering, isShowCheckedItem: list.isShowCheckedItem, isShowSublistCount: list.isShowSublistCount, lvm: list, cd: cd)
                //.edgesIgnoringSafeArea(.all)
        }
        .environment(\.editMode, $editMode)
        
    }
    
    private func onDelete(offsets: IndexSet) {
        guard let array = self.list.childrenArray else { return }
        for index in offsets {
            cd.deleteObject(object: array[index])
        }
        list.childrenUpdate = true
        cd.saveContext()
    }
    private func deleteObjects(objects: Set<ListItemCD>) {
        objects.forEach { item in
            cd.deleteObject(object: item)
            if let lst = item.parentList {
                lst.childrenUpdate = true
            }
            if let itm = item.parentListItem {
                itm.childrenUpdate = true
            }
        }
        cd.saveContext()
        selectedRows = Set<ListItemCD>()
    }
    private func onMove(source: IndexSet, destination: Int) {
        guard var array = list.childrenArray else {return}
        array.move(fromOffsets: source, toOffset: destination)
        list.children = NSOrderedSet(array: array)
        list.childrenUpdate = true
        cd.saveContext()
    }
    
    private func expandAll(array: [ListItemCD], expand: Bool) {
        array.forEach { item in
            item.isExpand = expand
            if let arr = item.childrenArray {
                expandAll(array: arr, expand: expand)
            }
        }
    }
}
