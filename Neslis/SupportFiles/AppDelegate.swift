//
//  AppDelegate.swift
//  Neslis
//
//  Created by Sergey Volkov on 22.07.2020.
//  Copyright © 2020 Sergei Volkov. All rights reserved.
//

import UIKit
import CloudKit
import UserNotifications
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        //print("userInfo: \(userInfo.description)")
        var fetchConfigurations = [CKRecordZone.ID : CKFetchRecordZoneChangesOperation.ZoneConfiguration]()
        var changeToken: CKServerChangeToken? = nil
        
        CloudKitManager.cloudKitSharedDB.fetchAllRecordZones { (recordZones, error) in
            
            guard let zones =  recordZones else {return}
            var zonesID = [CKRecordZone.ID]()
            
            zones.forEach { recordZone in
                
                zonesID.append(recordZone.zoneID)
                
                if let changeTokenData = UserDefaults.standard.data(forKey: recordZone.zoneID.description) {
                    
                    do {
                        changeToken = try NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: changeTokenData)
                        let configuration = CKFetchRecordZoneChangesOperation.ZoneConfiguration(previousServerChangeToken: changeToken, resultsLimit: nil, desiredKeys: nil)
                        configuration.previousServerChangeToken = changeToken
                        fetchConfigurations[recordZone.zoneID] = configuration
                    } catch {
                        print(error.localizedDescription)
                    }
                    
                }
                
            }
            
            let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: zonesID, configurationsByRecordZoneID: fetchConfigurations)
            operation.fetchAllChanges = true
            operation.recordChangedBlock = { record in
                //processing the received a modified record
                CDStack.shared.saveChangeRecord(record: record, context: CDStack.shared.container.viewContext)
            }
            operation.recordWithIDWasDeletedBlock = { recordID, recordType in
                //processing the received a delete record
                print("deleteRecord: \(recordID)")
                
                
            }
            
            operation.recordZoneChangeTokensUpdatedBlock = { zoneID, changeToken, data in
                guard let changeToken = changeToken else { return }
                do {
                    let changeTokenData = try NSKeyedArchiver.archivedData(withRootObject: changeToken, requiringSecureCoding: false)
                    UserDefaults.standard.set(changeTokenData, forKey: zoneID.description)
                } catch {
                    print(error.localizedDescription)
                }
                
            }
            operation.recordZoneFetchCompletionBlock = { zoneID, changeToken, data, more, error in
                guard error == nil else { return }
                guard let changeToken = changeToken else { return }
                do {
                    let changeTokenData = try NSKeyedArchiver.archivedData(withRootObject: changeToken, requiringSecureCoding: false)
                    UserDefaults.standard.set(changeTokenData, forKey: zoneID.description)
                } catch {
                    print(error.localizedDescription)
                }
            }
            operation.fetchRecordZoneChangesCompletionBlock = { error in
                guard error == nil else {
                    print(error!.localizedDescription)
                    return
                }
            }
            
            operation.qualityOfService = .utility
            CloudKitManager.cloudKitSharedDB.add(operation)
            completionHandler(.newData)
        }
        
        
//        if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) {
//                    print("CloudKit database changed")
//                    NotificationCenter.default.post(name: .cloudKitChanged, object: nil)
//                    completionHandler(.newData)
//                    return
//        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        CloudKitManager.createZone { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        IAPManager.shared.setupPurchases { success in
            if success {
                print("can make payments")
                IAPManager.shared.getProducts()
            }
        }

        IAPManager.shared.valRec()
        application.registerForRemoteNotifications()

        return true
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
}

