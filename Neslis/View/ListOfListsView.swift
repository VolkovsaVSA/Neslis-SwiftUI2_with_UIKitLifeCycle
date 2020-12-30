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
    @State private var refreshingID = UUID()
    
    @StateObject var colorVM = ColorSetViewModel()
    @StateObject var iconVM = IconSetViewModel()
    
    @State var size: CGFloat = 35
    
    var body: some View {
        LoadingView(isShowing: $progressData.activitySpinnerAnimate, text: progressData.activitySpinnerText, messageText: $progressData.finishMessage, result: $progressData.finishButtonShow, progressBar: $progressData.value, content: {
            NavigationView {
                List {
                    ForEach(lists) { list in
                        NavigationLink(destination: ListView(userSettings: userSettings, colorVM: colorVM, iconVM: iconVM, list: list)) {
                            VStack(spacing: 3) {
                                HStack {
                                    IconImageView(image: list.systemImage, color: Color(UIColor.color(data: list.systemImageColor) ??
                                                                                            .red) , imageScale: 16)
                                    Text("\(list.title)")
                                    Spacer()
                                    if list.isShare {
                                        Image(systemName: "person.2.circle.fill")
                                    }
                                    if userSettings.showListCounter {
                                        Text(CDStack.shared.completeCounter(list: list))
                                            .font(.system(size: 17, weight: .thin, design: .default))
                                    }
   
                                }
//                                .foregroundColor(CDStack.shared.progressColor(list: list, firstColor: Color.green, secondColor: Color(UIColor.label)))
                                if userSettings.showProgressBar {
                                    ProgressView(value: CDStack.shared.progressCount(list: list))
                                        //.scaleEffect(x: 1, y: 4, anchor: .center)
                                        .progressViewStyle(LinearProgressViewStyle(tint: CDStack.shared.progressColor(list: list, firstColor: Color.green, secondColor: Color.blue)))
                                }
                                
                                    
                            }
                            
                            .onReceive(list.objectWillChange) { _ in
                                refreshingID = UUID()
                            }
                            
                        }
                    }
                    .onDelete(perform: deleteList)

                    
//                    .listRowBackground(ProgressView(value: CDStack.shared.progressCount(list: lists[0]))
//                                        .scaleEffect(x: 1, y: 10, anchor: .center)
//                                        .progressViewStyle(LinearProgressViewStyle(tint: CDStack.shared.progressColor(list: lists[0], firstColor: Color.green, secondColor: Color.blue).opacity(0.6))))
                    

                    
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
                            Text(TxtLocal.Text.newList)
                                .foregroundColor(Color(.systemRed))
                            Spacer()
                        }
                    }
                }.id(refreshingID)
                .listStyle(InsetGroupedListStyle())
                .edgesIgnoringSafeArea(.bottom)
                .navigationTitle(TxtLocal.Navigation.Title.lists)
                .navigationBarItems(
                    leading: Button(action: {
                        activeSheet = .userSetting
                    }, label: {
                        Image(systemName: "line.horizontal.3")
                            .resizable()
                            .frame(width: 24, height: 14)
                    }),
                    trailing: Button(action: {
                        IAPManager.shared.validateReceipt()
                    }, label: {
                        Text("iCloud")
                            .font(.system(size: 12, weight: .thin, design: .default))
                            .padding(4)
                            .accentColor(Color(UIColor.label))
                            .background(userSettings.icloudBackup ? Color.green.opacity(0.9) : Color.red.opacity(0.9))
                            .cornerRadius(4)
                    })
                )
                .sheet(item: $activeSheet) { item in
                    switch item {
                    case .newList:
                        NewListView(size: size, colorVM: colorVM, iconVM: iconVM)
                            .environment(\.managedObjectContext, viewContext)
                            .edgesIgnoringSafeArea(.all)
                    case .userSetting:
                        SettingsView(userSettings: userSettings)
                            .environment(\.managedObjectContext, viewContext)
                    }
                }
            }
        })
        .onAppear() {
            switch UIDevice.current.userInterfaceIdiom {
            case .unspecified:
                size = 35
            case .phone:
                size = 35
            case .pad:
                size = 60
//            case .tv:
//                <#code#>
//            case .carPlay:
//                <#code#>
//            case .mac:
//                <#code#>
            @unknown default:
                size = 35
            }
        }
        
        
    }
    
    private func deleteList(offsets: IndexSet) {
        offsets.map { lists[$0] }.forEach(viewContext.delete)
        CDStack.shared.saveContext(context: viewContext)
    }
    
    
    
}

