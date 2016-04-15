//
//  PlaylistsTableViewController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 07/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit

class PlaylistsTableViewController: UITableViewController {
    
    private var playlists = [Playlist]()
    private var session = [Session]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        session = SessionDAO.fetchSession()
        getPlaylists()

    }
    
    private struct Playlist {
        var name: String
        var schedule: String
        var cover: String
        
        init (name: String, schedule: String, cover: String){
            self.name = "Title"
            self.schedule = "Schedule"
            self.cover = ""
        }
    }

    private func getPlaylists(){
        
        //Erase previous Data
        if self.playlists.count != 0 {
            playlists.removeAll()
        }
        
        let url = NSURL(string: "http://198.211.98.86/api/track/playlist/\(session[0].id!)/?sorted=1")
        let request = NSMutableURLRequest(URL: url!)
        
        request.HTTPMethod = "GET"
        request.setValue("JWT \(session[0].token!)", forHTTPHeaderField: "Authorization")
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            if error != nil {
                print(error)
                return
            } else {
                do {
                    let resultJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
                    let JSON = resultJSON as! [String:AnyObject]
                    
                    //Create playlists struct array from JSON
                    for item in JSON {
                        print(item.0)
                        var newPlaylist = Playlist(name: "name", schedule: "schedule", cover: "")
                        newPlaylist.name = item.0
                        //newPlaylist.schedule = item.1.valueForKeyPath("")
                        //newPlaylist.cover =
                        self.playlists.append(newPlaylist)
                    }
                    
                    //Refresh TableView
                    dispatch_async(dispatch_get_main_queue()){
                        self.tableView.reloadData()
                    }
                    
                } catch let error as NSError {
                    print(error)
                }
            }
        }
        task.resume()
    }
 
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return playlists.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell: PlaylistsTableViewCell = tableView.dequeueReusableCellWithIdentifier("actives", forIndexPath: indexPath) as! PlaylistsTableViewCell
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.init(red: 29/255, green: 33/255, blue: 36/255, alpha: 1)
        cell.selectedBackgroundView = bgColorView
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero
        
        cell.playlistName.text = playlists[indexPath.row].name
        
        return cell
        
        /*
        switch (indexPath.section) {
        case 0:
            let cell: PlaylistsTableViewCell = tableView.dequeueReusableCellWithIdentifier("actives", forIndexPath: indexPath)
            let bgColorView = UIView() as! PlaylistsTableViewCell
            bgColorView.backgroundColor = UIColor.init(red: 29/255, green: 33/255, blue: 36/255, alpha: 1)
            cell.selectedBackgroundView = bgColorView
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            return cell
            
        case 1:
            let cell: PlaylistsTableViewCell = tableView.dequeueReusableCellWithIdentifier("inactives", forIndexPath: indexPath) as! PlaylistsTableViewCell
            let bgColorView = UIView()
            bgColorView.backgroundColor = UIColor.init(red: 29/255, green: 33/255, blue: 36/255, alpha: 1)
            cell.selectedBackgroundView = bgColorView
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
     
            return cell
            
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier("inactives", forIndexPath: indexPath)
            return cell
        }
        */
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

/*

    SETTINGS CELL CLASS

*/

class PlaylistsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var playlistCover: UIImageView!
    @IBOutlet weak var playlistName: UILabel!
    @IBOutlet weak var playlistHour: UILabel!
    
}
