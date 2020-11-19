//
//  Persistence.swift
//  Neslis
//
//  Created by Sergey Volkov on 10.10.2020.
//

import CoreData

struct CDStack {
    static let shared = CDStack()
    
    let container: NSPersistentContainer
    
    var context: NSManagedObjectContext {
        return container.viewContext
    }
    
    private init() {
        container = NSPersistentContainer(name: "Neslis")
        container.loadPersistentStores(completionHandler: { [self] (storeDescription, error) in
            if let error = error as NSError? {
                print(error.localizedDescription)
            }
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            container.viewContext.automaticallyMergesChangesFromParent = true
        })
    }
      
    func saveContext() {
        DispatchQueue.main.async {
            if self.context.hasChanges {

                let insertedObjects = self.context.insertedObjects
                let modifiedObjects = self.context.updatedObjects
                let deletedRecordIDs = self.context.deletedObjects

                var deleteRecordsID = [CKRecord.ID]()
                deletedRecordIDs.forEach { object in
                    let id = object.value(forKey: "id") as! UUID
                    let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: CloudKitManager.recordZone.zoneID)
                    deleteRecordsID.append(recordID)
                }

                do {

                    if UserDefaults.standard.bool(forKey: UDKeys.Settings.icloudBackup) {
                        print("icloudBackup")
                        CloudKitManager.saveObjectsToCloud(insertedObjects: insertedObjects, modifedObjects: modifiedObjects, deleteObjectsID: deleteRecordsID, db: CloudKitManager.cloudKitPrivateDB) { result in
                            switch result {
                            case .success(let count):
                                print("Save \(count) objects to icloudBackup")
                            case .failure(let error):
                                print("Error icloudBackup  \(error.localizedDescription)")
                            }
                        }
                    }

                    try self.context.save()
                    
                } catch {
                    self.context.rollback()
                    let error = error as Error
                    print(error.localizedDescription)
                }

            }
        }

    }
    
//    func saveContext() {
//        do {
//            try self.context.save()
//        } catch {
//            print("ERROR SAVE CD: \(error.localizedDescription)")
//        }
//
//    }
    
    func deleteObject(object: NSManagedObject) {
        context.delete(object)
    }
    
    
    func isCompleteCheck(isComplete: Bool) -> String {
        return isComplete ? "checkmark.circle.fill" : "circle"
    }
    
    func isCompleteItem(listItem: ListItemCD) {
        listItem.isComplete.toggle()
        isCompleteChildItem(listItem: listItem)
        saveContext()
    }
    private func isCompleteChildItem(listItem: ListItemCD) {
        if let arr = listItem.childrenArray {
            for (_, value) in arr.enumerated() {
                let tempValue = value
                tempValue.isComplete = listItem.isComplete
                isCompleteChildItem(listItem: tempValue)
            }
        } 
    }
    
    func createList(title: String, systemImage: String, systemImageColor: Data, isAutoNumbering: Bool, isShowCheckedItem: Bool, isShowSublistCount: Bool, share: Bool) {
        let newList = ListCD(context: context)
        newList.dateAdded = Date()
        newList.id = UUID()
        newList.isAutoNumbering = isAutoNumbering
        newList.isShowCheckedItem = isShowCheckedItem
        newList.isShowSublistCount = isShowSublistCount
        newList.children = []
        newList.childrenUpdate = false
        newList.systemImage = systemImage
        newList.systemImageColor = systemImageColor
        newList.title = title
        newList.share = share
    }
    
    func createListItem(title: String, parentList: ListCD?, parentListItem: ListItemCD?, share: Bool) {
        let newListItem = ListItemCD(context: context)
        newListItem.id = UUID()
        newListItem.dateAdded = Date()
        newListItem.title = title
        newListItem.parentList = parentList
        newListItem.parentListItem = parentListItem
        newListItem.index = 0
        newListItem.isComplete = false
        newListItem.isEditing = false
        newListItem.isExpand = true
        newListItem.share = share
        newListItem.childrenUpdate = false
    }
    
    func createListFromRecord(record: CKRecord)->ListCD {
        let list = ListCD(context: context)
        list.id = UUID(uuidString: record.object(forKey: CloudKitManager.RecordType.ListFileds.id.rawValue) as! String)
        list.title = record.object(forKey: CloudKitManager.RecordType.ListFileds.title.rawValue) as! String
        list.dateAdded = record.object(forKey: CloudKitManager.RecordType.ListFileds.dateAdded.rawValue) as! Date
        list.systemImageColor = record.object(forKey: CloudKitManager.RecordType.ListFileds.systemImageColor.rawValue) as! Data
        list.systemImage = record.object(forKey: CloudKitManager.RecordType.ListFileds.systemImage.rawValue) as! String
        list.isShowSublistCount = record.object(forKey: CloudKitManager.RecordType.ListFileds.isShowSublistCount.rawValue) as! Bool
        list.isShowCheckedItem = record.object(forKey: CloudKitManager.RecordType.ListFileds.isShowCheckedItem.rawValue) as! Bool
        list.isAutoNumbering = record.object(forKey: CloudKitManager.RecordType.ListFileds.isAutoNumbering.rawValue) as! Bool
        list.children = []
        return list
    }
    
    func nonCompleteCount(list: [ListItemCD]) -> Int {
        return list.count - list.filter { $0.isComplete == false }.count
    }
    func prepareArrayListItem(array: [ListItemCD], list: ListCD) -> [ListItemCD] {
        let filteredArray = array.filter {
            list.isShowCheckedItem ? true : $0.isComplete == list.isShowCheckedItem
        }
        return filteredArray
    }
    
    
    func fetchList()->[NSManagedObject] {
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "ListCD")
        var lists = [NSManagedObject]()
        do {
            lists = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return lists
    }
    
    func fetchOneObject(entityName: String, id: String)->NSManagedObject? {
        
        let filter = UUID(uuidString: id)
        let predicate = NSPredicate(format: "id == %@", filter! as CVarArg)
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.predicate = predicate
        
        do {
            let objects = try context.fetch(request) as! [NSManagedObject]
            
            if objects.isEmpty {
                return nil
            } else {
                return objects.first
            }
            
        } catch {
            print("Could not fetch one object. \(error.localizedDescription)")
            return nil
        }
        
    }
    
    func convertRecordTypeToCDEntity(recordType: String)->String? {
        var entity: String?
        
        switch recordType {
        case CloudKitManager.RecordType.List.rawValue:
            entity = ListCD.description()
        case CloudKitManager.RecordType.ListItem.rawValue:
            entity = ListItemCD.description()
        default:
            break
        }
        
        return entity
    }
    
    func saveChangeRecord(record: CKRecord) {
        print("record.recordType: \(record.recordType)")
        print("recordID: \(record.recordID)")
        
        guard let id = record.object(forKey: CloudKitManager.RecordType.ListFileds.id.rawValue) as? String else {return}
        guard let convertedRecordType = convertRecordTypeToCDEntity(recordType: record.recordType) else {return}
        
        var object = CDStack.shared.fetchOneObject(entityName: convertedRecordType, id: id)
        print("object: \(String(describing: object?.description))")
        
        func saveListItemData(listItem: inout ListItemCD, record: CKRecord) {
            listItem.title = record.object(forKey: CloudKitManager.RecordType.ListItemFields.title.rawValue) as! String
            listItem.index = record.object(forKey: CloudKitManager.RecordType.ListItemFields.index.rawValue) as! Int16
            listItem.isComplete = record.object(forKey: CloudKitManager.RecordType.ListItemFields.isComplete.rawValue) as! Bool
            listItem.isEditing = record.object(forKey: CloudKitManager.RecordType.ListItemFields.isEditing.rawValue) as! Bool
            listItem.isExpand = record.object(forKey: CloudKitManager.RecordType.ListItemFields.isExpand.rawValue) as! Bool
        }
        func saveEditedData(object: inout NSManagedObject, record: CKRecord) {
            
            switch object {
            case is ListCD:
                let list = object as! ListCD
                list.title = record.object(forKey: CloudKitManager.RecordType.ListFileds.title.rawValue) as! String
                list.systemImageColor = record.object(forKey: CloudKitManager.RecordType.ListFileds.systemImageColor.rawValue) as! Data
                list.systemImage = record.object(forKey: CloudKitManager.RecordType.ListFileds.systemImage.rawValue) as! String
                list.isShowSublistCount = record.object(forKey: CloudKitManager.RecordType.ListFileds.isShowSublistCount.rawValue) as! Bool
                list.isShowCheckedItem = record.object(forKey: CloudKitManager.RecordType.ListFileds.isShowCheckedItem.rawValue) as! Bool
                list.isAutoNumbering = record.object(forKey: CloudKitManager.RecordType.ListFileds.isAutoNumbering.rawValue) as! Bool
                
                if let tempChilds = record.object(forKey: CloudKitManager.RecordType.ListFileds.children.rawValue) as? [String] {
                    if !tempChilds.isEmpty {
                        var childs = [ListItemCD]()
                        tempChilds.forEach { childId in
                            let child = CDStack.shared.fetchOneObject(entityName: ListItemCD.description(), id: childId) as! ListItemCD
                            childs.append(child)
                        }
                        let childsSet = NSOrderedSet(array: childs)
                        list.children = childsSet
                    }
                }
                
            case is ListItemCD:
                var listItem = object as! ListItemCD
                saveListItemData(listItem: &listItem, record: record)
                
                if let tempChilds = record.object(forKey: CloudKitManager.RecordType.ListItemFields.children.rawValue) as? [String] {
                    if !tempChilds.isEmpty {
                        var childs = [ListItemCD]()
                        tempChilds.forEach { childId in
                            let child = CDStack.shared.fetchOneObject(entityName: ListItemCD.description(), id: childId) as! ListItemCD
                            childs.append(child)
                        }
                        let childsSet = NSOrderedSet(array: childs)
                        listItem.children = childsSet
                    }
                }
                
            default:
                break
            }
        }

        if object != nil {
            saveEditedData(object: &object!, record: record)
        } else {
            
            switch convertedRecordType {
            case ListCD.description():
                let list = createListFromRecord(record: record)
                list.share = true
            case ListItemCD.description():
                
                let listItem = ListItemCD(context: context)
                listItem.id = UUID(uuidString: record.object(forKey: CloudKitManager.RecordType.ListItemFields.id.rawValue) as! String)
                listItem.dateAdded = record.object(forKey: CloudKitManager.RecordType.ListItemFields.dateAdded.rawValue) as! Date
                listItem.title = record.object(forKey: CloudKitManager.RecordType.ListItemFields.title.rawValue) as! String
                listItem.index = record.object(forKey: CloudKitManager.RecordType.ListItemFields.index.rawValue) as! Int16
                listItem.isEditing = record.object(forKey: CloudKitManager.RecordType.ListItemFields.isEditing.rawValue) as! Bool
                listItem.isExpand = record.object(forKey: CloudKitManager.RecordType.ListItemFields.isExpand.rawValue) as! Bool
                listItem.isComplete = record.object(forKey: CloudKitManager.RecordType.ListItemFields.isComplete.rawValue) as! Bool
                
                print("record.parent!.recordID: \(record.parent!.recordID)")
                print("record.parent.recordReferance: \(String(describing: record.object(forKey: "parent")?.description))")
                
//                CloudKitManager.cloudKitSharedDB.fetch(withRecordID: record.parent!.recordID) { (parentRecord, error) in
//
//                }
//
//
//                listItem.parent = parent
//                listItem.share = parent.share
                
                
                
            default:
                break
            }
        }
        
        
        //CDStack.shared.saveContext()
    }
}
