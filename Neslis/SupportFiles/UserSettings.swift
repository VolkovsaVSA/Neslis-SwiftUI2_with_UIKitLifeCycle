//
//  SettingStore.swift
//  Neslis
//
//  Created by Sergey Volkov on 26.07.2020.
//  Copyright © 2020 Sergei Volkov. All rights reserved.
//

import SwiftUI
import CloudKit

class UserSettings: ObservableObject {
    
    static var shared = UserSettings()
    
    @Published var icloudBackup: Bool {
        didSet {
            UserDefaults.standard.set(icloudBackup, forKey: UDKeys.Settings.icloudBackup)
        }
    }
    @Published var sharingNotification: Bool = false {
        didSet {
            UserDefaults.standard.set(sharingNotification, forKey: UDKeys.Settings.sharingNotification)
            if sharingNotification == true {
                DispatchQueue.main.async {
                    NotifManager.requestAuthoriz()
                }
            }
            else {
                CloudKitManager.cloudKitSharedDB.fetchAllSubscriptions { (subs, error) in
                    if let subscriptions = subs {
                        let subsID = subscriptions.map {$0.subscriptionID}
                        CloudKitManager.Subscription.deleteRecordZoneSubscription(db: CloudKitManager.cloudKitSharedDB, subscriptionID: subsID)
                    }
                }
            }
        }
    }
    @Published var proVersion: Bool {
        didSet {
            UserDefaults.standard.set(proVersion, forKey: UDKeys.Settings.proVersion)
            UserDefaults.standard.set(proVersion, forKey: UDKeys.Settings.icloudBackup)
            UserDefaults.standard.set(proVersion, forKey: UDKeys.Settings.sharingNotification)
        }
    }
    @Published var useListColor: Bool {
        didSet {
            UserDefaults.standard.setValue(useListColor, forKey: UDKeys.Settings.useListColor)
        }
    }
    @Published var zonIsCreated : Bool {
        didSet {
            UserDefaults.standard.setValue(zonIsCreated, forKey: UDKeys.Settings.zonIsCreated)
        }
    }
    @Published var showAllExpandButton: Bool {
        didSet {
            UserDefaults.standard.setValue(showAllExpandButton, forKey: UDKeys.Settings.showAllExpandButton)
        }
    }
    @Published var showProgressBar: Bool {
        didSet {
            UserDefaults.standard.setValue(showProgressBar, forKey: UDKeys.Settings.showProgressBar)
        }
    }
    @Published var showListCounter: Bool {
        didSet {
            UserDefaults.standard.setValue(showListCounter, forKey: UDKeys.Settings.showListCounter)
        }
    }
    
    
    
    init() {
        self.icloudBackup = UserDefaults.standard.object(forKey: UDKeys.Settings.icloudBackup) as? Bool ?? false
        self.sharingNotification = UserDefaults.standard.object(forKey: UDKeys.Settings.sharingNotification) as? Bool ?? false
        self.proVersion = UserDefaults.standard.object(forKey: UDKeys.Settings.proVersion) as? Bool ?? false
        self.useListColor = UserDefaults.standard.object(forKey: UDKeys.Settings.useListColor) as? Bool ?? false
        self.zonIsCreated = UserDefaults.standard.object(forKey: UDKeys.Settings.zonIsCreated) as? Bool ?? false
        self.showAllExpandButton = UserDefaults.standard.object(forKey: UDKeys.Settings.showAllExpandButton) as? Bool ?? true
        self.showProgressBar = UserDefaults.standard.object(forKey: UDKeys.Settings.showProgressBar) as? Bool ?? false
        self.showListCounter = UserDefaults.standard.object(forKey: UDKeys.Settings.showListCounter) as? Bool ?? true
    }
}
