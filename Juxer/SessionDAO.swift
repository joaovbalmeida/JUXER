//
//  SessionDAO.swift
//  Jjuxer
//
//  Created by Joao Victor Almeida on 12/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import Foundation
import CoreData

class SessionDAO {
    
    // insert new object
    static func insert(session: Session) {
        DatabaseManager.sharedInstance.managedObjectContext.insertObject(session)
        
        do {
            try DatabaseManager.sharedInstance.managedObjectContext.save()
        } catch let error as NSError {
            print("Erro ao inserir tarefas", error)
        }
        
    }
    
    // update existing object
    static func update(session: Session) {
        do {
            try DatabaseManager.sharedInstance.managedObjectContext.save()
        } catch let error as NSError {
            print("Erro ao alterar tarefa ", error)
        }
        
    }
    
    // delete object
    static func delete(session: Session) {
        DatabaseManager.sharedInstance.managedObjectContext.deleteObject(session)
        do {
            try DatabaseManager.sharedInstance.managedObjectContext.save()
        } catch let error as NSError {
            print("Erro ao deletar tarefa", error)
        }
    }
    
    // fetch existing object
    static func fetchSession() -> [Session] {
        
        let request = NSFetchRequest(entityName: "Session")
        
        var result = [Session]()
        
        do {
            result = try DatabaseManager.sharedInstance.managedObjectContext.executeFetchRequest(request) as! [Session]
        } catch let error as NSError {
            print("Erro ao buscar tarefas", error)
        }
        
        return result
    }
    
}