//
//  User.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 30/03/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
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
