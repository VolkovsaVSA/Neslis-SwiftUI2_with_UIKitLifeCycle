//
//  ListItemView.swift
//  Neslis
//
//  Created by Sergey Volkov on 23.10.2020.
//

import SwiftUI

struct ListItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var userSettings: UserSettings
    var isExpand = true
    
    @ObservedObject var list: ListCD
    @ObservedObject var item: ListItemCD
    
    @State var addNewSublist = false
    var parentIndex: String?
    
    var body: some View {
        Section {
            HStack {
                Image(systemName: CDStack.shared.isCompleteCheck(isComplete: item.isComplete))
                    .onTapGesture {
                        CDStack.shared.isCompleteItem(listItem: item, context: viewContext)
                        CDStack.shared.saveContext(context: viewContext)
                    }
                    .foregroundColor(userSettings.useListColor ? Color(UIColor.color(data: list.systemImageColor) ?? .label) : Color(UIColor.label))
                    .font(Font.system(size: 20))
                if list.isAutoNumbering {
                    Text(parentIndex == nil ? item.index.description : parentIndex! + "." + item.index.description)
                        .fontWeight(.thin)
                }
                TextField("New task", text: $item.title, onEditingChanged: { isChange in
                    //isChange
                    item.isEditing = isChange
                    CDStack.shared.saveContext(context: viewContext)
                }) {
                    CDStack.shared.saveContext(context: viewContext)
                    //onCommit
                }
                
                .font(Font.system(size: 17, weight: item.childrenArray?.isEmpty ?? true ? .regular : .bold, design: .default))
                
                if item.isEditing {
                    Image(systemName: addNewSublist ? "minus.circle" : "plus.circle")
                        .foregroundColor(userSettings.useListColor ? Color(UIColor.color(data: list.systemImageColor) ?? .blue) : .blue)
                        .onTapGesture {
                            addNewSublist.toggle()
                    }
                    .font(Font.system(size: 20))
                }
                
                if item.childrenArray?.count ?? 0 > 0 {
                    Image(systemName:"chevron.right.circle")
                        .onTapGesture {
                            item.isExpand.toggle()
                    }
                        .font(Font.system(size: 20))
                        .foregroundColor(userSettings.useListColor ? Color(UIColor.color(data: list.systemImageColor) ?? UIColor.blue) : .blue)
                        .rotationEffect(.degrees(item.isExpand ? 90 : 0))
                        .animation(.spring())
                }
                
                if let array = item.childrenArray {
                    if !array.isEmpty && list.isShowSublistCount {
                        Text(" \(CDStack.shared.nonCompleteCount(list: array)) / \(array.count) ")
                            .font(Font.system(size: 14, weight: .thin, design: .default))
                    }
                }
                

            }

            if let array = item.childrenArray {
                if !array.isEmpty {
                    if item.isExpand {
                        Section {
                            ForEach(CDStack.shared.prepareArrayListItem(array: array, list: list), id:\.self) { localItem in
                                ListItemView(userSettings: userSettings, isExpand: true, list: list, item: localItem, parentIndex: parentIndex == nil ? item.index.description : parentIndex! + "." + item.index.description)
                                    .onReceive(localItem.objectWillChange) { _ in
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            self.item.objectWillChange.send()
                                        }
                                    }
                                    
                            }
                            .onDelete(perform: onDelete)
                            .onMove(perform: onMove)
                        }
                        .padding(.leading)
                    }
                }
            }
            
            if addNewSublist {
                NewListItemView(userSettings: userSettings, list: list, firstLevel: false, parentList: nil, parentListItem: item, newTitle: "", addNewsublist: $addNewSublist)
                    .padding(.horizontal)
            }

        }
        
        
        
    }
    
    private func onDelete(offsets: IndexSet) {
        guard let array = item.childrenArray else { return }
        for index in offsets {
            viewContext.delete(array[index])
        }
        item.childrenUpdate = true
    }
    private func onMove(source: IndexSet, destination: Int) {
        guard var array = item.childrenArray else {return}
        array.move(fromOffsets: source, toOffset: destination)
        item.children = NSOrderedSet(array: array)
        item.childrenUpdate = true
    }
}

