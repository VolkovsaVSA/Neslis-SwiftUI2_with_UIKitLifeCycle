//
//  SettingsView.swift
//  Neslis
//
//  Created by Sergey Volkov on 09.11.2020.
//

import SwiftUI
import CloudKit
import MessageUI

struct SettingsView: View {
    
    enum ActiveSheet: Identifiable {
        case purchaseView, mailView
        var id: Int {
            hashValue
        }
    }
    @State private var activeSheet: ActiveSheet?

    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: ListCD.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ListCD.dateAdded, ascending: true)]
    )
    var listsCD: FetchedResults<ListCD>
    
    @ObservedObject var userSettings: UserSettings
    @State var acountStatus: CKAccountStatus?
    @ObservedObject var progressBar = ProgressData.shared
    @ObservedObject var userAlert = UserAlert.shared
    
    @State var mailResult: Result<MFMailComposeResult, Error>? = nil
//    @State var isShowingMailView = false
    
//    fileprivate func attentionAlert() -> Binding<Bool> {
//        Binding<Bool>(
//            get: { userSettings.icloudBackup },
//            set: { _ in }
//        )
//    }
    
    fileprivate func loadData(rewrite: Bool) {
        progressBar.setZero()
        
        progressBar.activitySpinnerText = TxtLocal.Alert.Text.restoring
        progressBar.showProgressBar = true
        progressBar.activitySpinnerAnimate = true
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
                userAlert.title = TxtLocal.Alert.Title.error
                userAlert.text = TxtLocal.Alert.Text.pleaseCheckTheInternetConnection
            } else {
                userAlert.title = TxtLocal.Alert.Title.success
                userAlert.text = TxtLocal.Alert.Text.backupDataIsLoadedSuccessfully
            }
            
            CDStack.shared.saveContext(context: viewContext)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                progressBar.activitySpinnerAnimate = false
                userAlert.alertType = .noAccessToNotification
                userSettings.icloudBackup = true
            }

        }
    }
    fileprivate func saveData(rewrite: Bool) {
        
        DispatchQueue.main.async {
            progressBar.showProgressBar = true
            progressBar.activitySpinnerAnimate = true
            progressBar.setZero()
            progressBar.activitySpinnerText = TxtLocal.Alert.Text.saving
        }
        
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
                        DispatchQueue.main.async {
                            userAlert.title = ""
                            userAlert.text = saveMessage1
                            progressBar.activitySpinnerAnimate = false
                            userAlert.alertType = .noAccessToNotification
                        }
                    }
                } else {
                    print("clearError: \(clearError!.localizedDescription)")
                    DispatchQueue.main.async {
                        userAlert.title = ""
                        userAlert.text = TxtLocal.Alert.Text.pleaseCheckTheInternetConnection
                        progressBar.activitySpinnerAnimate = false
                        userAlert.alertType = .noAccessToNotification
                    }
                }
            }
        } else {
            saveAllObjects { saveMessage2 in
                DispatchQueue.main.async {
                    progressBar.activitySpinnerAnimate = false
                    userAlert.title = ""
                    userAlert.text = saveMessage2
                    userAlert.alertType = .noAccessToNotification
                }
                
            }
        }
        
    }
    fileprivate func byFullVersion() {
        print("\(IAPManager.shared.products)")
        if IAPManager.shared.products.isEmpty {
            DispatchQueue.main.async {
                userAlert.alertType = .networkError
                userAlert.text = TxtLocal.Alert.Text.pleaseCheckTheInternetConnection
            }
        } else {
            activeSheet = .purchaseView
        }
    }
    fileprivate func didsetIcloudBackupValue(_ newValue: Bool) {
        if newValue {
            progressBar.showProgressBar = true
            progressBar.activitySpinnerAnimate = true
            progressBar.activitySpinnerText = TxtLocal.Alert.Text.fetchDataFromICloud
            CloudKitManager.FetchFromCloud.fetchListCountFromPrivateDB { result in
                DispatchQueue.main.async {
                    progressBar.activitySpinnerAnimate = false
                }
                
                switch result {
                case .success(let count):
                    if count > 0 {
                        DispatchQueue.main.async {
                            userAlert.alertType = .oldIcloudData
                        }
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    DispatchQueue.main.async {
                        userAlert.text = error.localizedDescription
                        userAlert.alertType = .networkError
                        userSettings.icloudBackup = false
                    }
                }
            }
        }
    }
    fileprivate func saveButtonAction() {
        progressBar.showProgressBar = true
        progressBar.activitySpinnerAnimate = true
        progressBar.activitySpinnerText = TxtLocal.Alert.Text.fetchDataFromICloud
        
        CloudKitManager.FetchFromCloud.fetchListCountFromPrivateDB { result in
            print(#function, " ", result)
            DispatchQueue.main.async {
                progressBar.activitySpinnerAnimate = false
            }
            switch result {
            case .success(let count):
                if count > 0 {
                    DispatchQueue.main.async {
                        userAlert.alertType = .saveRewrite
                    }
                } else {
                    saveData(rewrite: true)
                }
            case .failure(let error):
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    userAlert.text = error.localizedDescription
                    userAlert.alertType = .networkError
                }
            }
        }
    }
    fileprivate func restoreButtonAction() {
        let coreDataCount = CDStack.shared.fetchList(context: viewContext).count
        progressBar.showProgressBar = true
        progressBar.activitySpinnerAnimate = true
        progressBar.activitySpinnerText = TxtLocal.Alert.Text.fetchDataFromICloud
        
        CloudKitManager.FetchFromCloud.fetchListCountFromPrivateDB { result in
            DispatchQueue.main.async {
                progressBar.activitySpinnerAnimate = false
            }
            
            switch result {
            case .success(let count):
                if count > 0 {
                    if coreDataCount > 0 {
                        DispatchQueue.main.async {
                            userAlert.alertType = .loadRewrite
                        }
                    } else {
                        loadData(rewrite: false)
                    }
                } else {
                    DispatchQueue.main.async {
                        userAlert.alertType = .noIcloudData
                    }
                }
            case .failure(let error):
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    userAlert.alertType = .networkError
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
                message: Text(userAlert.text),
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
                title: Text(userAlert.title),
                message: Text(userAlert.text),
                dismissButton: .cancel(Text(TxtLocal.Button.ok))
            )
        }
    }
    
    var body: some View {
        LoadingView(isShowing: $progressBar.activitySpinnerAnimate, text: progressBar.activitySpinnerText, progressBar: $progressBar.value, showProgressBar: $progressBar.showProgressBar) {
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
                                        .fixedSize(horizontal: false, vertical: true)
                                        .font(.system(size: 17, weight: .thin, design: .default))
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(nil)
                                }
                            } else {
                                Text(TxtLocal.Text.purchaseProVersionForBackup)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .font(.system(size: 17, weight: .thin, design: .default))
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
                            }
                            
                        }
                        
                        Section(header: Text(TxtLocal.Text.visualSettings).font(.title).foregroundColor(.gray)) {
                            Toggle(TxtLocal.Toggle.useIconColorinList, isOn: $userSettings.useListColor)
                            Toggle(TxtLocal.Toggle.showExpandAllButton, isOn: $userSettings.showAllExpandButton)
                            Toggle(TxtLocal.Toggle.showProgressBar, isOn: $userSettings.showProgressBar)
                            Toggle(TxtLocal.Toggle.showListCounter, isOn: $userSettings.showListCounter)
                        }.fixedSize(horizontal: false, vertical: true)
                        Section(header: Text(TxtLocal.Text.feedback).font(.title).foregroundColor(.gray)) {

                            Button {
                                activeSheet = .mailView
                            } label: {
                                HStack {
                                    VStack(alignment: .leading ,spacing: 0) {
                                        Text(TxtLocal.Text.sendEmailToTheDeveloper)
                                        if !MFMailComposeViewController.canSendMail() {
                                            Text(TxtLocal.Text.toSendEmail)
                                                .font(.system(size: 10, weight: .thin, design: .default))
                                        }
                                    }
                                    Spacer()
                                    ChevronView()
                                }
                            }
                            .buttonStyle(FeedbackButtonStyle(disable: !MFMailComposeViewController.canSendMail()))
                            
                            Button {
                                if let url = AppId.appUrl {
                                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                }
                            } label: {
                                HStack{
                                    Text(TxtLocal.Text.rateTheApp)
                                    Spacer()
                                    ChevronView()
                                }
                            }
                            .buttonStyle(FeedbackButtonStyle(disable: false))
                            
                            Button {
                                if let url = AppId.developerUrl {
                                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                }
                            } label: {
                                HStack{
                                    Text(TxtLocal.Text.otherApplications)
                                    Spacer()
                                    ChevronView()
                                }
                            }
                            .buttonStyle(FeedbackButtonStyle(disable: false))


                        }.fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .onAppear {
                    userAlert.alertType = nil
                    
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
                .alert(item: $userAlert.alertType) { alert in
                    return creatAlert(alert)
                }
                .sheet(item: $activeSheet) { item in
                    switch item {
                    case .mailView:
                        MailView(result: $mailResult, recipients: [AppId.feedbackEmail], messageBody: TxtLocal.contentBody.feedbackOnApplication)
                    case .purchaseView:
                        PurchaseView()
                            .environment(\.managedObjectContext, viewContext)
                    }
                }
                .navigationBarTitle(TxtLocal.Navigation.Title.settings)
            }
        }
        
        
    }
}

