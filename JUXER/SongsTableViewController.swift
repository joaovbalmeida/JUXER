//
//  SongsTableViewController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 07/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit

class SongsTableViewController: UITableViewController {
    
    struct trackData {
        var Name: String
        var Artist: String
    }
    
    var tracks: [trackData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        
        self.clearsSelectionOnViewWillAppear = true
        self.getTracks()
    }
    
    func getTracks(){
        let url = NSURL(string: "http://198.211.98.86/api/track/playlist/9/")
        let session = NSURLSession.sharedSession()
        let request = NSURLRequest(URL: url!)
        let dataTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            
            if error != nil {
                print(error)
            }
            else {
                print(data)
            }
            
        })
        dataTask.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return tracks.count
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
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
