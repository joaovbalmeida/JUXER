//
//  SongsTableViewController.swift
//  Juxer
//
//  Created by Joao Victor Almeida on 07/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit
import Kingfisher
import SCLAlertView

class SongsTableViewController: UITableViewController {
    
    private var songs = [Song]()
    private var filteredSongs = [Song]()
    private var queueSongsID = [Int]()
    var playlistName = String()
    var session = [Session]()
    var user = [User]()
    
    private var firstTimeLoading = true
    var activityIndicator: UIActivityIndicatorView!
    var overlay: UIView!
    var alertView = SCLAlertView()
    let searchController = UISearchController(searchResultsController: nil)
    
    private struct Song {
        var title: String
        var artist: String
        var album: String
        var cover: String
        var id: Int
        
        init (title: String, artist: String, album: String, cover: String, id: Int){
            self.title = ""
            self.artist = ""
            self.album = ""
            self.cover = ""
            self.id = 0
        }
    }
    
    lazy var songsRefreshControl: UIRefreshControl = {
        let songsRefreshControl = UIRefreshControl()
        songsRefreshControl.addTarget(self, action: #selector(SongsTableViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        
        return songsRefreshControl
    }()
    
    func handleRefresh(refreshControl: UIRefreshControl){
        getSongs()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Configure Actitivity Indicator
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.frame = CGRect(x: self.view.bounds.maxX/2 - 10, y: self.view.bounds.maxY/2 - 10 - (self.navigationController?.navigationBar.frame.height)!, width: 20, height: 20)
        self.tableView.addSubview(activityIndicator)
        
        activityIndicator.startAnimating()
        
        //Configure SCLAlert
        let appearance = SCLAlertView.SCLAppearance(showCloseButton: false)
        alertView = SCLAlertView(appearance: appearance)
        
        //Configure SearchBar
        searchController.searchBar.barTintColor = UIColor.blackColor()
        searchController.searchBar.placeholder = "Search".localized
        searchController.searchBar.tintColor = UIColor.init(red: 255/255, green: 0/255, blue: 90/255, alpha: 1)
        searchController.searchBar.keyboardAppearance = .Dark
        searchController.searchBar.enablesReturnKeyAutomatically = true
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        tableView.backgroundView = UIView()
        tableView.indicatorStyle = .White
        
        //Configure Pull to Refresh
        songsRefreshControl.tintColor = UIColor.whiteColor()
        
        session = SessionDAO.fetchSession()
        getSongs()
        
        user = UserDAO.fetchUser()
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredSongs = songs.filter { Song in
            if Song.title.lowercaseString.containsString(searchText.lowercaseString) || Song.artist.lowercaseString.containsString(searchText.lowercaseString) || Song.album.lowercaseString.containsString(searchText.lowercaseString) {
                return true
            } else {
                return false
            }
        }
        tableView.reloadData()
    }
    
    private func getSongs(){
        
        //Erase previous Data
        if self.queueSongsID.count != 0 {
            queueSongsID.removeAll()
        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        let url = NSURL(string: "http://juxer.club/api/track/queue/\(session[0].id!)/")
        let request = NSMutableURLRequest(URL: url!)
        
        request.HTTPMethod = "GET"
        request.setValue("JWT \(session[0].token!)", forHTTPHeaderField: "Authorization")
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if error != nil {
                print(error)
                dispatch_async(dispatch_get_main_queue()){
                    self.stopLoadSpinner()
                    self.connectionErrorAlert()
                }
            } else {
                let httpResponse = response as! NSHTTPURLResponse
                if httpResponse.statusCode == 200 {
                    do {
                        let resultJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                        
                        if let JSON = resultJSON.valueForKey("queue")! as? NSMutableArray {
                            
                            //Get queue songs id
                            if JSON.count > 0 {
                                for item in JSON {
                                    if let id = item.valueForKey("id") as? Int {
                                        self.queueSongsID.append(id)
                                    }
                                }
                            }
                        }
                        //Get songs that are not on queue yet
                        self.getSongsNotOnQueue()
                        
                    } catch let error as NSError {
                        print(error)
                        dispatch_async(dispatch_get_main_queue()){
                            self.stopLoadSpinner()
                            self.JSONErrorAlert()
                        }
                    }
                } else {
                    print(httpResponse.statusCode)
                    dispatch_async(dispatch_get_main_queue()){
                        self.stopLoadSpinner()
                        self.connectionErrorAlert()
                    }
                }
            }
        }
        task.resume()
    }
    
    private func getSongsNotOnQueue(){
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        let url = NSURL(string: "http://juxer.club/api/track/playlist/\(session[0].id!)/?sorted=1")
        let request = NSMutableURLRequest(URL: url!)
        
        request.HTTPMethod = "GET"
        request.setValue("JWT \(session[0].token!)", forHTTPHeaderField: "Authorization")
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if error != nil {
                print(error)
                dispatch_async(dispatch_get_main_queue()){
                    self.stopLoadSpinner()
                    self.connectionErrorAlert()
                }
            } else {
                let httpResponse = response as! NSHTTPURLResponse
                if httpResponse.statusCode == 200 {
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
                        //Wrap songs in array of Song struct
                        var tempSongs = [Song]()
                        if songsData.count != 0 {
                            for item in songsData {
                                var newSong = Song(title: "", artist: "", album: "", cover: "",id: 0)
                                if let id = item.valueForKey("id") as? Int {
                                    newSong.id = id
                                }
                                if self.queueSongsID.contains(newSong.id) != true {
                                    if let title = item.valueForKey("title_short") as? String{
                                        newSong.title = title
                                    }
                                    if let artistName = item.valueForKey("artist")!.valueForKey("name") as? String {
                                        newSong.artist = artistName
                                    }
                                    if let albumName = item.valueForKey("album")!.valueForKey("title") as? String{
                                        newSong.album = albumName
                                    }
                                    if let cover = item.valueForKey("album")!.valueForKey("cover_medium") as? String{
                                        newSong.cover = cover
                                    }
                                    tempSongs.append(newSong)
                                }
                            }
                            tempSongs.sortInPlace { $0.artist < $1.artist }
                            self.songs = tempSongs
                        }
                        
                        if self.songs.count != 0 {
                            dispatch_async(dispatch_get_main_queue()){
                                if self.firstTimeLoading {
                                    self.view.addSubview(self.songsRefreshControl)
                                    self.firstTimeLoading = false
                                }
                                self.stopLoadSpinner()
                                self.tableView.reloadData()
                            }
                        } else {
                            dispatch_async(dispatch_get_main_queue()){
                                let appearance = SCLAlertView.SCLAppearance(showCloseButton: false)
                                self.alertView = SCLAlertView(appearance: appearance)
                                self.alertView.addButton("OK"){
                                    self.performSegueWithIdentifier("unwindToPlaylists", sender: self)
                                }
                                self.alertView.showInfo("Oops".localized, subTitle: "This playlist ran out of tracks!".localized, colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                            }
                        }
                        
                    } catch let error as NSError {
                        print(error)
                        dispatch_async(dispatch_get_main_queue()){
                            self.stopLoadSpinner()
                            self.JSONErrorAlert()
                        }     
                    }
                } else {
                    print(httpResponse.statusCode)
                    dispatch_async(dispatch_get_main_queue()){
                        self.stopLoadSpinner()
                        self.connectionErrorAlert()
                    }
                }
            }
        }
        task.resume()
    }

    private func stopLoadSpinner(){
        if songsRefreshControl.refreshing == false {
            self.activityIndicator.stopAnimating()
        } else {
            self.songsRefreshControl.endRefreshing()
        }
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.active && searchController.searchBar.text != "" {
            return filteredSongs.count
        }
        return songs.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: SongsTableViewCell = tableView.dequeueReusableCellWithIdentifier("songs", forIndexPath: indexPath) as! SongsTableViewCell
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.init(red: 29/255, green: 33/255, blue: 36/255, alpha: 1)
        cell.selectedBackgroundView = bgColorView
        cell.separatorInset = UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 0)
        cell.layoutMargins = UIEdgeInsetsZero
        
        let song: Song
        
        //Get song from filter or not
        if searchController.active && searchController.searchBar.text != "" {
            song = filteredSongs[indexPath.row]
        } else {
            song = songs[indexPath.row]
        }
        
        //Show info from the song
        if song.cover != "" {
            cell.songCover.kf_setImageWithURL(NSURL(string: song.cover)!,placeholderImage: Image(named: "CoverPlaceholder"))
        }
        if song.album != "" {
            cell.songArtistLabel.text = song.artist + " - " + song.album
        } else {
            cell.songArtistLabel.text = song.artist
        }
        cell.songTitleLabel.text = song.title
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let id: Int
        //Get song id from filter or not
        if searchController.active && searchController.searchBar.text != "" {
            id = filteredSongs[indexPath.row].id
        } else {
            id = songs[indexPath.row].id
        }
        
        searchController.dismissViewControllerAnimated(true, completion: nil)
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        dispatch_async(dispatch_get_main_queue()){
            self.startLoadOverlay()
        }
        
        var alertView = SCLAlertView()
        let jsonObject: [String : AnyObject] =
            [ "id": id , "anom" : user[0].anonymous! ]
        
        if NSJSONSerialization.isValidJSONObject(jsonObject) {
            
            do {
                let JSON = try NSJSONSerialization.dataWithJSONObject(jsonObject, options: [])
                
                // create post request
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                let url = NSURL(string: "http://juxer.club/api/track/queue/\(session[0].id!)/")
                let request = NSMutableURLRequest(URL: url!)
                request.HTTPMethod = "POST"
                
                // insert json data to the request
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                request.setValue("JWT \(session[0].token!)", forHTTPHeaderField: "Authorization")
                request.HTTPBody = JSON
                
                let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    
                    if error != nil {
                        print(error)
                        dispatch_async(dispatch_get_main_queue()){
                            self.connectionErrorAlert()
                            self.stopLoadOverlay()
                        }
                        
                    } else {
                        
                        let string = NSString(data: data!, encoding: NSUTF8StringEncoding)
                        let httpResponse = response as! NSHTTPURLResponse
                        if httpResponse.statusCode == 200 {
                            
                            NSNotificationCenter.defaultCenter().postNotificationName("reload", object: nil)
                            dispatch_async(dispatch_get_main_queue()){
                                let appearance = SCLAlertView.SCLAppearance(showCloseButton: false)
                                alertView = SCLAlertView(appearance: appearance)
                                alertView.addButton("OK"){
                                    self.dismissViewControllerAnimated(true, completion: {})
                                }
                                alertView.showSuccess("Thanks".localized, subTitle: "Your request is now on queue!".localized, colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                            }
                            
                        } else if httpResponse.statusCode == 422 {
                            
                            if string == "\"Track already on queue\"" {
                                dispatch_async(dispatch_get_main_queue()){
                                    self.stopLoadOverlay()
                                    alertView.showError("Oops".localized, subTitle: "The requested track is already on queue!".localized, closeButtonTitle: "OK", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                                }
                            } else if string == "\"User has already reached song request limit\"" {
                                dispatch_async(dispatch_get_main_queue()){
                                    self.stopLoadOverlay()
                                    alertView.showError("Reached Limit".localized, subTitle: "You have reached your request limit, wait your pending requests finish and try again!".localized, closeButtonTitle: "OK", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                                }
                            } else if string == "\"Unavailable track\"" {
                                dispatch_async(dispatch_get_main_queue()){
                                    self.stopLoadOverlay()
                                    alertView.showError("Reached Limit".localized, subTitle: "This Playlist reached the deadline limit!".localized, closeButtonTitle: "OK", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                                }
                            } else {
                                dispatch_async(dispatch_get_main_queue()){
                                    self.stopLoadOverlay()
                                    alertView.showError("Error".localized, subTitle: "Unable to request this song!".localized, closeButtonTitle: "OK", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                                }
                            }
                        } else {
                            dispatch_async(dispatch_get_main_queue()){
                                self.stopLoadOverlay()
                                alertView.showError("Error".localized, subTitle: "Unable to make request, please try again!".localized, closeButtonTitle: "OK", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                            }
                            print(httpResponse.statusCode)
                            print(string)
                        }
                    }
                }
                task.resume()
            } catch {
                print(error)
                dispatch_async(dispatch_get_main_queue()){
                    self.stopLoadOverlay()
                    self.JSONErrorAlert()
                }
            }
        }
    }
    
    private func connectionErrorAlert(){
        self.alertView.addButton("OK"){
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        self.alertView.showError("Connection Error".localized, subTitle: "Unable to reach server, please try again!".localized, colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
    }
    
    private func JSONErrorAlert(){
        self.alertView.addButton("OK"){
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        self.alertView.showError("Error".localized, subTitle: "Unable to get Tracks!".localized, colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
    }
    
    private func startLoadOverlay(){
        self.tableView.userInteractionEnabled = false
        self.navigationController?.navigationBar.userInteractionEnabled = false
        self.overlay = UIView(frame: CGRectMake(0, tableView.contentOffset.y, self.view.bounds.width, self.view.bounds.height))
        self.overlay.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        self.activityIndicator.frame.origin.y = self.tableView.contentOffset.y + self.view.bounds.height/2 - 10
        self.activityIndicator.startAnimating()
        self.view.addSubview(self.overlay)
        self.view.bringSubviewToFront(self.activityIndicator)
    }
    
    private func stopLoadOverlay(){
        self.activityIndicator.stopAnimating()
        self.overlay.removeFromSuperview()
        self.tableView.userInteractionEnabled = true
        self.navigationController?.navigationBar.userInteractionEnabled = true
    }
    
    deinit {
        self.searchController.view.removeFromSuperview()
    }
    
}

extension SongsTableViewController: UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
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


