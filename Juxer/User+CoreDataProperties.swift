//
//  User+CoreDataProperties.swift
//  Juxer
//
//  Created by Joao Victor Almeida on 30/04/16.
//

import Foundation
import CoreData

extension User {

    @NSManaged var anonymous: NSNumber?
    @NSManaged var email: String?
    @NSManaged var firstName: String?
    @NSManaged var id: String?
    @NSManaged var lastName: String?
    @NSManaged var name: String?
    @NSManaged var pictureUrl: String?

}
