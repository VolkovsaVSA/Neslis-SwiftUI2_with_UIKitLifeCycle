//
//  SceneDelegate.swift
//  Neslis
//
//  Created by Sergey Volkov on 22.07.2020.
//  Copyright © 2020 Sergei Volkov. All rights reserved.
//

import UIKit
import SwiftUI
import CloudKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    //var loading = Loadspinner()
    var progressData = ProgressData.shared
    var settings = UserSettings.shared
    let coreData = CDStack.shared
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        let contentView = ListOfListsView(userSettings: settings, progressData: progressData)
            .environment(\.managedObjectContext, coreData.container.viewContext)
        
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        
        // Save changes in the application's managed object context when the application transitions to the background.
        coreData.saveContext(context: coreData.container.viewContext)
    }
    
    
    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        
        //cloudKitShareMetadata.
        ProgressData.shared.setZero()
        let acceptSharesOperation = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])
        acceptSharesOperation.qualityOfService = .userInteractive
        
        acceptSharesOperation.acceptSharesCompletionBlock = { error in
            if error != nil {
                print("error acceptSharesCompletionBlock: \(error!.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.progressData.activitySpinnerText = "Fetch sharing data"
                    self.progressData.activitySpinnerAnimate = true
                }
                CloudKitManager.Sharing.fetchShare(cloudKitShareMetadata) { (rc, er) in
                    if let error = er {
                        //print("shareRecordToObject error:\(error.localizedDescription)")
                        DispatchQueue.main.async {
                            self.progressData.activitySpinnerAnimate = false
                            self.progressData.finishMessage = error.localizedDescription
                            self.progressData.finishButtonShow = true
                        }
                        
                    }
                    guard let shareRecord = rc else {
                        DispatchQueue.main.async {
                            self.progressData.activitySpinnerAnimate = false
                            self.progressData.finishMessage = "Error loading"
                            self.progressData.finishButtonShow = true
                        }
                        return
                    }
                    
                    //CloudKitManager.rootRecord = shareRecord
                    
                    CloudKitManager.Sharing.shareRecordToObject(rootRecord: shareRecord, db: CloudKitManager.cloudKitSharedDB) { (_, error) in
                        if let localError = error {
                            print("shareRecordToObject error:\(localError.localizedDescription)")
                            DispatchQueue.main.async {
                                self.progressData.finishMessage = localError.localizedDescription
                                self.progressData.finishButtonShow = true
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.coreData.saveContext(context: self.coreData.container.viewContext)
                            }
                        }
                        DispatchQueue.main.async {
                            self.progressData.activitySpinnerAnimate = false
                        }
                    }

                    CloudKitManager.Subscription.setSubscription(db: CloudKitManager.cloudKitSharedDB, subscriptionID: CloudKitManager.Subscription.sharedDbSubsID, subscriptionSavedKey: CloudKitManager.Subscription.sharedDbSubsSavedKey)
                    
                    CloudKitManager.Subscription.setSubscription(db: CloudKitManager.cloudKitPrivateDB, subscriptionID: CloudKitManager.Subscription.privateDbSubsID, subscriptionSavedKey: CloudKitManager.Subscription.privateDbSubsSavedKey)
                }
            }
        }
        
        
        CKContainer(identifier: cloudKitShareMetadata.containerIdentifier)
            .add(acceptSharesOperation)
    }
    
    
    
}



