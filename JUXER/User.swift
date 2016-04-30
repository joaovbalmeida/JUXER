//
//  User.swift
//  
//
//  Created by Joao Victor Almeida on 30/04/16.
//
//

import Foundation
import CoreData


class User: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    convenience init() {
        let context: NSManagedObjectContext = DatabaseManager.sharedInstance.managedObjectContext
        
        let entityDescription: NSEntityDescription? = NSEntityDescription.entityForName("User", inManagedObjectContext: context)
        
        self.init(entity: entityDescription!, insertIntoManagedObjectContext: context)
    }
}
