//
//  ContentView.swift
//  Neslis
//
//  Created by Sergey Volkov on 10.10.2020.
//

import SwiftUI
import CoreData

struct ListOfListsView: View {
    
    enum ActiveSheet: Identifiable {
        case newList, userSetting
        var id: Int {
            hashValue
        }
    }
    @State private var activeSheet: ActiveSheet?
    
    @ObservedObject var userSettings: UserSettings
    @ObservedObject var progressData: ProgressData
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: ListCD.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ListCD.dateAdded, ascending: true)]
    )
    var lists: FetchedResults<ListCD>
    
    @StateObject var colorVM = ColorSetViewModel()
    @StateObject var iconVM = IconSetViewModel()
 
    var body: some View {
        LoadingView(isShowing: $progressData.activitySpinnerAnimate, text: progressData.activitySpinnerText, messageText: $progressData.finishMessage, result: $progressData.finishButtonShow, progressBar: $progressData.value, content: {
            NavigationView {
                List {
                    ForEach(lists) { list in
                        NavigationLink(destination: ListView(userSettings: userSettings, colorVM: colorVM, iconVM: iconVM, list: list)) {
                            HStack {
                                IconImageView(image: list.systemImage, color: Color(UIColor.color(data: list.systemImageColor) ??
                                                                                        .red) , imageScale: 16)
                                Text("\(list.title)")
                                Spacer()
                                if list.isShare {
                                    Image(systemName: "person.2.circle.fill")
                                }
                                Text("\(list.childrenArray?.count ?? 0)")
                            }
                            
                        }
                        
                    }
                    .onDelete(perform: deleteList)
                    
                    Button(action: {
                        activeSheet = .newList
                        iconVM.iconSelected = "list.bullet"
                        colorVM.colorSelected = .red
                    }) {
                        HStack(alignment: .center) {
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .font(Font.system(size: 20))
                                .foregroundColor(Color(.systemRed))
                            Text("Add new list")
                                .foregroundColor(Color(.systemRed))
                            Spacer()
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .edgesIgnoringSafeArea(.bottom)
                .navigationTitle("Lists")
                .navigationBarItems(
                    leading: Button(action: {
                        activeSheet = .userSetting
                    }, label: {
                        Image(systemName: "line.horizontal.3")
                            .resizable()
                            .frame(width: 24, height: 14)
                    })
                )
                .sheet(item: $activeSheet) { item in
                    switch item {
                    case .newList:
                        NewListView(size: UIScreen.main.bounds.width/10, colorVM: colorVM, iconVM: iconVM)
                            .environment(\.managedObjectContext, viewContext)
                            .edgesIgnoringSafeArea(.all)
                    case .userSetting:
                        SettingsView(userSettings: userSettings)
                            .environment(\.managedObjectContext, viewContext)
                    }
                }
            }
        })
        
        
    }
    
    private func deleteList(offsets: IndexSet) {
        offsets.map { lists[$0] }.forEach(viewContext.delete)
        CDStack.shared.saveContext(context: viewContext)
    }
    
    
    
}

