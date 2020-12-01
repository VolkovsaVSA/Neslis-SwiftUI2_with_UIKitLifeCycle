//
//  SettingsView.swift
//  Neslis
//
//  Created by Sergey Volkov on 09.11.2020.
//

import SwiftUI
import CloudKit

struct SettingsView: View {
    
    enum AlertType: Identifiable {
        case saveRewrite, loadRewrite, networkError, oldIcloudData, noIcloudData
        var id: Int {
            hashValue
        }
    }
    @State var myAlert: AlertType?
    
    struct NetworkAlert {
        var title = ""
        var text = ""
    }
    
    private let errorNetworkAlert = NetworkAlert(title: "Network error", text: "Please check the internet connection or re-authenticate in an iCloud account or try later.")
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
    
    fileprivate func attentionAlert() -> Binding<Bool> {
        Binding<Bool>(
            get: { userSettings.icloudBackup },
            set: { _ in }
        )
    }

    fileprivate func loadData(rewrite: Bool) {
        progressBar.setZero()
        activityText = "Restoring..."
        
        userSettings.icloudBackup = false
        
        if rewrite {
            listsCD.forEach { list in
                viewContext.delete(list)
            }
            CDStack.shared.saveContext(context: viewContext)
        }
        
        result = false
        loading = true
        CloudKitManager.FetchFromCloud.fetchListData(db: CloudKitManager.cloudKitPrivateDB) { (lists, error) in
            
            print("end loading. Progress: \(ProgressData.shared.value)")
            if error != nil {
                print("error load from icloud: \(String(describing: error?.localizedDescription))")
                message = errorNetworkAlert.text
            } else {
                message = loadNetworkAlert.text
            }
            
            CDStack.shared.saveContext(context: viewContext)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                result = true
                userSettings.icloudBackup = true
            }

        }
    }
    fileprivate func saveData(rewrite: Bool) {
        func saveAllObjects() {
            CloudKitManager.SaveToCloud.saveAllObjectsToCloud() { error in
                print("end uploading. Progress: \(ProgressData.shared.value)")
                if error != nil {
                    print("error save to icloud: \(String(describing: error?.localizedDescription))")
                    message = errorNetworkAlert.text
                } else {
                    message = saveNetworkAlert.text
                }

            }
        }
        
        progressBar.setZero()
        activityText = "Saving..."
        result = false
        loading = true
        
        if rewrite {
            CloudKitManager.Zone.deleteZone { clearError in
                if clearError == nil {
                    saveAllObjects()
                } else {
                    print("clearError: \(clearError!.localizedDescription)")
                    message =  errorNetworkAlert.text
                }
            }
        } else {
            saveAllObjects()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            result = true
        }
        
    }
    
    var body: some View {
        LoadingView(isShowing: $loading, text: activityText, messageText: $message, result: $result, progressBar: $progressBar.value) {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Section(header: Text("Purchases").font(.title).foregroundColor(.gray)) {
                            Button("Pro Version") {
                                print("\(IAPManager.shared.products.isEmpty)")
                                if IAPManager.shared.products.isEmpty {
                                    myAlert = .networkError
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
                                    Toggle("Enable backup to iCloud and sharing lists", isOn: $userSettings.icloudBackup.didSet(execute: { newValue in
                                        if newValue {
                                            loading = true
                                            activityText = "Fetch data from iCloud"
                                            CloudKitManager.FetchFromCloud.fetchListCount { result in
                                                loading = false
                                                activityText = ""
                                                switch result {
                                                case .success(let count):
                                                    if count > 0 {
                                                        myAlert = .oldIcloudData
                                                    }
                                                case .failure(let error):
                                                    print(error.localizedDescription)
                                                    myAlert = .networkError
                                                    userSettings.icloudBackup = false
                                                }
                                            }
                                        }
                                    })
                                    .animation())
                                    
                                    if userSettings.icloudBackup {
                                        Button("Save data") {
                                            loading = true
                                            activityText = "Fetch data from iCloud"
                                            CloudKitManager.FetchFromCloud.fetchListCount { result in
                                                loading = false
                                                activityText = ""
                                                switch result {
                                                case .success(let count):
                                                    if count > 0 {
                                                        myAlert = .saveRewrite
                                                    } else {
                                                        saveData(rewrite: true)
                                                    }
                                                case .failure(let error):
                                                    print(error.localizedDescription)
                                                    myAlert = .networkError
                                                }
                                            }
                                        }
                                        .modifier(SettingButtonModifire(disable: false))
                                        Button("Restore data") {
                                            let coreDataCount = CDStack.shared.fetchList(context: viewContext).count
                                            
                                            loading = true
                                            activityText = "Fetch data from iCloud"
                                            CloudKitManager.FetchFromCloud.fetchListCount { result in
                                                loading = false
                                                activityText = ""
                                                switch result {
                                                case .success(let count):
                                                    if count > 0 {
                                                        if coreDataCount > 0 {
                                                            myAlert = .loadRewrite
                                                        } else {
                                                            loadData(rewrite: false)
                                                        }
                                                    } else {
                                                        myAlert = .noIcloudData
                                                    }
                                                case .failure(let error):
                                                    print(error.localizedDescription)
                                                    myAlert = .networkError
                                                }
                                            }
                                           
                                        }
                                        .modifier(SettingButtonModifire(disable: false))
                                        Button("Clear iCloud DB") {
                                            CloudKitManager.Zone.deleteZone { error in
                                                if let clearError = error {
                                                    print("error in clear DB: \(clearError.localizedDescription))")
                                                }
                                            }
                                        }
                                        .modifier(SettingDeleteButtonModifire())
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
                    CloudKitManager.Zone.createZone { error in
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
                .alert(item: $myAlert) { alert in
                    switch alert {
                    case .saveRewrite:
                        return Alert(title: Text("Attention!"), message: Text("You are have another iCloud data. Do you want rewreite this data or joined all data?"), primaryButton: .destructive(Text("Rewrite"), action: {
                            saveData(rewrite: true)
                        }), secondaryButton: .default(Text("Joined"), action: {
                            saveData(rewrite: false)
                        }))
                    case .loadRewrite:
                        return Alert(title: Text("Attention!"), message: Text("You are have data on your phone. Do you want rewreite this data or joined all data?"), primaryButton: .destructive(Text("Rewrite"), action: {
                            loadData(rewrite: true)
                        }), secondaryButton: .default(Text("Joined"), action: {
                            loadData(rewrite: false)
                        }))
                    case .networkError:
                        return Alert(title: Text(errorNetworkAlert.title), message: Text(errorNetworkAlert.text), dismissButton: .cancel(Text("OK")))
                    case .oldIcloudData:
                        return Alert(title: Text("Attention!"), message: Text("You are have backup data! Do you want to load this data?"), primaryButton: .default(Text("Load"), action: {
                            loadData(rewrite: false)
                        }), secondaryButton: .cancel(Text("Cancel")))
                    case .noIcloudData:
                        return Alert(title: Text("Attention!"), message: Text("No backup data in iCloud."), dismissButton: .cancel(Text("OK")))
                    }
                    
                }

                .navigationBarTitle("Settings")
            }
        }
        
        
    }
}

