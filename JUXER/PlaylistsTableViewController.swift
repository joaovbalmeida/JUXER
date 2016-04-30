//
//  PlaylistsTableViewController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 07/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit
import SwiftDate

class PlaylistsTableViewController: UITableViewController {
    
    private var playlists = [Playlist]()
    private var session = [Session]()
    private var selectedPlaylist: String = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        session = SessionDAO.fetchSession()
        getPlaylists()

    }
    
    private struct Playlist {
        var name: String
        var schedule: NSDate
        var deadline: NSDate?
        var cover: String
        var id: Int
        
        init (name: String, schedule: NSDate, cover: String, id: Int){
            self.name = "Title"
            self.schedule = NSDate()
            self.cover = ""
            self.id = 0
        }
    }

    private func getPlaylists(){
        
        //Erase previous Data
        if self.playlists.count != 0 {
            playlists.removeAll()
        }
        
        let url = NSURL(string: "http://198.211.98.86/api/playlist/?event=\(session[0].id!)")
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
                    let JSON = resultJSON.valueForKey("results") as! NSMutableArray

                    //Create playlists struct array from JSON
                    for item in JSON {
 
                        //Get current time and convert to NSDate
                        let calendar = NSCalendar.currentCalendar()
                        let flags = NSCalendarUnit(rawValue: UInt.max)
                        let components = calendar.components(flags, fromDate: NSDate())
                        let today = calendar.dateFromComponents(components)
                        
                        //Get playlist time and convert to NSDate
                        var startDate = NSDate()
                        var endDate = NSDate()
                        var endDateNil = false
                        if let dateString = item.valueForKey("starts_at") as? String {
                            startDate = dateString.toDateFromISO8601()!
                        }
                        if let endDateString = item.valueForKey("deadline") as? String {
                            endDate = endDateString.toDateFromISO8601()!
                        } else {
                            endDateNil = true
                        }
                        
                        //Compare playlist hour to current time
                        if startDate.timeIntervalSinceDate(today!).isSignMinus && endDate.timeIntervalSinceDate(today!) > 0 {
                            
                            var newPlaylist = Playlist(name: "name", schedule: NSDate(), cover: "", id: 0)
                            newPlaylist.name = item.valueForKey("name") as! String
                            newPlaylist.id = item.valueForKey("id") as! Int
                            newPlaylist.schedule = startDate
                            if endDateNil == false {
                                newPlaylist.deadline = endDate
                            }
                            
                            //newPlaylist.cover = item.valueForKey("picture") as! String
                            self.playlists.append(newPlaylist)
                        }
                        
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
        
        if playlists[indexPath.row].deadline != nil {
            cell.playlistHour.text = NSDateFormatter.localizedStringFromDate(playlists[indexPath
                .row].schedule, dateStyle: .ShortStyle, timeStyle: .ShortStyle) + " - " + NSDateFormatter.localizedStringFromDate(playlists[indexPath
                    .row].deadline!, dateStyle: .ShortStyle, timeStyle: .ShortStyle)

        } else {
            cell.playlistHour.text = NSDateFormatter.localizedStringFromDate(playlists[indexPath
                .row].schedule, dateStyle: .ShortStyle, timeStyle: .ShortStyle)
        }
        cell.playlistName.text = playlists[indexPath.row].name
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        self.selectedPlaylist = playlists[indexPath.row].name
        self.performSegueWithIdentifier("toActiveSongs", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "toActiveSongs" {
            let destVC = segue.destinationViewController as! SongsTableViewController
            destVC.playlistName = self.selectedPlaylist
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

/*

    PLAYLISTS CELL CLASS

*/

class PlaylistsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var playlistCover: UIImageView!
    @IBOutlet weak var playlistName: UILabel!
    @IBOutlet weak var playlistHour: UILabel!
    
}
