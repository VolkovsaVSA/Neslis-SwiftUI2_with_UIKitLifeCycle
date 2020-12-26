//
//  Translation.swift
//  Neslis
//
//  Created by Sergey Volkov on 26.12.2020.
//

import SwiftUI
import Foundation

struct TxtLocal {
    struct Alert {
        struct Title {
            static let error: LocalizedStringKey = "Error"
            static let success: LocalizedStringKey = "Success"
            static let attention: LocalizedStringKey = "Attention!"
        }
        struct Text {
            static let touTurnedOffNotification: LocalizedStringKey = "You turned off notification in settings. Please turn on the notifications for this application in the system settings."
            static let fetchSharingData: LocalizedStringKey = "Fetch sharing data"
            static let errorLoading: LocalizedStringKey = "Error loading"
            static let toAcceptSharedLists: LocalizedStringKey = "To accept shared lists buy the Pro version."
            static let backupDataIsSavedSuccessfully: LocalizedStringKey = "Backup data is saved successfully."
            static let backupDataIsLoadedSuccessfully: LocalizedStringKey = "Backup data is loaded successfully."
            static let pleaseCheckTheInternetConnection: LocalizedStringKey = "Please check the internet connection or re-authenticate in an iCloud account or try later."
            static let restoring: LocalizedStringKey = "Restoring..."
            static let saving: LocalizedStringKey = "Saving..."
            static let fetchDataFromICloud: LocalizedStringKey = "Fetch data from iCloud"
            static let youAreHaveAnotherICloudData: LocalizedStringKey = "You are have another iCloud data. Do you want rewreite this data or joined all data?"
            static let youAreHaveDataOnYourPhone: LocalizedStringKey = "You are have data on your phone. Do you want rewreite this data or joined all data?"
            static let youAreHaveBackupData: LocalizedStringKey = "You are have backup data! Do you want to load this data?"
            static let noBackupDataInICloud: LocalizedStringKey = "No backup data in iCloud."
        }
    }
    struct Button {
        static let proVersion: LocalizedStringKey = "Pro Version"
        static let restorePurchases: LocalizedStringKey = "Restore purchases"
        static let saveData: LocalizedStringKey = "Save data"
        static let restoreData: LocalizedStringKey = "Restore data"
        static let save: LocalizedStringKey = "Save"
        static let load: LocalizedStringKey = "Load"
        static let ok: LocalizedStringKey = "OK"
        static let cancel: LocalizedStringKey = "Cancel"
        static let rewrite: LocalizedStringKey = "Rewrite"
        static let joined: LocalizedStringKey = "Joined"
    }
    struct Navigation {
        struct Title {
            static let lists: LocalizedStringKey = "Lists"
            static let settings: LocalizedStringKey = "Settings"
            static let listSettings: LocalizedStringKey = "List settings"
        }
    }
    struct Toggle {
        static let enableBackup: LocalizedStringKey = "Enable backup to iCloud and sharing lists"
        static let notificationsOfChanges: LocalizedStringKey = "Notifications of changes to shared lists"
        static let useTheColorOfTheList: LocalizedStringKey = "Use the color of the list-icon to visual style the list"
        static let showExpandAllButton: LocalizedStringKey = "Show 'expand all' button"
        static let autoNumbering: LocalizedStringKey = "Auto numbering"
        static let showCheckedItem: LocalizedStringKey = "Show checked item"
        static let showSublistCount: LocalizedStringKey = "Show sublist count"
    }
    struct TextField {
        static let newTask: LocalizedStringKey = "New task"
        static let newListTitle: LocalizedStringKey = "New list title"
        static let enterNewTask: LocalizedStringKey = "Enter new task"
    }
    struct Text {
        static let addNewList: LocalizedStringKey = "Add new list"
        static let purchases: LocalizedStringKey = "Purchases"
        static let iCloud: LocalizedStringKey = "iCloud"
        static let yourAreNotLogged: LocalizedStringKey = "You are not logged in iCloud, or not all permits granted! Please login to your iCloud account and check all permits in system settings for sharing lists and backup."
        static let purchaseProVersionForBackup: LocalizedStringKey = "Purchase Pro version for backup and sharing lists."
        static let visualSettings: LocalizedStringKey = "Visual settings"
        static let upgradeToPro: LocalizedStringKey = "Upgrade to Pro"
        static let dataBackup: LocalizedStringKey = "Data backup"
        static let sharingLists: LocalizedStringKey = "Sharing lists"
        static let inMonth = "/ month"
        static let inYear = "/ year"
        static let yourSave = "Your save"
        static let recurringBilling: LocalizedStringKey = """
                Recurring billing. Cancel any time.
                If you choose to purchase a subscription, payment will be charged to your iTunes account and your account will be charged fo renewal 24 yours prior to the end of the current period unless auto-renew is turned off. Auto-renewal is managed by user and may be turned off at any time by going to your settings in the iTunes Store after purchase. Any unused portion of a free trial period will be forfeited when the user purchases a subscription.
                """
    }
    struct contentBody {
        static let sharedList: LocalizedStringKey = "Shared list"
        static let hasBeenChanged: LocalizedStringKey = "has been changed"
    }
}
