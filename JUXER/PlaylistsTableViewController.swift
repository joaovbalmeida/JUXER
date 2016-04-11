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
        
        

    }
/*
    private func getPlaylist(){
        
        //Erase previous Data
        if self.tracks.count != 0 {
            tracks.removeAll()
        }
        
        let url = NSURL(string: "http://198.211.98.86/api/track/queue/\(session[0].id!)/")
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
                    
                    //Get now playing index
                    self.index = resultJSON.valueForKey("index")! as! Int
                    
                    //Get All Tracks
                    let title: [NSString] = resultJSON.valueForKey("queue")!.valueForKey("title_short")! as! [NSString]
                    let artist: [NSString] = resultJSON.valueForKey("queue")!.valueForKey("artist")!.valueForKey("name")! as! [NSString]
                    let album: [NSString] = resultJSON.valueForKey("queue")!.valueForKey("album")!.valueForKey("title")! as! [NSString]
                    let coverSmall: [NSString] = resultJSON.valueForKey("queue")!.valueForKey("album")!.valueForKey("cover")! as! [NSString]
                    let cover: [NSString] = resultJSON.valueForKey("queue")!.valueForKey("album")!.valueForKey("cover_big")! as! [NSString]
                    
                    //Refresh Now Playing Track
                    dispatch_async(dispatch_get_main_queue()) {
                        self.songLabel.text = title[self.index] as String
                        self.artistLabel.text = "\(artist[self.index] as String) - \(album[self.index] as String)"
                        self.albumBG.hnk_setImageFromURL(NSURL(string: String(cover[self.index]))!)
                        self.albumtImage.hnk_setImageFromURL(NSURL(string: String(cover[self.index]))!)
                        self.songScrollingLabel.text = self.songLabel.text
                        self.artistScrollingLabel.text = self.artistLabel.text
                    }
                    
                    //Get how many tracks
                    self.count = title.count - self.index
                    
                    //Wrap tracks info into Struct
                    for i in self.index + 1 ..< title.count {
                        var newTrack = Track(title: "title", artist: "artist", cover: "")
                        newTrack.title = title[i] as String
                        newTrack.artist = artist[i] as String
                        newTrack.cover = coverSmall[i] as String
                        self.tracks.append(newTrack)
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
*/
 
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell: PlaylistsTableViewCell = tableView.dequeueReusableCellWithIdentifier("actives", forIndexPath: indexPath) as! PlaylistsTableViewCell
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.init(red: 29/255, green: 33/255, blue: 36/255, alpha: 1)
        cell.selectedBackgroundView = bgColorView
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero
        
        
        
        
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
