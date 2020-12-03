//
//  NotifManager.swift
//  Neslis
//
//  Created by Sergey Volkov on 05.09.2020.
//  Copyright © 2020 Sergei Volkov. All rights reserved.
//

import Foundation
import UserNotifications
import SwiftUI

class NotifManager {
    
    static func requestAuthoriz() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { authorised, error in
            DispatchQueue.main.async {
                let userSettings = UserSettings.shared
                
                guard authorised else {
                    print(error?.localizedDescription as Any)
                    
                    userSettings.sharingNotification = false
                    let userAlert = UserAlert.shared
                    userAlert.title = "Error"
                    userAlert.text = "You turned off notification in settings. Please turn on the notifications for this application in the system settings."
                    userAlert.show = true
                    return
                }
                
                !userSettings.sharingNotification ? userSettings.sharingNotification.toggle() : nil
            }
        }
    }
    
    
    
}
