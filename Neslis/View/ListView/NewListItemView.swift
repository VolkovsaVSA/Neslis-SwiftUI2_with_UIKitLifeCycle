//
//  NewListItem.swift
//  Neslis
//
//  Created by Sergey Volkov on 29.10.2020.
//

import SwiftUI

struct NewListItemView: View {
    
    var userSettings: UserSettings
    var cd: CDStack
    @ObservedObject var list: ListCD

    var firstLevel: Bool = true
    var parentList: ListCD?
    var parentListItem: ListItemCD?
    
    @State var newTitle = ""
    @Binding var addNewsublist: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "plus.circle.fill")
                .font(Font.system(size: 20))
                .foregroundColor(userSettings.useListColor ? Color(UIColor.color(data: list.systemImageColor) ?? UIColor.red) : .red)
            TextField("Enter new task", text: $newTitle, onEditingChanged: { tfChange in
                addNewsublist = tfChange
            })
            {
                cd.createListItem(title: newTitle, parentList: parentList, parentListItem: parentListItem, share: firstLevel ? parentList!.share : parentListItem!.share)
                newTitle = ""

                if parentList != nil {
                    parentList!.setIndex()
                    parentList!.childrenUpdate = true
                } else if parentListItem != nil {
                    parentListItem!.setIndex()
                    parentListItem!.childrenUpdate = true
                }

                addNewsublist = false
                cd.saveContext()
            }
            
        }
    }
}
