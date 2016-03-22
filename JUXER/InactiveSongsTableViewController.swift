//
//  InactiveSongsTableViewController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 21/03/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit

class InactiveSongsTableViewController: UITableViewController {

    var playlists = [String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playlists = ["oi", "tchau","cell","cell2","cell3","cel34"]
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return playlists.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("songs", forIndexPath: indexPath)
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.init(red: 29/255, green: 33/255, blue: 36/255, alpha: 1)
        cell.selectedBackgroundView = bgColorView
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero
        
        
        return cell
    }
    
}
