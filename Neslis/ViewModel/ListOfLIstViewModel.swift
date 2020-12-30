//
//  ListOfLIstViewModel.swift
//  Neslis
//
//  Created by Sergey Volkov on 27.12.2020.
//

import Foundation
import SwiftUI
import CoreData

class ListOfListViewModel: ObservableObject {
    
    @Published var lists: [ListCD]
    
    init() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ListCD")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ListCD.dateAdded, ascending: true)]
        
        do {
            self.lists = try CDStack.shared.container.viewContext.fetch(request) as! [ListCD]
        } catch {
            self.lists = []
            print("Failed to fetch lists: \(error)")
        }

    }
}
