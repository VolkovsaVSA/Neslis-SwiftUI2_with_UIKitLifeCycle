//
//  111.swift
//  Neslis
//
//  Created by Sergey Volkov on 06.12.2020.
//

import Foundation
import CoreData

//public protocol ValueTransforming: NSSecureCoding {
//  static var valueTransformerName: NSValueTransformerName { get }
//}
//
//public class NSSecureCodingValueTransformer<T: NSObject & ValueTransforming>: ValueTransformer {
//  public override class func transformedValueClass() -> AnyClass { T.self }
//  public override class func allowsReverseTransformation() -> Bool { true }
//
//  public override func transformedValue(_ value: Any?) -> Any? {
//    guard let value = value as? T else { return nil }
//    return try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true)
//  }
//
//  public override func reverseTransformedValue(_ value: Any?) -> Any? {
//    guard let data = value as? NSData else { return nil }
//    let result = try? NSKeyedUnarchiver.unarchivedObject(
//      ofClass: T.self,
//      from: data as Data
//    )
//    return result
//  }
//
//  /// Registers the transformer by calling `ValueTransformer.setValueTransformer(_:forName:)`.
//  public static func registerTransformer() {
//    let transformer = NSSecureCodingValueTransformer<T>()
//    ValueTransformer.setValueTransformer(transformer, forName: T.valueTransformerName)
//  }
//}
//
//extension NSObject: ValueTransforming {
//    
//    public static var valueTransformerName: NSValueTransformerName { .init("NSObject") }
//}


//public protocol ValueTransforming: NSSecureCoding {
//  static var valueTransformerName: NSValueTransformerName { get }
//}
//
//public class NSSecureCodingValueTransformer<T: NSSecureCoding & NSObject>: ValueTransformer {
//  public override class func transformedValueClass() -> AnyClass { T.self }
//  public override class func allowsReverseTransformation() -> Bool { true }
//
//  public override func transformedValue(_ value: Any?) -> Any? {
//    guard let value = value as? T else { return nil }
//    return try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true)
//  }
//
//  public override func reverseTransformedValue(_ value: Any?) -> Any? {
//    guard let data = value as? NSData else { return nil }
//    let result = try? NSKeyedUnarchiver.unarchivedObject(
//      ofClass: T.self,
//      from: data as Data
//    )
//    return result
//  }
//
//  /// Registers the transformer by calling `ValueTransformer.setValueTransformer(_:forName:)`.
//  public static func registerTransformer() {
//    let transformer = NSSecureCodingValueTransformer<T>()
//    ValueTransformer.setValueTransformer(transformer, forName: T.valueTransformerName)
//  }
//}

//@objc(NSObject)
//class NSObjectTransformer: NSSecureUnarchiveFromDataTransformer {
//        override class var allowedTopLevelClasses: [AnyClass] {
//                return super.allowedTopLevelClasses + [NSObject.self]
//        }
//}


//@objc(NSObject)
//final class NSObjectTransformer: NSSecureUnarchiveFromDataTransformer {
//
//    /// The name of the transformer. This is the name used to register the transformer using `ValueTransformer.setValueTrandformer(_"forName:)`.
//    static let name = NSValueTransformerName(rawValue: String(describing: NSObjectTransformer.self))
//
//    // 2. Make sure `NSObject` is in the allowed class list.
//    override static var allowedTopLevelClasses: [AnyClass] {
//        return [NSObject.self]
//    }
//
//    /// Registers the transformer.
//    public static func register() {
//        let transformer = NSObjectTransformer()
//        ValueTransformer.setValueTransformer(transformer, forName: name)
//    }
//}

