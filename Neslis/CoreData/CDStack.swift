//
//  Persistence.swift
//  Neslis
//
//  Created by Sergey Volkov on 10.10.2020.
//

import CoreData

struct CDStack {
    static let shared = CDStack()
    
    struct SortedObjects {
        var privateModifedObjects = [NSManagedObject]()
        var privateDeleteRecordsID = [CKRecord.ID]()
        var sharedModifedObjects = [NSManagedObject]()
        var sharedDeleteRecordsID = [CKRecord.ID]()
    }
    
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Neslis")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("CDError: \(error.localizedDescription)")
            }
        })
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func deleteAllLists(context: NSManagedObjectContext) {
        let lists = fetchList(context: context)
        lists.forEach { list in
            context.delete(list)
        }
        saveContext(context: context)
    }
    
    private func sortObjectsToDB()->SortedObjects {
        
        let insertedModifiedObjects = container.viewContext.insertedObjects.union(container.viewContext.updatedObjects)
        let deletedOblects = container.viewContext.deletedObjects
        
        var sortObject = SortedObjects()

        insertedModifiedObjects.forEach { object in
            guard let cdEntity = object as? ListSharedProperties else {return}
            if cdEntity.isShare {
                sortObject.sharedModifedObjects.append(object)
            } else {
                sortObject.privateModifedObjects.append(object)
            }
        }
        deletedOblects.forEach { object in
            guard let cdEntity = object as? ListSharedProperties else {return}
            if cdEntity.isShare {
                guard let id = object.value(forKey: "id") as? UUID else {return}
                guard let rootRecordZoneID = cdEntity.shareRecrodZoneID else {return}
                let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: rootRecordZoneID)
                sortObject.sharedDeleteRecordsID.append(recordID)
            } else {
                guard let id = object.value(forKey: "id") as? UUID else {return}
                let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: CloudKitManager.recordZone.zoneID)
                
                sortObject.privateDeleteRecordsID.append(recordID)
                
                if let list = object as? ListCD {
                    print("delete shareded list")
                    if let shareRecordID = list.shareRootRecrodID {
                        print("shareRecordID: \(shareRecordID.description)")
                        sortObject.privateDeleteRecordsID.append(shareRecordID)
                        
                        CloudKitManager.cloudKitPrivateDB.fetch(withRecordID: shareRecordID) { (record, error) in
                            if let shareRecord = record as? CKShare {
                                shareRecord.participants.forEach { participant in
                                    shareRecord.removeParticipant(participant)
                                }
                            }
                        }
                        
                    }
                }
            }
        }
//        print("shared sortObject: \(sortObject.sharedModifedObjects.description)")
        return sortObject
    }
    
    func saveContext(context: NSManagedObjectContext) {
        DispatchQueue.main.async {
            if context.hasChanges {
                
                let sortedObj = sortObjectsToDB()
                
                do {
                    
                    if UserDefaults.standard.bool(forKey: UDKeys.Settings.icloudBackup) {
                        
                        CloudKitManager.SaveToCloud.saveObjectsToCloud2(objects: sortedObj) { result in
                            switch result {
                            case .success(let count):
                                print("Save \(count) objects to icloudBackup")
                            case .failure(let error):
                                print("Error iCloudBackup \(error.localizedDescription)")
                            }
                        }
                        
                    }
                    
                    try context.save()
                } catch {
                    context.rollback()
                    print(error.localizedDescription)
                }
                
            }
        }

        

    }
    
    func isCompleteCheck(isComplete: Bool) -> String {
        return isComplete ? "checkmark.circle.fill" : "circle"
    }
    
    func isCompleteItem( listItem: ListItemCD, context: NSManagedObjectContext) {
        listItem.isComplete.toggle()
        isCompleteChildItem(listItem: listItem)
//        saveContext(context: context)
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
    
    func createList(title: String, systemImage: String, systemImageColor: Data, isAutoNumbering: Bool, isShowCheckedItem: Bool, isShowSublistCount: Bool, share: Bool, context: NSManagedObjectContext) {
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
        newList.isShare = share
    }
    
    func createListItem(title: String, parentList: ListCD?, parentListItem: ListItemCD?, share: Bool, context: NSManagedObjectContext) {

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
        newListItem.isShare = share
        newListItem.childrenUpdate = false
        
        if let parent = parentList {
            newListItem.shareRecrodZoneID = parent.shareRecrodZoneID
        }
        if let parent = parentListItem {
            newListItem.shareRecrodZoneID = parent.shareRecrodZoneID
        }
    }
    
    func createListFromRecord(record: CKRecord, context: NSManagedObjectContext)->ListCD {
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
    
    
    func fetchList(context: NSManagedObjectContext)->[NSManagedObject] {
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "ListCD")
        var lists = [NSManagedObject]()
        do {
            lists = try context.fetch(fetchRequest)
        } catch let error {
            print(error.localizedDescription)
        }
        return lists
    }
    func fetchAmountAllItems(context: NSManagedObjectContext)->Int {
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "ListItemCD")
        var items = [NSManagedObject]()
        do {
            items = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return items.count
    }
    
    func fetchOneObject(entityName: String, id: String, context: NSManagedObjectContext)->NSManagedObject? {
        
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
    
    func saveChangeRecord(record: CKRecord, context: NSManagedObjectContext) {
        guard let id = record.object(forKey: CloudKitManager.RecordType.ListFileds.id.rawValue) as? String else {return}
        guard let convertedRecordType = convertRecordTypeToCDEntity(recordType: record.recordType) else {return}
        var object = CDStack.shared.fetchOneObject(entityName: convertedRecordType, id: id, context: context)

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
//                list.isShare = true
//                list.shareRecrodZoneID = record.recordID.zoneID
                
                if let tempChilds = record.object(forKey: CloudKitManager.RecordType.ListFileds.children.rawValue) as? [String] {
                    if !tempChilds.isEmpty {
                        var childs = [ListItemCD]()
                        tempChilds.forEach { childId in
                            if let child = CDStack.shared.fetchOneObject(entityName: ListItemCD.description(), id: childId, context: context) as? ListItemCD {
                                childs.append(child)
                            }
                            
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
                            guard let child = CDStack.shared.fetchOneObject(entityName: ListItemCD.description(), id: childId, context: context) as? ListItemCD else {return}
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
            print("object nil")
            switch convertedRecordType {
            case ListCD.description():
                let list = createListFromRecord(record: record, context: context)
                list.isShare = true
                list.shareRecrodZoneID = record.recordID.zoneID
            case ListItemCD.description():
                let listItem = ListItemCD(context: context)
                listItem.id = UUID(uuidString: record.object(forKey: CloudKitManager.RecordType.ListItemFields.id.rawValue) as! String)
                listItem.dateAdded = record.object(forKey: CloudKitManager.RecordType.ListItemFields.dateAdded.rawValue) as! Date
                listItem.title = record.object(forKey: CloudKitManager.RecordType.ListItemFields.title.rawValue) as! String
                listItem.index = record.object(forKey: CloudKitManager.RecordType.ListItemFields.index.rawValue) as! Int16
                listItem.isEditing = record.object(forKey: CloudKitManager.RecordType.ListItemFields.isEditing.rawValue) as! Bool
                listItem.isExpand = record.object(forKey: CloudKitManager.RecordType.ListItemFields.isExpand.rawValue) as! Bool
                listItem.isComplete = record.object(forKey: CloudKitManager.RecordType.ListItemFields.isComplete.rawValue) as! Bool
                listItem.isShare = true
                listItem.shareRecrodZoneID = record.recordID.zoneID
                
            default:
                break
            }
        }
        
        
        //CDStack.shared.saveContext(context: context)
    }
}
