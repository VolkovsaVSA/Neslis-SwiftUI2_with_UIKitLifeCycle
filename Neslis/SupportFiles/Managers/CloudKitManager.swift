//
//  CloudKitManager.swift
//  Neslis
//
//  Created by Sergey Volkov on 09.11.2020.
//

import Foundation
import CloudKit
import CoreData
import SwiftUI

struct CloudKitManager {
    
    enum RecordType: String {
        case List, ListItem
        
        enum ListFileds: String {
            case id, title, dateAdded, systemImageColor, isAutoNumbering, isShowCheckedItem, isShowSublistCount, systemImage, children, share
        }
        enum ListItemFields: String {
            case id, title, dateAdded, parentList, parentListItem, index, isComplete, isEditing, isExpand, children, share
        }
    }
    
    private static let zoneName = "NeslisPrivateZone"
    private static let containerID = "iCloud.VSA.Neslis"
    static let recordZone = CKRecordZone(zoneName: zoneName)
    static let container = CKContainer(identifier: containerID)
    static let cloudKitPrivateDB = container.privateCloudDatabase
    static let cloudKitSharedDB = container.sharedCloudDatabase
    private static let context = CDStack.shared.container.viewContext
    
    struct Subscription {
        
        static private let subscriptionID = "sharedListChanged"
        static private let subscriptionSavedKey = "ckSubscriptionSaved"
        
        static func saveSubscription() {
            let alreadySaved = UserDefaults.standard.bool(forKey: subscriptionSavedKey)
            guard !alreadySaved else { return }
            let subscriptionSharedDatabase = CKDatabaseSubscription(subscriptionID: subscriptionID)
            let sharedInfo = CKSubscription.NotificationInfo()
            sharedInfo.shouldSendContentAvailable = true
            sharedInfo.alertBody = "Shared lists have changed"
            subscriptionSharedDatabase.notificationInfo = sharedInfo

            let subShared = CKModifySubscriptionsOperation(subscriptionsToSave: [subscriptionSharedDatabase], subscriptionIDsToDelete: nil)
            subShared.qualityOfService = .utility
            CloudKitManager.cloudKitSharedDB.add(subShared)
            
            UserDefaults.standard.set(true, forKey: self.subscriptionSavedKey)
        }
    }
    
    static func createZone(completion: @escaping (Error?) -> Void) {
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [recordZone], recordZoneIDsToDelete: [])
        operation.modifyRecordZonesCompletionBlock = { _, _, error in
            guard error == nil else {
                completion(error)
                return
            }
            completion(nil)
            print("Create zone successeful")
        }
        operation.qualityOfService = .userInitiated
        CloudKitManager.cloudKitPrivateDB.add(operation)
    }
    static func clearDB(completion: @escaping (Error?)->Void) {
        
        CloudKitManager.cloudKitPrivateDB.delete(withRecordZoneID: CloudKitManager.recordZone.zoneID) { (zoneID, zoneError) in
            
            if let deleteZoneError = zoneError {
                completion(deleteZoneError)
            } else {
                createZone { createError in
                    if let createZoneError = createError {
                        completion(createZoneError)
                    } else {
                        completion(nil)
                    }
                }
            }

        }
    }
    
    static func objectToCKRecord(object: NSManagedObject)->CKRecord? {
        
        switch object {
        case is ListCD:
            let list = object as! ListCD
            guard !list.share else {return nil}
            let recordID = CKRecord.ID(recordName: list.id!.uuidString, zoneID: recordZone.zoneID)
            let record = CKRecord(recordType: RecordType.List.rawValue, recordID: recordID)
            record[RecordType.ListFileds.id.rawValue] = list.id!.uuidString as CKRecordValue
            record[RecordType.ListFileds.title.rawValue] = list.title as  CKRecordValue
            record[RecordType.ListFileds.dateAdded.rawValue] = list.dateAdded as CKRecordValue
            record[RecordType.ListFileds.isAutoNumbering.rawValue] = list.isAutoNumbering as CKRecordValue
            record[RecordType.ListFileds.isShowCheckedItem.rawValue] = list.isShowCheckedItem as CKRecordValue
            record[RecordType.ListFileds.isShowSublistCount.rawValue] = list.isShowSublistCount as CKRecordValue
            record[RecordType.ListFileds.systemImage.rawValue] = list.systemImage as CKRecordValue
            record[RecordType.ListFileds.systemImageColor.rawValue] = list.systemImageColor as CKRecordValue
            record[RecordType.ListFileds.share.rawValue] = list.share as CKRecordValue
            
            if let children = list.children {
                if !children.array.isEmpty {
                    var tempArray = [String]()
                    children.forEach { list in
                        let tempListItem = list as! ListItemCD
                        tempArray.append(tempListItem.id!.uuidString)
                    }
                    record[RecordType.ListFileds.children.rawValue] = tempArray
                }
            }
            
            return record
            
        case is ListItemCD:
            let listItem = object as! ListItemCD
            guard !listItem.share else { return nil }
            let recordID = CKRecord.ID(recordName: listItem.id!.uuidString, zoneID: recordZone.zoneID)
            let record = CKRecord(recordType: RecordType.ListItem.rawValue, recordID: recordID)
            record[RecordType.ListItemFields.id.rawValue] = listItem.id!.uuidString as CKRecordValue
            record[RecordType.ListItemFields.dateAdded.rawValue] = listItem.dateAdded as CKRecordValue
            record[RecordType.ListItemFields.title.rawValue] = listItem.title as CKRecordValue
            
            if let parent = listItem.parentList {
                let refID = CKRecord.ID(recordName: parent.id!.uuidString, zoneID: recordZone.zoneID)
                let ref = CKRecord.Reference(recordID: refID, action: .deleteSelf)
                record[RecordType.ListItemFields.parentList.rawValue] = ref as CKRecordValue
                record.setParent(refID)
            }
            if let parent = listItem.parentListItem {
                let refID = CKRecord.ID(recordName: parent.id!.uuidString, zoneID: recordZone.zoneID)
                let ref = CKRecord.Reference(recordID: refID, action: .deleteSelf)
                record[RecordType.ListItemFields.parentListItem.rawValue] = ref as CKRecordValue
                record.setParent(refID)
            }
            
            record[RecordType.ListItemFields.index.rawValue] = listItem.index as CKRecordValue
            record[RecordType.ListItemFields.isComplete.rawValue] = listItem.isComplete as CKRecordValue
            record[RecordType.ListItemFields.isEditing.rawValue] = listItem.isEditing as CKRecordValue
            record[RecordType.ListItemFields.isExpand.rawValue] = listItem.isExpand as CKRecordValue
            record[RecordType.ListItemFields.share.rawValue] = listItem.share as CKRecordValue
            
            if let children = listItem.children {
                if !children.array.isEmpty {
                    var tempArray = [String]()
                    children.forEach { list in
                        let tempListItem = list as! ListItemCD
                        tempArray.append(tempListItem.id!.uuidString)
                    }
                    record[RecordType.ListFileds.children.rawValue] = tempArray
                }
            }
            
            return record
            
        default:
            return nil
        }
        
    }
    
    static func saveObjectsToCloud(insertedObjects: Set<NSManagedObject>, modifedObjects: Set<NSManagedObject>, deleteObjectsID: [CKRecord.ID], db: CKDatabase, completion: @escaping (Result<Int, Error>) -> Void) {
        
        var records = [CKRecord]()
        
        insertedObjects.forEach { object in
            if let record = objectToCKRecord(object: object) {
                records.append(record)
            }
        }
        modifedObjects.forEach { object in
            if let record = objectToCKRecord(object: object) {
                records.append(record)
            }
        }
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: deleteObjectsID)
        operation.savePolicy = .allKeys
        operation.isAtomic = false
        operation.configuration.timeoutIntervalForRequest = 10
        operation.configuration.timeoutIntervalForResource = 10
        operation.modifyRecordsCompletionBlock = { saveRecords, deleteRecordsID, error in
            if let localError = error {
                completion(.failure(localError))
            } else {
                completion(.success(insertedObjects.count + modifedObjects.count))
            }
        }
        db.add(operation)
    }
    
    static func saveAllObjectsToCloud(completion: @escaping (Error?)->Void) {
        
        let semaphore = DispatchSemaphore(value: 0)
        var flag = false
        let lists = CDStack.shared.fetchList(context: context)
        ProgressData.shared.allItesCount = CDStack.shared.fetchAmountAllItems(context: context)
        lists.forEach { object in
            saveObjectsToCloud(insertedObjects: [object], modifedObjects: [], deleteObjectsID: [], db: CloudKitManager.cloudKitPrivateDB) { result in
                switch result {
                case .success(let count):
                    print("Save \(count) listObject")
                    flag = true
                case .failure(let error):
                    print("Error listObject: \(error.localizedDescription)")
                    flag = false
                    completion(error)
                }
                semaphore.signal()
            }
            
            let list = object as! ListCD
            
            if flag {
                if let children = list.children {
                    if !children.array.isEmpty {
                        saveItem(children.array)
                    }
                }
            }

        }
        
        completion(nil)
    }
    
    fileprivate static func saveItem(_ array: [Any]) {
        let semaphore = DispatchSemaphore(value: 0)
        var arr = [NSManagedObject]()
        array.forEach { objectItem in
            arr.append(objectItem as! NSManagedObject)
        }
        let setToSave = Set(arr)
        CloudKitManager.saveObjectsToCloud(insertedObjects: setToSave, modifedObjects: [], deleteObjectsID: [], db: CloudKitManager.cloudKitPrivateDB) { result in
            switch result {
            case .success(let count):
                print("Save \(count) object")
                ProgressData.shared.counter += count
            case .failure(let error):
                print("Error save object: \(error.localizedDescription)")
                return
            }
            semaphore.signal()
        }
        semaphore.wait()

        array.forEach { objectItem in
            let item = objectItem as! ListItemCD
            if let children = item.children {
                if !children.array.isEmpty {
                    saveItem(children.array)
                }
            }
        }
    }
    static func fetchListCount(completion: @escaping (Result<Int, Error>) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: RecordType.List.rawValue, predicate: predicate)
        cloudKitPrivateDB.perform(query, inZoneWith: recordZone.zoneID) { (records, error) in
            if let performError = error {
                completion(.failure(performError))
            } else {
                completion(.success(records?.count ?? 0))
            }
        }
    }
    static func fetchListData(db: CKDatabase, completion: @escaping ([ListCD], Error?) -> Void) {
        var results = [ListCD]()
        var retError: Error?
        
        let predicate = NSPredicate(value: true)
        let sort = NSSortDescriptor(key: "dateAdded", ascending: true)
        let query = CKQuery(recordType: RecordType.List.rawValue, predicate: predicate)
        query.sortDescriptors = [sort]
        
        //countig listItem recors
        let queryItems = CKQuery(recordType: RecordType.ListItem.rawValue, predicate: predicate)
        db.perform(queryItems, inZoneWith: recordZone.zoneID) { (records, error) in
            print("records Items count: \(String(describing: records?.count))")
            if let recordsCount = records {
                ProgressData.shared.allItesCount = recordsCount.count
            }
            
        }
        
        db.perform(query, inZoneWith: recordZone.zoneID) { (records: [CKRecord]?, error: Error?) in
            if let error = error {
                print(#function, "fetch List error: \(error.localizedDescription)")
                retError = error
            } else {
                records?.forEach({ record in
                    let list = CDStack.shared.createListFromRecord(record: record, context: context)
                    
                    if db == container.privateCloudDatabase {
                        list.share = false
                    }
                    if db == container.sharedCloudDatabase {
                        list.share = true
                    }
                    
                    if let tempChildArray = record.object(forKey: RecordType.ListFileds.children.rawValue) as? [String] {
                        if !tempChildArray.isEmpty {
                            tempChildArray.forEach { id in
                                print("forEach fetchItem: \(id)")
                                fetchListItem(rootRecord: nil, db: db, id: id, parentList: list, parentListItem: nil) { (_, error) in
                                    if let localError = error {
                                        retError = localError
                                    }
                                }
                            }
                        }
                    }
                    
                    results.append(list)
                })
            }
            completion(results, retError)
        }
    }
    private static func fetchListItem(rootRecord: CKRecord?, db: CKDatabase, id: String, parentList: ListCD?, parentListItem: ListItemCD?, completion: @escaping (ListItemCD?, Error?) -> Void) {
        let semaphore = DispatchSemaphore(value: 0)
        var item: ListItemCD?
        var retError: Error?
        var recordID: CKRecord.ID!
        if db == cloudKitPrivateDB {
//            print("privateDB")
            recordID = CKRecord.ID(recordName: id, zoneID: recordZone.zoneID)
        } else {
//            print("sharedDB")
            guard let record = rootRecord else {return}
            recordID = CKRecord.ID(recordName: id, zoneID: record.recordID.zoneID)
        }
        
        db.fetch(withRecordID: recordID) { (record: CKRecord?, error: Error?) in
            if let localRecord = record {
                let listItem = ListItemCD(context: context)
                listItem.id = UUID(uuidString: localRecord.object(forKey: RecordType.ListItemFields.id.rawValue) as! String)
                listItem.title = localRecord.object(forKey: RecordType.ListItemFields.title.rawValue) as! String
                listItem.dateAdded = localRecord.object(forKey: RecordType.ListItemFields.dateAdded.rawValue) as! Date
                listItem.index = localRecord.object(forKey: RecordType.ListItemFields.index.rawValue) as! Int16
                listItem.isEditing = localRecord.object(forKey: RecordType.ListItemFields.isEditing.rawValue) as! Bool
                listItem.isExpand = localRecord.object(forKey: RecordType.ListItemFields.isExpand.rawValue) as! Bool
                listItem.isComplete = localRecord.object(forKey: RecordType.ListItemFields.isComplete.rawValue) as! Bool
                
                listItem.parentList = parentList
                listItem.parentListItem = parentListItem
                
                if let listParent = parentList {
                    listItem.share = listParent.share
                }
                if let listParent = parentListItem {
                    listItem.share = listParent.share
                }
                ProgressData.shared.counter += 1
                if let tempChildArray = localRecord.object(forKey: RecordType.ListItemFields.children.rawValue) as? [String] {
                    if !tempChildArray.isEmpty {
                        tempChildArray.forEach { id in
                            fetchListItem(rootRecord: rootRecord, db: db, id: id, parentList: nil, parentListItem: listItem) { (_, error) in
                                if let localError = error {
                                    retError = localError
                                }
                            }
                        }
                    }
                }
                
                item = listItem
            }
            if error != nil {
                print("fetch sublist1 error: \(error!.localizedDescription)")
            }
            retError = error
            semaphore.signal()
        }
        semaphore.wait()
        completion(item, retError)
    }
    
    static func fetchListRecordForSharing(id: String, completion: @escaping (CKRecord?, Error?) -> Void) {
        let recordID = CKRecord.ID(recordName: id, zoneID: recordZone.zoneID)
        cloudKitPrivateDB.fetch(withRecordID: recordID) { (record, error) in
            completion(record, error)
        }
    }
    static func fetchShare(_ metadata: CKShare.Metadata, completion: @escaping (CKRecord?, Error?)->Void) {
        let operation = CKFetchRecordsOperation(recordIDs: [metadata.rootRecordID])
        operation.perRecordCompletionBlock = { record, _, error in
            guard error == nil, record != nil else {
                print("perRecordCompletionBlock error: \(error!.localizedDescription)")
                return
            }
            //show data
            print("Share record: \(record!.description)")
            completion(record, error)
        }
        CloudKitManager.container.sharedCloudDatabase.add(operation)
    }
    
    static func shareRecordToObject(rootRecord: CKRecord, db: CKDatabase, completion: @escaping (ListCD, Error?)->Void) {
        print(#function)
        
        var retError: Error?
        let list = ListCD(context: context)
        list.id = UUID(uuidString: rootRecord.object(forKey: RecordType.ListFileds.id.rawValue) as! String)
        list.title = rootRecord.object(forKey: RecordType.ListFileds.title.rawValue) as! String
        list.dateAdded = rootRecord.object(forKey: RecordType.ListFileds.dateAdded.rawValue) as! Date
        list.systemImageColor = rootRecord.object(forKey: RecordType.ListFileds.systemImageColor.rawValue) as! Data
        list.systemImage = rootRecord.object(forKey: RecordType.ListFileds.systemImage.rawValue) as! String
        list.isShowSublistCount = rootRecord.object(forKey: RecordType.ListFileds.isShowSublistCount.rawValue) as! Bool
        list.isShowCheckedItem = rootRecord.object(forKey: RecordType.ListFileds.isShowCheckedItem.rawValue) as! Bool
        list.isAutoNumbering = rootRecord.object(forKey: RecordType.ListFileds.isAutoNumbering.rawValue) as! Bool
        //list.children = []
        list.share = true
        
        if let tempChildArray = rootRecord.object(forKey: RecordType.ListFileds.children.rawValue) as? [String] {
            if !tempChildArray.isEmpty {
                tempChildArray.forEach { id in
                    print("forEach fetchItem: \(id)")
                    fetchListItem(rootRecord: rootRecord, db: db, id: id, parentList: list, parentListItem: nil) { (_, error) in
                        if let localError = error {
                            retError = localError
                        }
                        
                    }
                }
            }
        }
        completion(list, retError)
    }
    
    static func checkIcloudStatus(completion: @escaping(CKAccountStatus?)->Void) {
        let container = CKContainer(identifier: containerID)
        let semaphore = DispatchSemaphore(value: 0)
        
        container.accountStatus { (accountStatus, error) in
            
            switch accountStatus {
            case .available:
                print("iCloud Available")
                //status = true
                
                //                container.requestApplicationPermission(.userDiscoverability) { (status: CKContainer_Application_PermissionStatus?, error: Error?) in
                //                    container.fetchUserRecordID { (fetchRecord: CKRecord.ID?, error: Error?) in
                //                        if let record = fetchRecord {
                //                            container.discoverUserIdentity(withUserRecordID: record, completionHandler: { (userID: CKUserIdentity?, error: Error?) in
                //                                if let user = userID {
                //                                    print(user.hasiCloudAccount)
                //                                    print(user.lookupInfo?.phoneNumber ?? "No phone number info")
                //                                    print(user.lookupInfo?.emailAddress ?? "No email address info")
                //                                    print((user.nameComponents?.givenName)! + " " + (user.nameComponents?.familyName)!)
                //                                } else {
                //                                    print(error?.localizedDescription ?? "")
                //                                }
                //                            })
                //                        } else {
                //                            retError = error
                //                            print(error?.localizedDescription ?? "")
                //                        }
                //                    }
                //                }
                
            case .noAccount:
                print("No iCloud account")
            case .restricted:
                print("iCloud restricted")
            case .couldNotDetermine:
                print("Unable to determine iCloud status")
            default:
                break
            }
            semaphore.signal()
            semaphore.wait()
            completion(accountStatus)
        }
        
        //completion(status, retError)
    }
    
    
}
