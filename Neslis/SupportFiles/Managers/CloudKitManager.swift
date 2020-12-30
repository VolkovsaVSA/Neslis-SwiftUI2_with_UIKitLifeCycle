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
    
    //static var rootRecord: CKRecord?
    
    enum RecordType: String {
        case List, ListItem
        
        enum ListFileds: String {
            case id, title, dateAdded, systemImageColor, isAutoNumbering, isShowCheckedItem, isShowSublistCount, systemImage, children/*, share, ownerName*/
        }
        enum ListItemFields: String {
            case id, title, dateAdded, parentList, parentListItem, index, isComplete, isEditing, isExpand, children/*, share, ownerName*/
        }
    }
    
    static let zoneName = "NeslisPrivateZone"
    private static let containerID = "iCloud.VSA.Neslis"
    static let recordZone = CKRecordZone(zoneName: zoneName)
    static let container = CKContainer(identifier: containerID)
    static let cloudKitPrivateDB = container.privateCloudDatabase
    static let cloudKitSharedDB = container.sharedCloudDatabase
    private static let context = CDStack.shared.container.viewContext
    
    struct Subscription {
        
        static let sharedDbSubsID = "sharedDbSubsID"
        static let sharedDbSubsSavedKey = "sharedDbSubsSavedKey"
        static let privateDbSubsID = "privateDbSubsID"
        static let privateDbSubsSavedKey = "privateDbSubsSavedKey"
        
        static func setSubscription(db: CKDatabase, subscriptionID: String, subscriptionSavedKey: String) {
            let alreadySaved = UserDefaults.standard.bool(forKey: subscriptionSavedKey)
            guard !alreadySaved else { return }
            let subscriptionDatabase = CKDatabaseSubscription(subscriptionID: subscriptionID)
            let sharedInfo = CKSubscription.NotificationInfo()
            sharedInfo.shouldSendContentAvailable = true
//            sharedInfo.alertBody = "Shared lists has been changed"
//            sharedInfo.soundName = "default"
            subscriptionDatabase.notificationInfo = sharedInfo

            let subShared = CKModifySubscriptionsOperation(subscriptionsToSave: [subscriptionDatabase], subscriptionIDsToDelete: nil)
            subShared.qualityOfService = .userInitiated
            db.add(subShared)
            
            UserDefaults.standard.set(true, forKey: subscriptionSavedKey)
        }
        
        static func deleteRecordZoneSubscription(db:  CKDatabase, subscriptionID: [String]) {
            let subShared = CKModifySubscriptionsOperation(subscriptionsToSave: nil, subscriptionIDsToDelete: subscriptionID)
            subShared.qualityOfService = .userInitiated
            db.add(subShared)
        }

        
    }
    
    struct Zone {
        
        static func createZone(completion: @escaping (Error?) -> Void) {
            
            if !UserSettings.shared.zonIsCreated {
                let operation = CKModifyRecordZonesOperation(recordZonesToSave: [recordZone], recordZoneIDsToDelete: [])
                operation.modifyRecordZonesCompletionBlock = { _, _, error in
                    guard error == nil else {
                        completion(error)
                        return
                    }
                    completion(nil)
                    DispatchQueue.main.async {
                        UserSettings.shared.zonIsCreated = true
                    }
                    
                    print("Create zone successeful")
                }
                operation.qualityOfService = .userInitiated
                cloudKitPrivateDB.add(operation)
            }
            
        }
        static func deleteZone(completion: @escaping (Error?)->Void) {
            
            cloudKitPrivateDB.delete(withRecordZoneID: recordZone.zoneID) { (zoneID, zoneError) in
                
                if let deleteZoneError = zoneError {
                    completion(deleteZoneError)
                } else {
                    DispatchQueue.main.async {
                        UserSettings.shared.zonIsCreated = false
                    }
                    
                    createZone { createError in
                        completion(createError)
                    }
                }

            }
        }
    }
    
    struct SaveToCloud {
        
        static func objectToCKRecord(object: NSManagedObject)->CKRecord? {
            
            switch object {
            case is ListCD:
                let list = object as! ListCD
                var recordID: CKRecord.ID!
                
                if list.isShare {
                    guard let sharedRecrodZoneID = list.shareRecrodZoneID else { print(#function, " guard let sharedRecrodZoneID"); return nil }
                    recordID = CKRecord.ID(recordName: list.id!.uuidString, zoneID: sharedRecrodZoneID)
                } else {
                    recordID = CKRecord.ID(recordName: list.id!.uuidString, zoneID: recordZone.zoneID)
                }
                
                guard let recordID2 = recordID  else { return nil }
                
                let record = CKRecord(recordType: RecordType.List.rawValue, recordID: recordID2)
                record[RecordType.ListFileds.id.rawValue] = list.id!.uuidString as CKRecordValue
                record[RecordType.ListFileds.title.rawValue] = list.title as  CKRecordValue
                record[RecordType.ListFileds.dateAdded.rawValue] = list.dateAdded as CKRecordValue
                record[RecordType.ListFileds.isAutoNumbering.rawValue] = list.isAutoNumbering as CKRecordValue
                record[RecordType.ListFileds.isShowCheckedItem.rawValue] = list.isShowCheckedItem as CKRecordValue
                record[RecordType.ListFileds.isShowSublistCount.rawValue] = list.isShowSublistCount as CKRecordValue
                record[RecordType.ListFileds.systemImage.rawValue] = list.systemImage as CKRecordValue
                record[RecordType.ListFileds.systemImageColor.rawValue] = list.systemImageColor as CKRecordValue

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
                var recordID: CKRecord.ID!
                
                if listItem.isShare {
                    guard let sharedRecrodZoneID = listItem.shareRecrodZoneID else { print(#function, " guard let sharedRecrodZoneID");return nil }
                    recordID = CKRecord.ID(recordName: listItem.id!.uuidString, zoneID: sharedRecrodZoneID)
                } else {
                    recordID = CKRecord.ID(recordName: listItem.id!.uuidString, zoneID: recordZone.zoneID)
                }
                
                let record = CKRecord(recordType: RecordType.ListItem.rawValue, recordID: recordID)
                record[RecordType.ListItemFields.id.rawValue] = listItem.id!.uuidString as CKRecordValue
                record[RecordType.ListItemFields.dateAdded.rawValue] = listItem.dateAdded as CKRecordValue
                record[RecordType.ListItemFields.title.rawValue] = listItem.title as CKRecordValue

                if let parent = listItem.parentList {
                    var refID: CKRecord.ID!
                    if listItem.isShare {
                        guard let sharedRecrodZoneID = listItem.shareRecrodZoneID else {print(#function, " guard let sharedRecrodZoneID"); return nil }
                        refID = CKRecord.ID(recordName: parent.id!.uuidString, zoneID: sharedRecrodZoneID)
                    } else {
                        refID = CKRecord.ID(recordName: parent.id!.uuidString, zoneID: recordZone.zoneID)
                    }
                    let ref = CKRecord.Reference(recordID: refID, action: .deleteSelf)
                    record[RecordType.ListItemFields.parentList.rawValue] = ref as CKRecordValue
                    record.setParent(refID)
                }
                if let parent = listItem.parentListItem {
                    var refID: CKRecord.ID!
                    if listItem.isShare {
                        guard let sharedRecrodZoneID = listItem.shareRecrodZoneID else {print(#function, " guard let sharedRecrodZoneID"); return nil }
                        refID = CKRecord.ID(recordName: parent.id!.uuidString, zoneID: sharedRecrodZoneID)
                    } else {
                        refID = CKRecord.ID(recordName: parent.id!.uuidString, zoneID: recordZone.zoneID)
                    }
                    let ref = CKRecord.Reference(recordID: refID, action: .deleteSelf)
                    record[RecordType.ListItemFields.parentListItem.rawValue] = ref as CKRecordValue
                    record.setParent(refID)
                }

                record[RecordType.ListItemFields.index.rawValue] = listItem.index as CKRecordValue
                record[RecordType.ListItemFields.isComplete.rawValue] = listItem.isComplete as CKRecordValue
                record[RecordType.ListItemFields.isEditing.rawValue] = listItem.isEditing as CKRecordValue
                record[RecordType.ListItemFields.isExpand.rawValue] = listItem.isExpand as CKRecordValue

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
        
        static func saveObjectsToCloud2(objects: CDStack.SortedObjects, completion: @escaping (Result<Int, Error>) -> Void) {
            
            func createOperations(recordsToSave: [CKRecord], recordIDsToDelete: [CKRecord.ID], db: CKDatabase) {
                let operation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
                operation.savePolicy = .allKeys
                operation.isAtomic = true
                operation.configuration.timeoutIntervalForRequest = 20
                operation.configuration.timeoutIntervalForResource = 20
                operation.modifyRecordsCompletionBlock = { saveRecords, deleteRecordsID, error in
                    if let localError = error {
                        print(#function, db)
                        print("error operation: \(localError.localizedDescription)")
                        completion(.failure(localError))
                    } else {
                        completion(.success(saveRecords!.count))
                    }
                }
                operation.perRecordCompletionBlock = { record, error in
                    if let er = error {
                        print(#function)
                        print("perRecordCompletionBlock: \(er.localizedDescription)")
                        //print(record.description)
                    }
                    //print(record.description)
                }
                db.add(operation)
            }
            
            var privateRecords = [CKRecord]()
            var shareRecords = [CKRecord]()

            
            objects.privateModifedObjects.forEach { object in
                if let record = objectToCKRecord(object: object) {
                    privateRecords.append(record)
                }
            }
            objects.sharedModifedObjects.forEach { object in
                if let record = objectToCKRecord(object: object) {
                    shareRecords.append(record)
                }
            }
            
            createOperations(recordsToSave: privateRecords, recordIDsToDelete: objects.privateDeleteRecordsID, db: cloudKitPrivateDB)
            createOperations(recordsToSave: shareRecords, recordIDsToDelete: objects.sharedDeleteRecordsID, db: cloudKitSharedDB)
            
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
            operation.isAtomic = true
            operation.configuration.timeoutIntervalForRequest = 20
            operation.configuration.timeoutIntervalForResource = 20
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
            ProgressData.shared.allItemsCount = CDStack.shared.fetchAmountAllItems(context: context)
            lists.forEach { object in
                
                saveObjectsToCloud(insertedObjects: [object], modifedObjects: [], deleteObjectsID: [], db: cloudKitPrivateDB) { result in
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
                
                semaphore.wait()
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
            saveObjectsToCloud(insertedObjects: setToSave, modifedObjects: [], deleteObjectsID: [], db: cloudKitPrivateDB) { result in
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
    }
    
    struct FetchFromCloud {
        
        
        static func fetchListCountFromPrivateDB(completion: @escaping (Result<Int, Error>) -> Void) {
            let predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: RecordType.List.rawValue, predicate: predicate)
            
            CloudKitManager.Zone.createZone { error in
                if let zoneErreor = error {
                    completion(.failure(zoneErreor))
                } else {
                    cloudKitPrivateDB.perform(query, inZoneWith: recordZone.zoneID) { (records, error) in
                        if let performError = error {
                            completion(.failure(performError))
                        } else {
                            completion(.success(records?.count ?? 0))
                        }
                    }
                }
            }
            
            
        }
        static func fetchListDataFromPrivateDB(db: CKDatabase, completion: @escaping ([ListCD], Error?) -> Void) {
            var results = [ListCD]()
            var retError: Error?
            
            let predicate = NSPredicate(value: true)
            let sort = NSSortDescriptor(key: "dateAdded", ascending: true)
            let query = CKQuery(recordType: RecordType.List.rawValue, predicate: predicate)
            query.sortDescriptors = [sort]
            
            //countig listItem recors
            let queryItems = CKQuery(recordType: RecordType.ListItem.rawValue, predicate: predicate)
            cloudKitPrivateDB.perform(queryItems, inZoneWith: recordZone.zoneID) { (records, error) in
                //print("records Items count: \(String(describing: records?.count))")
                if let recordsCount = records {
                    ProgressData.shared.allItemsCount = recordsCount.count
                }
                
            }
            
            cloudKitPrivateDB.perform(query, inZoneWith: recordZone.zoneID) { (records: [CKRecord]?, error: Error?) in
                if let error = error {
                    print(#function, "fetch List error: \(error.localizedDescription)")
                    retError = error
                } else {
                    records?.forEach({ record in
                        let list = CDStack.shared.createListFromRecord(record: record, context: context)
                        list.isShare = false
                        
                        
                        if let tempChildArray = record.object(forKey: RecordType.ListFileds.children.rawValue) as? [String] {
                            if !tempChildArray.isEmpty {
                                tempChildArray.forEach { id in
                                    //print("forEach fetchItem: \(id)")
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
        static func fetchListItem(rootRecord: CKRecord?, db: CKDatabase, id: String, parentList: ListCD?, parentListItem: ListItemCD?, completion: @escaping (ListItemCD?, Error?) -> Void) {
            let semaphore = DispatchSemaphore(value: 0)
            var item: ListItemCD?
            var retError: Error?
            var recordID: CKRecord.ID!
            
            if db == cloudKitPrivateDB {
                recordID = CKRecord.ID(recordName: id, zoneID: recordZone.zoneID)
            } else {
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
                    listItem.shareRecrodZoneID = rootRecord?.recordID.zoneID
                    
                    if let listParent = parentList {
                        listItem.isShare = listParent.isShare
                    }
                    if let listItemParent = parentListItem {
                        listItem.isShare = listItemParent.isShare
                    }
                    //count progress of fetching
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
    }
    
    struct Sharing {
        
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
                    print("fetchShare error: \(error!.localizedDescription)")
                    return
                }
                
                completion(record, error)
            }
            cloudKitSharedDB.add(operation)
        }
        static func shareRecordToObject(rootRecord: CKRecord, db: CKDatabase, completion: @escaping (ListCD, Error?)->Void) {
            
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
            list.isShare = true
            list.shareRecrodZoneID = rootRecord.recordID.zoneID
            
            if let tempChildArray = rootRecord.object(forKey: RecordType.ListFileds.children.rawValue) as? [String] {
                if !tempChildArray.isEmpty {
                    ProgressData.shared.allItemsCount = tempChildArray.count
                    tempChildArray.forEach { id in
                        print("forEach fetchItem: \(id)")
                        ProgressData.shared.counter += 1
                        FetchFromCloud.fetchListItem(rootRecord: rootRecord, db: db, id: id, parentList: list, parentListItem: nil) { (_, error) in
                            if let localError = error {
                                retError = localError
                            }
                            
                        }
                    }
                }
            }
            completion(list, retError)
        }
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
