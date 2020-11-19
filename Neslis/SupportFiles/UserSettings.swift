//
//  SettingStore.swift
//  Neslis
//
//  Created by Sergey Volkov on 26.07.2020.
//  Copyright © 2020 Sergei Volkov. All rights reserved.
//

import Foundation

class UserSettings: ObservableObject {
    
    static var shared = UserSettings()
    
    @Published var icloudBackup: Bool {
        didSet {
            UserDefaults.standard.set(icloudBackup, forKey: UDKeys.Settings.icloudBackup)
        }
    }
    @Published var sharingNotification: Bool {
        didSet {
            UserDefaults.standard.set(sharingNotification, forKey: UDKeys.Settings.sharingNotification)
            if sharingNotification == true {
                DispatchQueue.main.async {
                    NotifManager.requestAuthoriz()
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
    
    init() {
        self.icloudBackup = UserDefaults.standard.object(forKey: UDKeys.Settings.icloudBackup) as? Bool ?? false
        self.sharingNotification = UserDefaults.standard.object(forKey: UDKeys.Settings.sharingNotification) as? Bool ?? false
        self.proVersion = UserDefaults.standard.object(forKey: UDKeys.Settings.proVersion) as? Bool ?? false
        self.useListColor = UserDefaults.standard.object(forKey: UDKeys.Settings.useListColor) as? Bool ?? false
    }
}
