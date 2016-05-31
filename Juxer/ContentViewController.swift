//
//  ContentViewController.swift
//  Juxer
//
//  Created by Joao Victor Almeida on 28/04/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit

class ContentViewController: UIViewController {

    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var contentIcon: UIImageView!
    
    var pageIndex: Int!
    var pageLabel: String!
    var pageIcon: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.contentLabel.text = self.pageLabel
        self.contentIcon.image = UIImage(named: self.pageIcon)
    }
    
}

// Extension for localizing strings set programmatically
extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: "", comment: "")
    }
}