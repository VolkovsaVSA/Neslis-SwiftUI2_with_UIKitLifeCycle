//
//  Translation.swift
//  Neslis
//
//  Created by Sergey Volkov on 26.12.2020.
//

import Foundation

struct TxtLocal {
    struct Alert {
        struct Title {
            static let error = NSLocalizedString("Error", comment: " ")
            static let success = NSLocalizedString("Success", comment: " ")
            static let attention = NSLocalizedString("Attention!", comment: " ")
        }
        struct Text {
            static let touTurnedOffNotification = NSLocalizedString("You turned off the notification in settings. Please turn on the notifications for this application in the system settings.", comment: " ")
            static let fetchSharingData = NSLocalizedString("Fetching share data", comment: " ")
            static let errorLoading = NSLocalizedString("Error loading", comment: " ")
            static let toAcceptSharedLists = NSLocalizedString("To accept shared lists buy the Pro version.", comment: " ")
            static let backupDataIsSavedSuccessfully = NSLocalizedString("Backup data is saved successfully.", comment: " ")
            static let backupDataIsLoadedSuccessfully = NSLocalizedString("Backup data is loaded successfully.", comment: " ")
            static let pleaseCheckTheInternetConnection = NSLocalizedString("Please check the internet connection or re-authenticate in an iCloud account or try later.", comment: " ")
            static let restoring = NSLocalizedString("Restoring...", comment: " ")
            static let saving = NSLocalizedString("Saving...", comment: " ")
            static let fetchDataFromICloud = NSLocalizedString("Fetch data from iCloud", comment: " ")
            static let youAreHaveAnotherICloudData = NSLocalizedString("You have another iCloud data. Do you want to rewrite this data or merge all data?", comment: " ")
            static let youAreHaveDataOnYourPhone = NSLocalizedString("You have data on your phone. Do you want to rewrite this data or merge all data?", comment: " ")
            static let youAreHaveBackupData = NSLocalizedString("You have backup data! Do you want to load this data?", comment: " ")
            static let noBackupDataInICloud = NSLocalizedString("No backup data in iCloud.", comment: " ")
        }
    }
    struct Button {
        static let proVersion = NSLocalizedString("Pro Version", comment: " ")
        static let restorePurchases = NSLocalizedString("Restore purchases", comment: " ")
        static let saveData = NSLocalizedString("Save data", comment: " ")
        static let restoreData = NSLocalizedString("Restore data", comment: " ")
        static let save = NSLocalizedString("Save", comment: " ")
        static let load = NSLocalizedString("Load", comment: " ")
        static let ok = NSLocalizedString("OK", comment: " ")
        static let cancel = NSLocalizedString("Cancel", comment: " ")
        static let rewrite = NSLocalizedString("Rewrite", comment: " ")
        static let merge = NSLocalizedString("Merge", comment: " ")
    }
    struct Navigation {
        struct Title {
            static let lists = NSLocalizedString("Lists", comment: " ")
            static let settings = NSLocalizedString("Settings", comment: " ")
            static let listSettings = NSLocalizedString("List settings", comment: " ")
        }
    }
    struct Toggle {
        static let enableBackup = NSLocalizedString("Enable iCloud backups and shared lists", comment: " ")
        static let notificationsOfChanges = NSLocalizedString("Notifications of changes to shared lists", comment: " ")
        static let useTheColorOfTheList = NSLocalizedString("Use the color of the list-icon to visual style the list", comment: " ")
        static let showExpandAllButton = NSLocalizedString("Show 'expand all' button", comment: " ")
        static let autoNumbering = NSLocalizedString("Auto numbering", comment: " ")
        static let showCheckedItem = NSLocalizedString("Show checked item", comment: " ")
        static let showSublistCount = NSLocalizedString("Show sublist count", comment: " ")
    }
    struct TextField {
        static let newTask = NSLocalizedString("New task", comment: " ")
        static let newListTitle = NSLocalizedString("New list title", comment: " ")
        static let enterNewTask = NSLocalizedString("Enter new task", comment: " ")
    }
    struct Text {
        static let addNewList = NSLocalizedString("Add new list", comment: " ")
        static let purchases = NSLocalizedString("Purchases", comment: " ")
        static let iCloud = NSLocalizedString("iCloud", comment: " ")
        static let yourAreNotLogged = NSLocalizedString("You are not logged in iCloud, or not all permits granted! Please login to your iCloud account and check all permits in system settings for sharing lists and backup.", comment: " ")
        static let purchaseProVersionForBackup = NSLocalizedString("Purchase Pro version for backup and sharing lists.", comment: " ")
        static let visualSettings = NSLocalizedString("Visual settings", comment: " ")
        static let upgradeToPro = NSLocalizedString("Upgrade to Pro", comment: " ")
        static let dataBackup = NSLocalizedString("Data backup", comment: " ")
        static let sharingLists = NSLocalizedString("Sharing lists", comment: " ")
        static let inMonth = NSLocalizedString("/ month", comment: " ")
        static let inYear = NSLocalizedString("/ year", comment: " ")
        static let yourSave = NSLocalizedString("Your save", comment: " ")
        static let recurringBilling = NSLocalizedString("Recurring billing. Cancel any time. If you choose to purchase a subscription, payment will be charged to your iTunes account and your account will be charged for renewal 24 hours prior to the end of the current period unless auto-renew is turned off. Auto-renewal is managed by the user and may be turned off at any time by going to your settings in the iTunes Store after purchase. Any unused portion of a free trial period will be forfeited when the user purchases a subscription.", comment: " ")
    }
    struct contentBody {
        static let sharedList = NSLocalizedString("Shared list", comment: " ")
        static let hasBeenChanged = NSLocalizedString("has been changed", comment: " ")
        static let completed = NSLocalizedString("completed", comment: " ")
    }
}
