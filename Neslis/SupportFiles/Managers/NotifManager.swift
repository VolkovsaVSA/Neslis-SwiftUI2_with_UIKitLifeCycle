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
        //center.delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { authorised, error in

            print("authorised: \(authorised)")
            
            DispatchQueue.main.async {

                guard authorised else {
                    print(error?.localizedDescription as Any)
                    
                    UserSettings.shared.sharingNotification = false
                    UserAlert.shared.title = "Error"
                    UserAlert.shared.text = "You turned off notification in settings. Please turn on the notifications for this application in the system settings."
                    UserAlert.shared.show = true
                    
                    print("settings.sharingNotification: \(UserSettings.shared.sharingNotification)")
                    print("UserDefaults: \(UserDefaults.standard.object(forKey: UDKeys.Settings.sharingNotification) as! Bool)")

                    return
                }
                
            }
        }
        
    }
    
}
