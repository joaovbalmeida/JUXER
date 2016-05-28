//
//  Session+CoreDataProperties.swift
//  Juxer
//
//  Created by Joao Victor Almeida on 05/04/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import Foundation
import CoreData

extension Session {

    @NSManaged var active: NSNumber?
    @NSManaged var token: String?
    @NSManaged var id: NSNumber?

}
