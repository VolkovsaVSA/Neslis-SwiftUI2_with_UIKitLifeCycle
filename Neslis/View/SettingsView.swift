//
//  SettingsView.swift
//  Neslis
//
//  Created by Sergey Volkov on 09.11.2020.
//

import SwiftUI
import CloudKit

struct SettingsView: View {
    
//    enum AlertType: Identifiable {
//        case saveRewrite, loadRewrite, networkError, oldIcloudData, noIcloudData
//        var id: Int {
//            hashValue
//        }
//    }
    //@State var myAlert: AlertType?
    @ObservedObject var myAlert = UserAlert.shared
    
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
    //@State var firstCreateZone = UserDefaults.standard.bool(forKey: UDKeys.firstCreateZone)

    @ObservedObject var progressBar = ProgressData.shared
    
    @State var activitySpinnerAnimate = false
    @State var activitySpinnerText = ""
    @State var finishMessage = ""
    @State var finishButtonShow = false
    
    @State var showPurchase = false
    
    @ObservedObject var userAlert = UserAlert.shared
    
//    fileprivate func attentionAlert() -> Binding<Bool> {
//        Binding<Bool>(
//            get: { userSettings.icloudBackup },
//            set: { _ in }
//        )
//    }
    
    fileprivate func loadData(rewrite: Bool) {
        progressBar.setZero()
        
        activitySpinnerText = "Restoring..."
        finishButtonShow = false
        activitySpinnerAnimate = true
        userSettings.icloudBackup = false
        
        if rewrite {
            listsCD.forEach { list in
                viewContext.delete(list)
            }
            CDStack.shared.saveContext(context: viewContext)
        }
        
        CloudKitManager.FetchFromCloud.fetchListDataFromPrivateDB(db: CloudKitManager.cloudKitPrivateDB) { (lists, error) in
            
            print("end loading. Progress: \(ProgressData.shared.value)")

            if error != nil {
                print("error load from icloud: \(String(describing: error?.localizedDescription))")
                finishMessage = errorNetworkAlert.text
            } else {
                finishMessage = loadNetworkAlert.text
            }
            
            CDStack.shared.saveContext(context: viewContext)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                finishButtonShow = true
                userSettings.icloudBackup = true
            }

        }
    }
    fileprivate func saveData(rewrite: Bool) {
        
        finishButtonShow = false
        activitySpinnerAnimate = true
        progressBar.setZero()
        activitySpinnerText = "Saving..."
        
        
        func saveAllObjects(completion: @escaping (String)->Void) {
            var message = ""
            CloudKitManager.SaveToCloud.saveAllObjectsToCloud() { error in
                print("end uploading. Progress: \(ProgressData.shared.value)")

                if error != nil {
                    print("error save to icloud: \(String(describing: error?.localizedDescription))")
                    message = errorNetworkAlert.text
                } else {
                    message = saveNetworkAlert.text
                }
                completion(message)

            }
        }
        
        if rewrite {
            CloudKitManager.Zone.deleteZone { clearError in
                if clearError == nil {
                    saveAllObjects { saveMessage1 in
                        finishMessage = saveMessage1
                    }
                } else {
                    print("clearError: \(clearError!.localizedDescription)")
                    finishMessage =  errorNetworkAlert.text
                }
                finishButtonShow = true
            }
        } else {
            saveAllObjects { saveMessage2 in
                finishMessage = saveMessage2
                finishButtonShow = true
            }
        }
        
    }
    fileprivate func byFullVersion() {
        print("\(IAPManager.shared.products)")
        if IAPManager.shared.products.isEmpty {
            DispatchQueue.main.async {
                myAlert.alertType = .networkError
            }
        } else {
            showPurchase = true
        }
    }
    fileprivate func didsetIcloudBackupValue(_ newValue: Bool) {
        if newValue {
            activitySpinnerAnimate = true
            activitySpinnerText = "Fetch data from iCloud"
            CloudKitManager.FetchFromCloud.fetchListCountFromPrivateDB { result in
                
                activitySpinnerAnimate = false
                
                switch result {
                case .success(let count):
                    if count > 0 {
                        DispatchQueue.main.async {
                            myAlert.alertType = .oldIcloudData
                        }
                        
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    DispatchQueue.main.async {
                        myAlert.alertType = .networkError
                        userSettings.icloudBackup = false
                    }
                }
            }
        }
    }
    fileprivate func saveButtonAction() {
        activitySpinnerAnimate = true
        activitySpinnerText = "Fetch data from iCloud"
        
        CloudKitManager.FetchFromCloud.fetchListCountFromPrivateDB { result in
            activitySpinnerAnimate = false
            
            switch result {
            case .success(let count):
                if count > 0 {
                    DispatchQueue.main.async {
                        myAlert.alertType = .saveRewrite
                    }
                } else {
                    saveData(rewrite: true)
                }
            case .failure(let error):
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    myAlert.alertType = .networkError
                }
            }
        }
    }
    fileprivate func restoreButtonAction() {
        let coreDataCount = CDStack.shared.fetchList(context: viewContext).count
        activitySpinnerAnimate = true
        activitySpinnerText = "Fetch data from iCloud"
        
        CloudKitManager.FetchFromCloud.fetchListCountFromPrivateDB { result in
            activitySpinnerAnimate = false
            switch result {
            case .success(let count):
                if count > 0 {
                    if coreDataCount > 0 {
                        DispatchQueue.main.async {
                            myAlert.alertType = .loadRewrite
                        }
                    } else {
                        loadData(rewrite: false)
                    }
                } else {
                    DispatchQueue.main.async {
                        myAlert.alertType = .noIcloudData
                    }
                }
            case .failure(let error):
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    myAlert.alertType = .networkError
                }
                
            }
        }
    }
    fileprivate func creatAlert(_ alert: AlertType) -> Alert {
        switch alert {
        case .saveRewrite:
            return Alert(title: Text("Attention!"), message: Text("You are have another iCloud data. Do you want rewreite this data or joined all data?"), primaryButton: .destructive(Text("Rewrite"), action: {
                saveData(rewrite: true)
            }), secondaryButton: .default(Text("Joined"), action: {
                saveData(rewrite: false)
            }))
        case .loadRewrite:
            return Alert(
                title: Text("Attention!"),
                message: Text("You are have data on your phone. Do you want rewreite this data or joined all data?"),
                primaryButton: .destructive(Text("Rewrite"), action: {
                    loadData(rewrite: true)
                }),
                secondaryButton: .default(Text("Joined"), action: {
                    loadData(rewrite: false)
                })
            )
        case .networkError:
            return Alert(
                title: Text(errorNetworkAlert.title),
                message: Text(errorNetworkAlert.text),
                dismissButton: .cancel(Text("OK"))
            )
        case .oldIcloudData:
            return Alert(
                title: Text("Attention!"),
                message: Text("You are have backup data! Do you want to load this data?"),
                primaryButton: .default(Text("Load"), action: {
                    loadData(rewrite: false)
                }),
                secondaryButton: .cancel(Text("Cancel"))
            )
        case .noIcloudData:
            return Alert(
                title: Text("Attention!"),
                message: Text("No backup data in iCloud."),
                dismissButton: .cancel(Text("OK"))
            )
        case .noAccessToNotification:
            return Alert(
                title: Text(""),
                message: Text(""),
                dismissButton: .cancel(Text("OK"))
            )
        }
    }
    
    var body: some View {
        LoadingView(isShowing: $activitySpinnerAnimate, text: activitySpinnerText, messageText: $finishMessage, result: $finishButtonShow, progressBar: $progressBar.value) {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Section(header: Text("Purchases").font(.title).foregroundColor(.gray)) {
                            Button("Pro Version") {
                                byFullVersion()
                            }
                            .modifier(SettingButtonModifire(disable: false))
                            Button("Restore purchases") {
                                
                                IAPManager.shared.restoreCompletedTransaction()
                            }
                            .modifier(SettingButtonModifire(disable: false))
                        }
                        
                        Section(header: Text("iCloud").font(.title).foregroundColor(.gray)) {
                            
                            if userSettings.proVersion {
                                if acountStatus == .available {
                                    Toggle("Enable backup to iCloud and sharing lists", isOn: $userSettings.icloudBackup.didSet(execute: { newValue in
                                        didsetIcloudBackupValue(newValue)
                                    })
                                    .animation())
                                    
                                    if userSettings.icloudBackup {
                                        Button("Save data") {
                                            saveButtonAction()
                                        }
                                        .modifier(SettingButtonModifire(disable: false))
                                        Button("Restore data") {
                                            restoreButtonAction()
                                        }
                                        .modifier(SettingButtonModifire(disable: false))
//                                        Button("Clear iCloud DB") {
//                                            CloudKitManager.Zone.deleteZone { error in
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
                        
                        Section(header: Text("Visual settings").font(.title).foregroundColor(.gray)) {
                            Toggle("Use the color of the list-icon to visual style the list", isOn: $userSettings.useListColor)
                            Toggle("Show 'expand all' button", isOn: $userSettings.showAllExpandButton)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .onAppear {
                    CloudKitManager.checkIcloudStatus { status in
                        acountStatus = status
                    }
                    if !userSettings.zonIsCreated {
                        CloudKitManager.Zone.createZone { error in
                            if let error = error {
                                print(error.localizedDescription)
                            }
                        }
                    }

                    IAPManager.shared.getProducts()
                }
                .alert(item: $myAlert.alertType) { alert in
                    return creatAlert(alert)
                }
                .sheet(isPresented: $showPurchase) {
                    PurchaseView()
                        .environment(\.managedObjectContext, viewContext)
                }
                .navigationBarTitle("Settings")
            }
        }
        
        
    }
}

