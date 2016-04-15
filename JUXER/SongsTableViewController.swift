//
//  SongsTableViewController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 07/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit
import Haneke

class SongsTableViewController: UITableViewController {
    
    private var songs: [Song] = [Song]()
    var playlistName: String = String()
    
    private struct Song {
        var title: String
        var artist: String
        var cover: String
        
        init (title: String, artist: String, cover: String){
            self.title = "Title"
            self.artist = "Artist"
            self.cover = ""
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = true
        getSongs()
    }
    
    private func getSongs(){
        
        var session = [Session]()
        session = SessionDAO.fetchSession()
        
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
                    let resultJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                    let JSON = resultJSON as! [String:AnyObject]
                    var songsData = NSMutableArray()
                    
                    //Get respective playlist songs
                    for item in JSON {
                        if item.0 == self.playlistName {
                            songsData = item.1 as! NSMutableArray
                        }
                    }
                    //Wrap songs in struct
                    if songsData.count != 0 {
                        for item in songsData {
                            var newSong = Song(title: "title", artist: "artist", cover: "")
                            newSong.title = item.valueForKey("title_short") as! String
                            newSong.artist = item.valueForKey("artist")!.valueForKey("name") as! String
                            newSong.cover = item.valueForKey("album")?.valueForKey("cover_medium") as! String
                            self.songs.append(newSong)
                        }
                    }
                    
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return songs.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: SongsTableViewCell = tableView.dequeueReusableCellWithIdentifier("songs", forIndexPath: indexPath) as! SongsTableViewCell
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.init(red: 29/255, green: 33/255, blue: 36/255, alpha: 1)
        cell.selectedBackgroundView = bgColorView
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero
        
        cell.songCover.hnk_setImageFromURL(NSURL(string: self.songs[indexPath.row].cover)!)
        cell.songTitleLabel.text = self.songs[indexPath.row].title
        cell.songArtistLabel.text = self.songs[indexPath.row].artist
        
        return cell
    }

}

 /*
 
 SONGS CELL CLASS
 
 */

class SongsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var songArtistLabel: UILabel!
    @IBOutlet weak var songCover: UIImageView!
    
}


