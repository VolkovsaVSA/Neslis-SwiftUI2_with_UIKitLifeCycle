//
//  LIstView.swift
//  Neslis
//
//  Created by Sergey Volkov on 22.10.2020.
//

import SwiftUI
import CloudKit

struct ListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var userSettings: UserSettings
    @ObservedObject var colorVM: ColorSetViewModel
    @ObservedObject var iconVM: IconSetViewModel
    @ObservedObject var list: ListCD
    
    @State var selectedRows = Set<ListItemCD>()
    @State var editMode: EditMode = .inactive
    
    @State var showModal = false
    @State var sharingButton: CloudSharingButton?
    @State var addNewSublist = false
    @State var expand = false
    
    @State var recordToShare: CKRecord?
    
    var body: some View {
        ZStack {
            List(selection: $selectedRows) {
                Section {
                    if let array = list.childrenArray {
                        ForEach(CDStack.shared.prepareArrayListItem(array: array, list: list), id: \.self) { localItem in
                            ListItemView(userSettings: userSettings, isExpand: true, list: list, item: localItem)
                                .onReceive(localItem.objectWillChange) { _ in
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            self.list.objectWillChange.send()
                                        }
                                }
                        }
                        .onDelete(perform: onDelete)
                        .onMove(perform: onMove)
                    }
                    
                    NewListItemView(userSettings: userSettings, list: list, firstLevel: true, parentList: list, parentListItem: nil, addNewsublist: $addNewSublist)
                }

            }

            if !addNewSublist && list.childrenArray?.count ?? 0 != 0 {
                VStack {
                    Spacer()
                    Text(" \(CDStack.shared.nonCompleteCount(list: list.childrenArray ?? [])) / \(list.childrenArray?.count ?? 0) completed ")
                        .font(.subheadline)
                        .background(CDStack.shared.nonCompleteCount(list: list.childrenArray ?? []) == (list.childrenArray?.count ?? 0) ? Color.green : Color(UIColor.systemBackground), alignment: .center)
                        .cornerRadius(6)
                        .padding(.bottom, 2)
                }
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
                        CDStack.shared.saveContext(context: viewContext)
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
        .onAppear() {
            if userSettings.icloudBackup {
                if !list.share {
                    CloudKitManager.fetchListRecordForSharing(id: list.id!.uuidString) { (record, error) in
                        if let localError = error {
                            print("fetchListForSharing error: \(localError.localizedDescription)")
                        }
                        if let sharingRecord = record {
                            recordToShare = sharingRecord
                            sharingButton = CloudSharingButton(toShare: list, recordToShare: sharingRecord)
                            print("fetchListForSharing success")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showModal) {
            NewListView(colorVM: colorVM, iconVM: iconVM, newListTitle: list.title, isAutoNumbering: list.isAutoNumbering, isShowCheckedItem: list.isShowCheckedItem, isShowSublistCount: list.isShowSublistCount, lvm: list)
                //.edgesIgnoringSafeArea(.all)
        }
        .environment(\.editMode, $editMode)
        
    }
    
    private func onDelete(offsets: IndexSet) {
        guard let array = list.childrenArray else { return }
        for index in offsets {
            viewContext.delete(array[index])
        }
        list.childrenUpdate = true
        list.setIndex()
        CDStack.shared.saveContext(context: viewContext)
    }
    private func deleteObjects(objects: Set<ListItemCD>) {
        objects.forEach { item in
            viewContext.delete(item)
            if let lst = item.parentList {
                lst.childrenUpdate = true
                lst.setIndex()
            }
            if let itm = item.parentListItem {
                itm.childrenUpdate = true
                itm.setIndex()
            }
        }
        CDStack.shared.saveContext(context: viewContext)
        selectedRows = Set<ListItemCD>()
    }
    private func onMove(source: IndexSet, destination: Int) {
        guard var array = list.childrenArray else {return}
        array.move(fromOffsets: source, toOffset: destination)
        list.children = NSOrderedSet(array: array)
        list.childrenUpdate = true
        list.setIndex()
        CDStack.shared.saveContext(context: viewContext)
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
