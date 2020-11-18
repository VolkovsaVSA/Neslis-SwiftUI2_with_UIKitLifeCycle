//
//  ListItemView.swift
//  Neslis
//
//  Created by Sergey Volkov on 23.10.2020.
//

import SwiftUI

struct ListItemView: View {
    var cd: CDStack
    var isExpand = true
    
    @ObservedObject var list: ListCD
    @ObservedObject var item: ListItemCD
    
    @State var addNewSublist = false
    var parentIndex: String?
    
    var body: some View {
        Section {
            HStack {
                Image(systemName: cd.isCompleteCheck(isComplete: item.isComplete))
                    .onTapGesture {
                        cd.isCompleteItem(listItem: self.item)
                    }
                    .foregroundColor(Color(UIColor.color(data: list.systemImageColor) ?? .label))
                    .font(Font.system(size: 20))
                if list.isAutoNumbering {
                    Text(parentIndex == nil ? item.index.description : parentIndex! + "." + item.index.description)
                        .fontWeight(.thin)
                }
                TextField("New task", text: $item.title, onEditingChanged: { isChange in
                    //isChange
                    item.isEditing = isChange
                    cd.saveContext()
                }) {
                    cd.saveContext()
                    //onCommit
                }
                .font(Font.system(size: 17, weight: item.childrenArray?.isEmpty ?? true ? .regular : .bold, design: .default))
                
                if item.isEditing {
                    Image(systemName: self.addNewSublist ? "minus.circle" : "plus.circle")
                        .foregroundColor(Color(UIColor.color(data: list.systemImageColor) ?? .blue))
                        .onTapGesture {
                            self.addNewSublist.toggle()
                    }
                    .font(Font.system(size: 20))
                }
                
                if item.childrenArray?.count ?? 0 > 0 {
                    Image(systemName:"chevron.right.circle")
                        .onTapGesture {
                            self.item.isExpand.toggle()
                    }
                        .font(Font.system(size: 20))
                        .foregroundColor(Color(UIColor.color(data: list.systemImageColor) ?? UIColor.blue))
                        .rotationEffect(.degrees(self.item.isExpand ? 90 : 0))
                        .animation(.spring())
                }
                
                if let array = item.childrenArray {
                    if !array.isEmpty && list.isShowSublistCount {
                        Text(" \(cd.nonCompleteCount(list: array)) / \(array.count) ")
                            .font(Font.system(size: 14, weight: .thin, design: .default))
                    }
                }
                

            }

            if let array = item.childrenArray {
                if !array.isEmpty {
                    if self.item.isExpand {
                        Section {
                            ForEach(cd.prepareArrayListItem(array: array, list: list), id:\.self) { localItem in
                                ListItemView(cd: cd, isExpand: true, list: list, item: localItem, parentIndex: parentIndex == nil ? item.index.description : parentIndex! + "." + item.index.description)
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
            
            if self.addNewSublist {
                NewListItemView(cd: cd, list: list, firstLevel: false, parentList: nil, parentListItem: item, newTitle: "", addNewsublist: $addNewSublist)
                    .padding(.horizontal)
            }

        }
        
        
        
    }
    
    private func onDelete(offsets: IndexSet) {
        guard let array = self.item.childrenArray else { return }
        for index in offsets {
            cd.deleteObject(object: array[index])
        }
        item.childrenUpdate = true
        cd.saveContext()
    }
    private func onMove(source: IndexSet, destination: Int) {
        guard var array = item.childrenArray else {return}
        array.move(fromOffsets: source, toOffset: destination)
        item.children = NSOrderedSet(array: array)
        item.childrenUpdate = true
        cd.saveContext()
    }
}

