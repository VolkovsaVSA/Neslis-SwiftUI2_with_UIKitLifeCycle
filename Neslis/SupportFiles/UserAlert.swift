//
//  UserAlert.swift
//  Neslis
//
//  Created by Sergey Volkov on 14.11.2020.
//

import SwiftUI

class UserAlert: ObservableObject {

    static let shared = UserAlert()
    
    var title = ""
    var text = ""
    @Published var show = false
}
