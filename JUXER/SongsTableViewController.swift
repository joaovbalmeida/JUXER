//
//  SongsTableViewController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 07/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit
import Kingfisher
import SCLAlertView

class SongsTableViewController: UITableViewController {
    
    private var songs: [Song] = [Song]()
    private var queueSongsID: [Int] = [Int]()
    var playlistName: String = String()
    var session = [Session]()
    
    private struct Song {
        var title: String
        var artist: String
        var cover: String
        var id: Int
        
        init (title: String, artist: String, cover: String, id: Int){
            self.title = "Title"
            self.artist = "Artist"
            self.cover = ""
            self.id = 0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        session = SessionDAO.fetchSession()

        getSongs()
    
    }
    
    private func getSongs(){
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
                    let resultJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                    
                    if let JSON = resultJSON.valueForKey("queue")! as? NSMutableArray {
                        
                        //Get queue songs id
                        if JSON.count > 0 {
                            for item in JSON {
                                let id = item.valueForKey("id") as! Int
                                self.queueSongsID.append(id)
                            }
                        }
                    }
                    
                    //Get songs that are not on queue yet
                    self.getSongsNotOnQueue()

                } catch let error as NSError {
                    print(error)
                }
            }
        }
        task.resume()
    }
    
    private func getSongsNotOnQueue(){
        
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
                            var newSong = Song(title: "title", artist: "artist", cover: "",id: 0)
                            newSong.id = item.valueForKey("id") as! Int
                            if self.queueSongsID.contains(newSong.id) != true {
                                newSong.title = item.valueForKey("title_short") as! String
                                newSong.artist = item.valueForKey("artist")!.valueForKey("name") as! String
                                newSong.cover = item.valueForKey("album")?.valueForKey("cover_medium") as! String
                                newSong.id = item.valueForKey("id") as! Int
                                self.songs.append(newSong)
                            }
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
        
        cell.songCover.kf_setImageWithURL(NSURL(string: self.songs[indexPath.row].cover)!,placeholderImage: Image(named: "CoverPlaceHolder.jpg"))
        cell.songTitleLabel.text = self.songs[indexPath.row].title
        cell.songArtistLabel.text = self.songs[indexPath.row].artist
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        

        self.tableView.userInteractionEnabled = false
        let alertView = SCLAlertView()
        
        let jsonObject: [String : AnyObject] =
            [ "id": self.songs[indexPath.row].id ]
        
        if NSJSONSerialization.isValidJSONObject(jsonObject) {
            
            do {
                
                let JSON = try NSJSONSerialization.dataWithJSONObject(jsonObject, options: [])
                
                // create post request
                let url = NSURL(string: "http://198.211.98.86/api/track/queue/\(session[0].id!)/")
                let request = NSMutableURLRequest(URL: url!)
                request.HTTPMethod = "POST"
                
                // insert json data to the request
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                request.setValue("JWT \(session[0].token!)", forHTTPHeaderField: "Authorization")
                request.HTTPBody = JSON
                
                let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
                    let httpResponse = response as! NSHTTPURLResponse
                    if httpResponse.statusCode == 200 {
                        
                        dispatch_async(dispatch_get_main_queue()){
                            
                            alertView.addButton("OK"){
                                self.dismissViewControllerAnimated(true, completion: {})
                            }
                            alertView.showCloseButton = false
                            alertView.showSuccess("Obrigado!", subTitle: "Seu pedido entrará na fila em breve!", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)

                            self.tableView.userInteractionEnabled = true
                        }
                        
                    } else if httpResponse.statusCode == 422 {
                        dispatch_async(dispatch_get_main_queue()){
                            alertView.showError("Ops", subTitle: "A música pedida já está na fila!", closeButtonTitle: "OK", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)

                            self.tableView.userInteractionEnabled = true
                            
                        }
                    } else if error != nil {
                        print(error)
                        self.tableView.userInteractionEnabled = true
                    }
                }
                task.resume()
            } catch {
                print(error)

                self.tableView.userInteractionEnabled = true
            }
        }
        
        
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


