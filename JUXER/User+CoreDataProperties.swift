//
//  User+CoreDataProperties.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 21/03/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension User {

    @NSManaged var name: String?
    @NSManaged var anonymous: NSNumber?

}
