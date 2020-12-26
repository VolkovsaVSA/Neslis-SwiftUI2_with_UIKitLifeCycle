//
//  SettingsView.swift
//  Neslis
//
//  Created by Sergey Volkov on 09.11.2020.
//

import SwiftUI
import CloudKit

struct SettingsView: View {
    
    @ObservedObject var myAlert = UserAlert.shared

    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: ListCD.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ListCD.dateAdded, ascending: true)]
    )
    var listsCD: FetchedResults<ListCD>
    
    @ObservedObject var userSettings: UserSettings
    
    @State var acountStatus: CKAccountStatus?

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
        
        activitySpinnerText = TxtLocal.Alert.Text.restoring
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
                finishMessage = TxtLocal.Alert.Text.pleaseCheckTheInternetConnection
            } else {
                finishMessage = TxtLocal.Alert.Text.backupDataIsLoadedSuccessfully
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
        activitySpinnerText = TxtLocal.Alert.Text.saving
        
        
        func saveAllObjects(completion: @escaping (String)->Void) {
            var message = ""
            CloudKitManager.SaveToCloud.saveAllObjectsToCloud() { error in
                print("end uploading. Progress: \(ProgressData.shared.value)")

                if error != nil {
                    print("error save to icloud: \(String(describing: error?.localizedDescription))")
                    message = TxtLocal.Alert.Text.pleaseCheckTheInternetConnection
                } else {
                    message = TxtLocal.Alert.Text.backupDataIsSavedSuccessfully
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
                    finishMessage =  TxtLocal.Alert.Text.pleaseCheckTheInternetConnection
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
            activitySpinnerText = TxtLocal.Alert.Text.fetchDataFromICloud
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
        activitySpinnerText = TxtLocal.Alert.Text.fetchDataFromICloud
        
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
        activitySpinnerText = TxtLocal.Alert.Text.fetchDataFromICloud
        
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
            return Alert(title: Text(TxtLocal.Alert.Title.attention), message: Text(TxtLocal.Alert.Text.youAreHaveAnotherICloudData), primaryButton: .destructive(Text(TxtLocal.Button.rewrite), action: {
                saveData(rewrite: true)
            }), secondaryButton: .default(Text(TxtLocal.Button.merge), action: {
                saveData(rewrite: false)
            }))
        case .loadRewrite:
            return Alert(
                title: Text(TxtLocal.Alert.Title.attention),
                message: Text(TxtLocal.Alert.Text.youAreHaveDataOnYourPhone),
                primaryButton: .destructive(Text(TxtLocal.Button.rewrite), action: {
                    loadData(rewrite: true)
                }),
                secondaryButton: .default(Text(TxtLocal.Button.merge), action: {
                    loadData(rewrite: false)
                })
            )
        case .networkError:
            return Alert(
                title: Text(TxtLocal.Alert.Title.error),
                message: Text(TxtLocal.Alert.Text.pleaseCheckTheInternetConnection),
                dismissButton: .cancel(Text(TxtLocal.Button.ok))
            )
        case .oldIcloudData:
            return Alert(
                title: Text(TxtLocal.Alert.Title.attention),
                message: Text(TxtLocal.Alert.Text.youAreHaveBackupData),
                primaryButton: .default(Text(TxtLocal.Button.load), action: {
                    loadData(rewrite: false)
                }),
                secondaryButton: .cancel(Text(TxtLocal.Button.cancel))
            )
        case .noIcloudData:
            return Alert(
                title: Text(TxtLocal.Alert.Title.attention),
                message: Text(TxtLocal.Alert.Text.noBackupDataInICloud),
                dismissButton: .cancel(Text(TxtLocal.Button.ok))
            )
        case .noAccessToNotification:
            return Alert(
                title: Text(""),
                message: Text(""),
                dismissButton: .cancel(Text(TxtLocal.Button.ok))
            )
        }
    }
    
    var body: some View {
        LoadingView(isShowing: $activitySpinnerAnimate, text: activitySpinnerText, messageText: $finishMessage, result: $finishButtonShow, progressBar: $progressBar.value) {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Section(header: Text(TxtLocal.Text.purchases).font(.title).foregroundColor(.gray)) {
                            Button(TxtLocal.Button.proVersion) {
                                byFullVersion()
                            }
                            .modifier(SettingButtonModifire(disable: false))
                            Button(TxtLocal.Button.restorePurchases) {
                                
                                IAPManager.shared.restoreCompletedTransaction()
                            }
                            .modifier(SettingButtonModifire(disable: false))
                        }
                        
                        Section(header: Text(TxtLocal.Text.iCloud).font(.title).foregroundColor(.gray)) {
                            
                            if userSettings.proVersion {
                                if acountStatus == .available {
                                    Toggle(TxtLocal.Toggle.enableBackup, isOn: $userSettings.icloudBackup.didSet(execute: { newValue in
                                        didsetIcloudBackupValue(newValue)
                                    })
                                    .animation())
                                    
                                    if userSettings.icloudBackup {
                                        Button(TxtLocal.Button.saveData) {
                                            saveButtonAction()
                                        }
                                        .modifier(SettingButtonModifire(disable: false))
                                        Button(TxtLocal.Button.restoreData) {
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
                                        Toggle(TxtLocal.Toggle.notificationsOfChanges, isOn: $userSettings.sharingNotification)
                                    }
                                    
                                } else {
                                    Text(TxtLocal.Text.yourAreNotLogged)
                                        .multilineTextAlignment(.center)
                                        .font(.system(size: 17, weight: .thin, design: .default))
                                }
                            } else {
                                Text(TxtLocal.Text.purchaseProVersionForBackup)
                                    //.multilineTextAlignment(.center)
                                    .font(.system(size: 17, weight: .thin, design: .default))
                            }
                            
                        }
                        
                        Section(header: Text(TxtLocal.Text.visualSettings).font(.title).foregroundColor(.gray)) {
                            Toggle(TxtLocal.Toggle.useTheColorOfTheList, isOn: $userSettings.useListColor)
                            Toggle(TxtLocal.Toggle.showExpandAllButton, isOn: $userSettings.showAllExpandButton)
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
                .navigationBarTitle(TxtLocal.Navigation.Title.settings)
            }
        }
        
        
    }
}

