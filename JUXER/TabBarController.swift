//
//  TabBarController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 24/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit
import CoreData

class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let session = SessionDAO.fetchSession()
        
        if session.count > 0 && session[0].active == 1 {
            selectedIndex = 1
        } else {
            selectedIndex = 0
        }
    }
}
