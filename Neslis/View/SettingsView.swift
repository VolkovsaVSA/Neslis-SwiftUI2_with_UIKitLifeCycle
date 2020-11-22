//
//  SettingsView.swift
//  Neslis
//
//  Created by Sergey Volkov on 09.11.2020.
//

import SwiftUI
import CloudKit

struct SettingsView: View {
    
    struct NetworkAlert {
        var title = ""
        var text = ""
    }
    
    private let errorNetworkAlert = NetworkAlert(title: "Network error", text: "Network error. Please check the internet connection or re-authenticate in an iCloud account.")
    private let saveNetworkAlert = NetworkAlert(title: "Success", text: "Backup data is saved successfully.")
    private let loadNetworkAlert = NetworkAlert(title: "Success", text: "Backup data is loaded successfully.")

    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: ListCD.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ListCD.dateAdded, ascending: true)]
    )
    var listsCD: FetchedResults<ListCD>
    @ObservedObject var userSettings: UserSettings
    
    @State var acountStatus: CKAccountStatus?
    @State var firstCreateZone = UserDefaults.standard.bool(forKey: UDKeys.firstCreateZone)
    
    @State var loading = false
    @State var activityText = ""
    @State var message = ""
    @State var result = false
    @ObservedObject var progressBar = ProgressData.shared
    
    @State private var downloadAmount = 0.0
    
    @State var showPurchase = false
    @State var showSaveAlert = false

    fileprivate func loadData() {
        //showingAlert = false
        activityText = "Restoring..."
        listsCD.forEach { list in
            viewContext.delete(list)
        }
        CDStack.shared.saveContext(context: viewContext)
        loading = true
        CloudKitManager.fetchListData(db: CloudKitManager.cloudKitPrivateDB) { (lists, error) in
            guard error == nil else {
                print("fetch error")
                print(error!.localizedDescription)
                loading = false
                UserAlert.shared.title = errorNetworkAlert.title
                UserAlert.shared.text = errorNetworkAlert.text
                return
            }
            print("end loading")

            UserAlert.shared.title = loadNetworkAlert.title
            UserAlert.shared.text = loadNetworkAlert.text
            loading = false
            CDStack.shared.saveContext(context: viewContext)
        }
    }
    fileprivate func saveData() {
        progressBar.setZero()
        activityText = "Saving..."
        result = false
        loading = true
        CloudKitManager.clearDB { clearError in
            if clearError == nil {
                CloudKitManager.saveAllObjectsToCloud() { error in
                    print("end uploading. Progress: \(ProgressData.shared.value)")
                    if error != nil {
                        message = errorNetworkAlert.text
                    } else {
                        message = saveNetworkAlert.text
                    }

                }
            } else {
                print("clearError: \(clearError!.localizedDescription)")
                message =  errorNetworkAlert.text
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                result = true
            }
        }
    }
    
    var body: some View {
        LoadingView(isShowing: $loading, messageText: $message, result: $result, progressBar: $progressBar.value, text: activityText) {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Section(header: Text("Purchases").font(.title).foregroundColor(.gray)) {
                            Button("Pro Version") {
                                print("\(IAPManager.shared.products.isEmpty)")
                                if IAPManager.shared.products.isEmpty {
                                    UserAlert.shared.title = errorNetworkAlert.title
                                    UserAlert.shared.text = errorNetworkAlert.text
                                    //showingAlert = true
                                } else {
                                    showPurchase = true
                                }
                            }
                            .modifier(SettingButtonModifire(disable: false))
                            Button("Restore purchases") {
                                //temp data
                                userSettings.proVersion = true
                            }
                            .modifier(SettingButtonModifire(disable: false))
                        }
                        //.listRowBackground(Color(UIColor.systemGroupedBackground))
                        Section(header: Text("iCloud").font(.title).foregroundColor(.gray)) {
                            
                            if userSettings.proVersion {
                                if acountStatus == .available {
                                    Toggle("Enable backup to iCloud and sharing lists", isOn: $userSettings.icloudBackup)
                                    if userSettings.icloudBackup {
                                        Button("Save data") {
                                            showSaveAlert = true
                                        }
                                        .modifier(SettingButtonModifire(disable: false))
                                        Button("Restore data") {
                                            loadData()
                                        }
                                        .modifier(SettingButtonModifire(disable: false))
//                                        Button("Clear iCloud DB") {
//                                            CloudKitManager.clearDB { error in
//                                                if let clearError = error {
//                                                    print("error in clear DB: \(clearError.localizedDescription))")
//                                                }
//                                            }
//                                        }
//                                        .modifier(SettingDeleteButtonModifire())
                                        Toggle("Notifications of changes to shared lists", isOn: $userSettings.sharingNotification)
                                    }
                                } else {
                                    HStack {
                                        Text("You are not logged in iCloud, or not all permits granted! Please login to your iCloud account and check all permits in system settings for sharing lists and backup.")
                                            .multilineTextAlignment(.center)
                                            .font(.system(size: 17, weight: .thin, design: .default))
                                    }
                                }
                            } else {
                                HStack {
                                    Text("Purchase Pro version for backup and sharing lists.")
                                        .multilineTextAlignment(.center)
                                        .font(.system(size: 17, weight: .thin, design: .default))
                                }
                            }
                            
                            
                        }
                        //.listRowBackground(Color(UIColor.systemGroupedBackground))
                        Section(header: Text("Visual settings").font(.title).foregroundColor(.gray)) {
                            Toggle("Use the color of the list-icon to visual style the list", isOn: $userSettings.useListColor)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .onAppear {
                    CloudKitManager.checkIcloudStatus { status in
                        acountStatus = status
                    }
                    CloudKitManager.createZone { error in
                        if let error = error {
                            print(error.localizedDescription)
                        }
                    }
                    IAPManager.shared.getProducts()
                }
                
                .sheet(isPresented: $showPurchase) {
                    PurchaseView()
                        .environment(\.managedObjectContext, viewContext)
                }
//                .alert(item: $activeAlert) { item in
//                    
//                    switch item {
//                    case .first:
//                        //print("first")
//                        return Alert(
//                            title: Text(UserAlert.shared.title),
//                            message: Text(UserAlert.shared.text),
//                            dismissButton: .default(Text("OK"))
//                        )
//                    case .second:
//                        //print("second")
//                        return Alert(
//                            title: Text(UserAlert.shared.title),
//                            message: Text(UserAlert.shared.text),
//                            dismissButton: .default(Text("OK"))
//                        )
//                    }
//                }
//                .alert(isPresented: $showingAlert) {
//                    Alert(
//                        title: Text(UserAlert.shared.text),
//                        message: Text(UserAlert.shared.title),
//                        dismissButton: .default(Text("OK"))
//                    )
//                }
                .alert(isPresented: $showSaveAlert) {
                    Alert(title: Text("Atention"),
                          message: Text("If you save your data, all previous data Neslis app in iCloud will be rewritten! Are you sure?"),
                          primaryButton: .destructive(Text("Save data"), action: {
                            saveData()
                          }),
                          secondaryButton: .cancel())
                }

                .navigationBarTitle("Settings")
            }
        }
        
        
    }
}

