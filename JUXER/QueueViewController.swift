//
//  QueueViewController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 25/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit

class QueueViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBAction func unwindToVC(segue: UIStoryboardSegue) {
    }
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsSelection = false
        
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "HomeBackground.png")!)
        
        let bar: UINavigationBar =  self.navigationController!.navigationBar
        bar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        bar.shadowImage = UIImage()
        bar.alpha = 0.0
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0:
            return 1
        case 1:
            return 3
        default:
            return 0
        }
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch (indexPath.section) {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("playing", forIndexPath: indexPath)
            self.tableView.rowHeight = 170
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            return cell
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("queue", forIndexPath: indexPath)
            self.tableView.rowHeight = 70
            return cell
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier("queue", forIndexPath: indexPath)
            return cell
        }
    }

}
