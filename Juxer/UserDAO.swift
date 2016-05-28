//
//  UserDAO.swift
//  Juxer
//
//  Created by Joao Victor Almeida on 03/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import Foundation
import CoreData

class UserDAO {
    
    // insert new object
    static func insert(user: User) {
        DatabaseManager.sharedInstance.managedObjectContext.insertObject(user)
        
        do {
            try DatabaseManager.sharedInstance.managedObjectContext.save()
        } catch let error as NSError {
            print("Erro ao inserir tarefas", error)
        }
        
    }
    
    // update existing object
    static func update(user: User) {
        do {
            try DatabaseManager.sharedInstance.managedObjectContext.save()
        } catch let error as NSError {
            print("Erro ao alterar tarefa ", error)
        }
        
    }
    
    // delete object
    static func delete(user: User) {
        DatabaseManager.sharedInstance.managedObjectContext.deleteObject(user)
        do {
            try DatabaseManager.sharedInstance.managedObjectContext.save()
        } catch let error as NSError {
            print("Erro ao deletar tarefa", error)
        }
        
        
    }
    
    // fetch existing object
    static func fetchUser() -> [User] {
        
        let request = NSFetchRequest(entityName: "User")
        
        var result = [User]()
        
        do {
            result = try DatabaseManager.sharedInstance.managedObjectContext.executeFetchRequest(request) as! [User]
        } catch let error as NSError {
            print("Erro ao buscar tarefas", error)
        }
        
        return result
    }
    
    
}