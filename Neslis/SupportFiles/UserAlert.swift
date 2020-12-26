//
//  UserAlert.swift
//  Neslis
//
//  Created by Sergey Volkov on 14.11.2020.
//

import SwiftUI

class UserAlert: ObservableObject {

    static let shared = UserAlert()
    
    var title: LocalizedStringKey = ""
    var text: LocalizedStringKey = ""
    @Published var show = false
    @Published var alertType: AlertType?
}

enum AlertType: Identifiable {
    case saveRewrite, loadRewrite, networkError, oldIcloudData, noIcloudData, noAccessToNotification
    var id: Int {
        hashValue
    }
}
