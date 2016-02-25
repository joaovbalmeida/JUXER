//
//  TabBarController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 24/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {

    @IBInspectable var defaultIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedIndex = defaultIndex
    }
}
