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


//        IAPManager.shared.validateReceipt(showAlert: false)
        
        if UserSettings.shared.proVersion && UserSettings.shared.icloudBackup {
            
            if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo), let subscriptionID = notification.subscriptionID {
                
                let sub = CKDatabaseSubscription(subscriptionID: subscriptionID)
                
                let notificationInfo = CKSubscription.NotificationInfo()
                notificationInfo.shouldSendContentAvailable = true
                sub.notificationInfo = notificationInfo
                
                
                switch subscriptionID {
                case "sharedDbSubsID":
                    print("CloudKit shared database changed")
                    
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
                                    print("fetchAllRecordZones error: \(error.localizedDescription)")
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
                            guard let entity = CDStack.shared.convertRecordTypeToCDEntity(recordType: recordType) else {return}
                            guard let deleteObject = CDStack.shared.fetchOneObject(entityName: entity, id: recordID.recordName, context: CDStack.shared.container.viewContext) else {return}
                            CDStack.shared.container.viewContext.delete(deleteObject)
                            CDStack.shared.saveContext(context: CDStack.shared.container.viewContext)
                        }
                        
                        operation.recordZoneChangeTokensUpdatedBlock = { zoneID, changeToken, data in
                            guard let changeToken = changeToken else { return }
                            do {
                                let changeTokenData = try NSKeyedArchiver.archivedData(withRootObject: changeToken, requiringSecureCoding: false)
                                UserDefaults.standard.set(changeTokenData, forKey: zoneID.description)
                            } catch {
                                print("recordZoneChangeTokensUpdatedBlock error: \(error.localizedDescription)")
                            }
                            
                        }
                        operation.recordZoneFetchCompletionBlock = { zoneID, changeToken, data, more, error in
                            guard error == nil else { return }
                            guard let changeToken = changeToken else { return }
                            do {
                                let changeTokenData = try NSKeyedArchiver.archivedData(withRootObject: changeToken, requiringSecureCoding: false)
                                UserDefaults.standard.set(changeTokenData, forKey: zoneID.description)
                            } catch {
                                print("recordZoneFetchCompletionBlock error: \(error.localizedDescription)")
                            }
                        }
                        operation.fetchRecordZoneChangesCompletionBlock = { error in
                            guard error == nil else {
                                print("fetchRecordZoneChangesCompletionBlock error: \(error!.localizedDescription)")
                                return
                            }
                            
                            
                        }
                        
                        operation.qualityOfService = .userInitiated
                        CloudKitManager.cloudKitSharedDB.add(operation)
                        completionHandler(.newData)
                    }
                    
                case "privateDbSubsID":
                    print("CloudKit private database changed")
                    //fetchSharedCanges(db: CloudKitManager.cloudKitPrivateDB)
                    
                    var fetchConfigurations = [CKRecordZone.ID : CKFetchRecordZoneChangesOperation.ZoneConfiguration]()
                    var changeToken: CKServerChangeToken? = nil
                    
                    CloudKitManager.cloudKitPrivateDB.fetchAllRecordZones { (recordZones, error) in
                        
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
                                    print("fetchAllRecordZones error: \(error.localizedDescription)")
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
                            print("recordWithIDWasDeletedBlock")
                            guard let entity = CDStack.shared.convertRecordTypeToCDEntity(recordType: recordType) else {return}
                            guard let deleteObject = CDStack.shared.fetchOneObject(entityName: entity, id: recordID.recordName, context: CDStack.shared.container.viewContext) else {return}
                            CDStack.shared.container.viewContext.delete(deleteObject)
                            CDStack.shared.saveContext(context: CDStack.shared.container.viewContext)
                        }
                        
                        operation.recordZoneChangeTokensUpdatedBlock = { zoneID, changeToken, data in
                            guard let changeToken = changeToken else { return }
                            do {
                                let changeTokenData = try NSKeyedArchiver.archivedData(withRootObject: changeToken, requiringSecureCoding: false)
                                UserDefaults.standard.set(changeTokenData, forKey: zoneID.description)
                            } catch {
                                print("recordZoneChangeTokensUpdatedBlock error: \(error.localizedDescription)")
                            }
                            
                        }
                        operation.recordZoneFetchCompletionBlock = { zoneID, changeToken, data, more, error in
                            guard error == nil else { return }
                            guard let changeToken = changeToken else { return }
                            do {
                                let changeTokenData = try NSKeyedArchiver.archivedData(withRootObject: changeToken, requiringSecureCoding: false)
                                UserDefaults.standard.set(changeTokenData, forKey: zoneID.description)
                            } catch {
                                print("recordZoneFetchCompletionBlock error: \(error.localizedDescription)")
                            }
                        }
                        operation.fetchRecordZoneChangesCompletionBlock = { error in
                            guard error == nil else {
                                print("fetchRecordZoneChangesCompletionBlock error: \(error!.localizedDescription)")
                                return
                            }
                        }
                        
                        operation.qualityOfService = .userInitiated
                        CloudKitManager.cloudKitPrivateDB.add(operation)
                        completionHandler(.newData)
                    }
                    
                default:
                    break
                }
                
                //NotificationCenter.default.post(name: NSNotification.Name(rawValue: "CKchange"), object: nil)
                
            }
            
        }
        
        
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UserAlert.shared.alertType = nil
        UserAlert.shared.title = ""
        UserAlert.shared.text = ""
        IAPManager.shared.validateReceipt(showAlert: false)
        
        if !UserSettings.shared.zonIsCreated {
            CloudKitManager.Zone.createZone { error in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
        }
        
        IAPManager.shared.setupPurchases { success in
            if success {
                print("can make payments")
                IAPManager.shared.getProducts()
            }
        }
        
        NotifManager.requestAuthoriz()
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

