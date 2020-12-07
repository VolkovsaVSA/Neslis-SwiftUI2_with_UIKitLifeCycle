//
//  ListSharedProperties.swift
//  Neslis
//
//  Created by Sergey Volkov on 01.12.2020.
//

import Foundation
import CloudKit

protocol ListSharedProperties {
    var isShare: Bool { get set }
    var shareRecrodZoneID: CKRecordZone.ID? { get set }
}
