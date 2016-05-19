//
//  PlaylistsTableViewController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 07/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit
import SwiftDate
import Kingfisher
import SCLAlertView

class PlaylistsTableViewController: UITableViewController {
    
    private var playlists = [Playlist]()
    private var session = [Session]()
    private var selectedPlaylist: String = String()
    
    var activityIndicator: UIActivityIndicatorView!
    var loadingView: UIView!
    
    private struct Playlist {
        var name: String
        var schedule: NSDate
        var deadline: NSDate?
        var cover: String
        var id: Int
        
        init (name: String, schedule: NSDate, cover: String, id: Int){
            self.name = String()
            self.schedule = NSDate()
            self.cover = String()
            self.id = 0
        }
    }

    lazy var playlistsRefreshControl: UIRefreshControl = {
        let playlistsRefreshControl = UIRefreshControl()
        playlistsRefreshControl.addTarget(self, action: #selector(PlaylistsTableViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        
        return playlistsRefreshControl
    }()
    
    func handleRefresh(refreshControl: UIRefreshControl){
        getPlaylists()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Configure Actitivity Indicator
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.frame = CGRect(x: self.view.bounds.maxX/2 - 10, y: self.view.bounds.maxY/2 - 10 - (self.navigationController?.navigationBar.frame.height)!, width: 20, height: 20)
        self.tableView.addSubview(activityIndicator)
        
        //Configure Refresh Controller
        playlistsRefreshControl.tintColor = UIColor.whiteColor()
        self.tableView.addSubview(playlistsRefreshControl)
        
        tableView.indicatorStyle = .White
        
        activityIndicator.startAnimating()
        
        session = SessionDAO.fetchSession()
        getPlaylists()

    }
    
    private func getPlaylists(){
        
        //Configure Alert View
        let appearance = SCLAlertView.SCLAppearance(showCloseButton: false)
        let alertView = SCLAlertView(appearance: appearance)
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let url = NSURL(string: "http://juxer.club/api/playlist/?available=\(session[0].id!)")
        let request = NSMutableURLRequest(URL: url!)
        
        request.HTTPMethod = "GET"
        request.setValue("JWT \(session[0].token!)", forHTTPHeaderField: "Authorization")
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if error != nil {
                print(error)
                dispatch_async(dispatch_get_main_queue()){
                    self.stopLoad()
                    alertView.addButton("OK"){
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                    alertView.showError("Erro de Conexão", subTitle: "Não foi possivel conectar ao servidor!", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                }

            } else {
                let httpResponse = response as! NSHTTPURLResponse
                if httpResponse.statusCode == 200 {
                    do {
                        let resultJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
                        let JSON = resultJSON.valueForKey("results") as! NSMutableArray
                        
                        if JSON.count > 0 {
                            
                            var tempPlaylist = [Playlist]()
                            
                            //Configure Calendar
                            let calendar = NSCalendar.currentCalendar()
                            let flags = NSCalendarUnit(rawValue: UInt.max)
                            let components = calendar.components(flags, fromDate: NSDate())
                            let today = calendar.dateFromComponents(components)
                            
                            //Create playlists struct array from JSON
                            for item in JSON {
                                
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
                                    
                                    var newPlaylist = Playlist(name: "", schedule: NSDate(), cover: "", id: 0)
                                    if let name = item.valueForKey("name") as? String {
                                        newPlaylist.name = name
                                    }
                                    if let id = item.valueForKey("id") as? Int {
                                        newPlaylist.id = id
                                    }
                                    if let picture = item.valueForKey("picture") as? String {
                                        newPlaylist.cover = picture
                                    }
                                    newPlaylist.schedule = startDate
                                    if endDateNil == false {
                                        newPlaylist.deadline = endDate
                                    }
                                    tempPlaylist.append(newPlaylist)
                                }
                                tempPlaylist.sortInPlace { $0.name < $1.name }
                                self.playlists = tempPlaylist
                            }
                        } else {
                            self.playlists.removeAll()
                        }
                        
                        //Refresh TableView
                        dispatch_async(dispatch_get_main_queue()){
                            self.stopLoad()
                            self.tableView.reloadData()
                        }
                        
                    } catch let error as NSError {
                        print(error)
                        dispatch_async(dispatch_get_main_queue()){
                            self.stopLoad()
                            alertView.addButton("OK"){
                                self.dismissViewControllerAnimated(true, completion: nil)
                            }
                            alertView.showError("Erro", subTitle: "Não foi possivel obter as Playlists!", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                        }
                    }
                } else {
                    print(httpResponse.statusCode)
                    dispatch_async(dispatch_get_main_queue()){
                        self.stopLoad()
                        alertView.addButton("OK"){
                            self.dismissViewControllerAnimated(true, completion: nil)
                        }
                        alertView.showError("Erro", subTitle: "Não foi possivel obter as Playlists!", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                    }
                }
                
            }
        }
        task.resume()
    }
    
    private func stopLoad(){
        if playlistsRefreshControl.refreshing == false {
            self.activityIndicator.stopAnimating()
        } else {
            self.playlistsRefreshControl.endRefreshing()
        }
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
        cell.separatorInset = UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 0)
        cell.layoutMargins = UIEdgeInsetsZero
        
        if playlists[indexPath.row].cover != "" {
            cell.playlistCover.kf_setImageWithURL(NSURL(string: playlists[indexPath.row].cover)!,placeholderImage: UIImage(named: "CoverPlaceholder"))
        }
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
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70
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
