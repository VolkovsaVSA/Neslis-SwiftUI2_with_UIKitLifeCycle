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
    
    struct NotifModel {
        var listTitle: String?
        var listId: String?
    }
    
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
                    userAlert.alertType = .noAccessToNotification
                    return
                }
                
                !userSettings.sharingNotification ? userSettings.sharingNotification.toggle() : nil
            }
        }
    }
    
    static func sendNotification(listtitle: String, listID: String) {
        let userSettings = UserSettings.shared
        let content = UNMutableNotificationContent()
        //content.title = "Neslis"
        content.body = "Shared list \"\(listtitle)\" has been changed"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: listID, content: content, trigger: trigger)
        if userSettings.sharingNotification {
            let pastDate = UserDefaults.standard.object(forKey: listID) as? Date
            if Date() >= (pastDate ?? Date()) {
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                UserDefaults.standard.set(Date() + 5, forKey: listID)
                DispatchQueue.main.async {
                    UIApplication.shared.applicationIconBadgeNumber += 1
                }
            }
        }
        
    }
    
    
    
    
}
