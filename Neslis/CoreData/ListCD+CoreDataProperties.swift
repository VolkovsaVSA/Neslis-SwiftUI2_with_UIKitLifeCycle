//
//  ListCD+CoreDataProperties.swift
//  Neslis
//
//  Created by Sergey Volkov on 11.10.2020.
//
//

import Foundation
import CoreData


extension ListCD: ListSharedProperties {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ListCD> {
        return NSFetchRequest<ListCD>(entityName: "ListCD")
    }

    @NSManaged public var dateAdded: Date
    @NSManaged public var id: UUID?
    @NSManaged public var title: String
    @NSManaged public var isAutoNumbering: Bool
    @NSManaged public var isShowCheckedItem: Bool
    @NSManaged public var isShowSublistCount: Bool
    @NSManaged public var isShare: Bool
    @NSManaged public var systemImage: String
    @NSManaged public var systemImageColor: Data
    @NSManaged public var children: NSOrderedSet?
    @NSManaged public var childrenUpdate: Bool
    @NSManaged public var shareRecrodZoneID: CKRecordZone.ID?
    @NSManaged public var shareRootRecrodID: CKRecord.ID?

}

// MARK: Generated accessors for children
extension ListCD {

    @objc(insertObject:inChildrenAtIndex:)
    @NSManaged public func insertIntoChildren(_ value: ListItemCD, at idx: Int)

    @objc(removeObjectFromChildrenAtIndex:)
    @NSManaged public func removeFromChildren(at idx: Int)

    @objc(insertChildren:atIndexes:)
    @NSManaged public func insertIntoChildren(_ values: [ListItemCD], at indexes: NSIndexSet)

    @objc(removeChildrenAtIndexes:)
    @NSManaged public func removeFromChildren(at indexes: NSIndexSet)

    @objc(replaceObjectInChildrenAtIndex:withObject:)
    @NSManaged public func replaceChildren(at idx: Int, with value: ListItemCD)

    @objc(replaceChildrenAtIndexes:withChildren:)
    @NSManaged public func replaceChildren(at indexes: NSIndexSet, with values: [ListItemCD])

    @objc(addChildrenObject:)
    @NSManaged public func addToChildren(_ value: ListItemCD)

    @objc(removeChildrenObject:)
    @NSManaged public func removeFromChildren(_ value: ListItemCD)

    @objc(addChildren:)
    @NSManaged public func addToChildren(_ values: NSOrderedSet)

    @objc(removeChildren:)
    @NSManaged public func removeFromChildren(_ values: NSOrderedSet)

}

extension ListCD : Identifiable {
    public var childrenArray: [ListItemCD]?  {
        guard let arr = children?.array as? [ListItemCD] else { return nil }
        if childrenUpdate {
            setIndex()
        }
        let retArr = arr.isEmpty ? nil : arr
        return retArr
    }
    public func setIndex() {
        guard let arr = children?.array as? [ListItemCD] else { return }
        var index = 1
        arr.forEach { item in
            item.index = Int16(index)
            index += 1
        }
        childrenUpdate = false
        CDStack.shared.saveContext(context: CDStack.shared.container.viewContext)
    }
}
