//
//  CloudSharingButton.swift
//  Neslis
//
//  Created by Sergey Volkov on 01.11.2020.
//

import Foundation
import SwiftUI
import CloudKit


struct CloudSharingButton: UIViewRepresentable {
    
    @ObservedObject var toShare: ListCD
    @State var recordToShare: CKRecord?
    
    enum CloudError: Error {
        case controllerInvalidated, missingNoteRecord
    }
    
    func makeUIView(context: UIViewRepresentableContext<CloudSharingButton>) -> UIButton {
        let button = UIButton()
        
        button.setImage(UIImage(systemName: "person.crop.circle.badge.plus"), for: .normal)
        button.addTarget(context.coordinator, action: #selector(context.coordinator.pressed(_:)), for: .touchUpInside)
        
        context.coordinator.shareRecord = recordToShare
        context.coordinator.button = button
        
        return button
    }
    
    func updateUIView(_ uiView: UIButton, context: UIViewRepresentableContext<CloudSharingButton>) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        var button: UIButton?
        var shareRecord: CKRecord?
        
        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            
            CloudKitManager.Subscription.setSubscription(db: CloudKitManager.cloudKitPrivateDB, subscriptionID: CloudKitManager.Subscription.privateDbSubsID, subscriptionSavedKey: CloudKitManager.Subscription.privateDbSubsSavedKey)
            
            if let shareID = csc.share?.recordID {
                parent.toShare.shareRootRecrodID = shareID
            }
            
            print("cloudSharingControllerDidSaveShare")
        }
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("failedToSaveShareWithError")
        }
        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            print("cloudSharingControllerDidStopSharing")
            
        }
        func itemTitle(for csc: UICloudSharingController) -> String? {
            return parent.toShare.title
        }
        
        var parent: CloudSharingButton
        init(_ parent: CloudSharingButton) {
            self.parent = parent
        }
        
        @objc func pressed(_ sender: UIButton) {
            
            guard let record = self.shareRecord else { print(#function, #line); return }
            
            if let shareReference = record.share {
                //print("record.share: \(shareReference)")
                CloudKitManager.cloudKitPrivateDB.fetch(withRecordID: shareReference.recordID) { (record, error) in
                    //print("record: \(record?.description)")
                    guard let shareRecord = record as? CKShare else { //print(error?.localizedDescription);
                        return }
                    DispatchQueue.main.async {
                        let controller = UICloudSharingController(share: shareRecord, container: CloudKitManager.container)
                        controller.delegate = self
                        controller.availablePermissions = [.allowPrivate, .allowReadWrite]
                        controller.definesPresentationContext = true
                        UIApplication.shared.windows.first?.rootViewController?.present(controller, animated: true)
                    }
                }
            } else {
                print("no share")
                let share = CKShare(rootRecord: record)
                share[CKShare.SystemFieldKey.title] = (record.object(forKey: "title") as! String) as CKRecordValue
                share.publicPermission = .readWrite
                
                let controller = UICloudSharingController { controller, completion in
                    
                    let operationQueue = OperationQueue()
                    operationQueue.maxConcurrentOperationCount = 1
                    
                    let operation = CKModifyRecordsOperation(recordsToSave: [record, share], recordIDsToDelete: [])
                    operation.modifyRecordsCompletionBlock = { saved, _, error in
                        if let error = error {
                            return completion(nil, nil, error)
                        }
                        completion(share, CloudKitManager.container, nil)
                    }
                    
                    operation.savePolicy = .changedKeys
                    operation.database = CloudKitManager.cloudKitPrivateDB
                    operationQueue.addOperation(operation)
                }
                controller.delegate = self
                controller.availablePermissions = [.allowPrivate, .allowReadWrite]
                controller.definesPresentationContext = true
                UIApplication.shared.windows.first?.rootViewController?.present(controller, animated: true)
            }
            
        }
    }
}
