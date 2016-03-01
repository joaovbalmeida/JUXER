//
//  PlaylistsTableViewController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 07/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit

class PlaylistsTableViewController: UITableViewController {

    
    
    var playlists = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playlists = ["oi", "tchau","cell","cell2","cell3","cel34"]

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
       
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0:
            return 1
        case 1:
            return playlists.count
        default:
            return 1
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        switch (indexPath.section) {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("actives", forIndexPath: indexPath)
            let bgColorView = UIView()
            bgColorView.backgroundColor = UIColor.init(red: 43/255, green: 50/255, blue: 54/255, alpha: 1)
            cell.selectedBackgroundView = bgColorView
            return cell
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("inactives", forIndexPath: indexPath)
            return cell
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier("inactives", forIndexPath: indexPath)
            return cell
        }

    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var label: String = ""
        
        switch (section) {
        case 0:
            label = "Listas Ativas"
            return label
            
        case 1:
            label = "Listas Inativas"
            return label
            
        default:
            label = ""
            return label
        }
    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
