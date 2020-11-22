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
    
    var loading = Loadspinner()
    var settings = UserSettings.shared
    let coreData = CDStack.shared
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        let contentView = ListOfListsView(userSettings: settings, loading: loading)
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
        
        let acceptSharesOperation = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])
        acceptSharesOperation.qualityOfService = .userInteractive
        
        acceptSharesOperation.acceptSharesCompletionBlock = { error in
            if error != nil {
                print("error acceptSharesCompletionBlock: \(error!.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.loading.animateSpinner = true
                }
                CloudKitManager.fetchShare(cloudKitShareMetadata) { (rc, er) in
                    if let error = er {
                        print("shareRecordToObject error:\(error.localizedDescription)")
                        DispatchQueue.main.async {
                            self.loading.animateSpinner = false
                            self.loading.message = error.localizedDescription
                            self.loading.showMessage = true
                        }
                        
                    }
                    guard let shareRecord = rc else {
                        DispatchQueue.main.async {
                            self.loading.animateSpinner = false
                            self.loading.message = "Error loading"
                            self.loading.showMessage = true
                        }
                        return
                    }
                    
                    CloudKitManager.shareRecordToObject(rootRecord: shareRecord, db: CloudKitManager.cloudKitSharedDB) { (_, error) in
                        if let localError = error {
                            print("shareRecordToObject :\(localError.localizedDescription)")
                            DispatchQueue.main.async {
                                self.loading.message = localError.localizedDescription
                                self.loading.showMessage = true
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.coreData.saveContext(context: self.coreData.container.viewContext)
                            }
                        }
                        DispatchQueue.main.async {
                            self.loading.message = ""
                            self.loading.animateSpinner = false
                        }
                    }

                    CloudKitManager.Subscription.saveSubscription()
                }
            }
        }
        
        
        CKContainer(identifier: cloudKitShareMetadata.containerIdentifier)
            .add(acceptSharesOperation)
    }
    
    
    
}



