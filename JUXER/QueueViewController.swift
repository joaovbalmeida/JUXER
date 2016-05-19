//
//  QueueViewController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 25/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import SCLAlertView

class QueueViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBAction func unwindToQueue(segue: UIStoryboardSegue){
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var requestLabelConstraint: NSLayoutConstraint!
    @IBOutlet weak var requestButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var albumBG: UIImageView!
    @IBOutlet weak var albumtImage: UIImageView!
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var songScrollingLabel: UILabel!
    @IBOutlet weak var artistScrollingLabel: UILabel!
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var orderButton: UIButton!

    private let kHeaderHeight: CGFloat = 380
    let darkBlur = UIBlurEffect(style: UIBlurEffectStyle.Dark)
    var overlay: UIView!
    var activityIndicator: UIActivityIndicatorView!
    var alertView = SCLAlertView()

    private var session: [Session] = [Session]()
    private var tracks: [Track] = [Track]()
    
    private struct Track {
        var title: String
        var artist: String
        var album: String
        var cover: String
        var user: String
        
        init (title: String, artist: String, album: String, cover: String, user: String){
            self.title = "Title"
            self.artist = "Artist"
            self.album = "Album"
            self.cover = ""
            self.user = "User"
        }
    }
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(QueueViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        
        return refreshControl
    }()
    
    func handleRefresh(refreshControl: UIRefreshControl){
        getQueue()
    }
    
    func reloadTableData(notification: NSNotification) {
        getQueue()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        session = SessionDAO.fetchSession()
        
        //Configure activity indicator
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.frame = CGRect(x: self.view.bounds.maxX/2 - 10, y: self.view.bounds.maxY/2 - 10, width: 20, height: 20)
        self.view.addSubview(activityIndicator)
        
        //Check if connected to event
        if session.count != 0 && session[0].active == 1 {
            getQueue()
            
        } else {
            orderButton.userInteractionEnabled = false
        }
        
        //Configure Stretchy Header
        headerView = tableView.tableHeaderView
        headerView.clipsToBounds = true
        tableView.clipsToBounds = true
        tableView.tableHeaderView = nil
        tableView.addSubview(headerView)
        tableView.contentInset = UIEdgeInsets(top: kHeaderHeight, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -kHeaderHeight)

        tableView.allowsSelection = false
        
        //Configure Pull to Refresh
        refreshControl.tintColor = UIColor.whiteColor()
        refreshControl.bounds.origin.y = 350
        if session.count != 0 && session[0].active == 1 {
            tableView.addSubview(refreshControl)
        }
        
        //Configure NSObserver for Reload
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(QueueViewController.reloadTableData(_:)), name: "reload", object: nil)
    }


    func updateHeaderView() {
        var headerRect = CGRect(x: 0, y: -kHeaderHeight, width: view.bounds.width , height: kHeaderHeight)
        if tableView.contentOffset.y <= -120 {
            headerRect.size.height = -tableView.contentOffset.y
            headerRect.origin.y = tableView.contentOffset.y
            requestLabelConstraint.constant = -tableView.contentOffset.y - 15
            requestButtonConstraint.constant = -tableView.contentOffset.y - 15
        } else if tableView.contentOffset.y > -120 {
            headerRect.size.height = 120
            headerRect.origin.y = tableView.contentOffset.y
            requestButtonConstraint.constant = 105
            requestLabelConstraint.constant = 105
        }
        headerView.frame = headerRect
        
    }
    
    func updateInitialLabels() {
        var alpha: CGFloat = 1
        if tableView.contentOffset.y >= -250 {
            alpha = ((-tableView.contentOffset.y / 80) - 11/5)
        }
        albumtImage.alpha = alpha
        artistLabel.alpha = alpha
        songLabel.alpha = alpha
    }
    
    func updateScrollingLabels() {
        var alpha: CGFloat = 1
        if tableView.contentOffset.y <= -130 {
            alpha = (-(-tableView.contentOffset.y / 50) + 18/5)
        }
        songScrollingLabel.alpha = alpha
        artistScrollingLabel.alpha = alpha
    }
    
    private func getQueue(){
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        if refreshControl.refreshing == false {
            dispatch_async(dispatch_get_main_queue()){
                self.startLoadOverlay()
            }
        }
        
        let url = NSURL(string: "http://juxer.club/api/track/queue/\(session[0].id!)/")
        let request = NSMutableURLRequest(URL: url!)
        
        request.HTTPMethod = "GET"
        request.setValue("JWT \(session[0].token!)", forHTTPHeaderField: "Authorization")
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if error != nil {
                print(error)
                dispatch_async(dispatch_get_main_queue()){
                    self.stopLoad()
                    self.alertView.showError("Erro de Conexão", subTitle: "Não foi possivel conectar ao servidor!", closeButtonTitle: "OK", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                }
            } else {
                do {
                    let resultJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
                    if let JSON = resultJSON.valueForKey("queue") as? NSMutableArray {
                        
                        //Get now playing index
                        var index = resultJSON.valueForKey("index")! as? Int
                        if index == nil {
                            index = 0
                        }
                        
                        //Refresh Now Playing Track
                        if JSON.count > 0 && index < JSON.count {
                            dispatch_async(dispatch_get_main_queue()) {
                                if let title = JSON[index!].valueForKey("title_short") as? String {
                                    self.songLabel.text = title
                                    self.songScrollingLabel.text = title
                                }
                                if let artist = JSON[index!].valueForKey("artist")!.valueForKey("name") as? String {
                                    if let album = JSON[index!].valueForKey("album")!.valueForKey("title") as? String {
                                        self.artistLabel.text = artist + " - " + album
                                        self.artistScrollingLabel.text = artist + " - " + album
                                    } else {
                                        self.artistLabel.text = artist
                                        self.artistScrollingLabel.text = artist
                                    }
                                }
                                if let userFirstName = JSON[index!].valueForKey("user")!.valueForKey("first_name") as? String{
                                    if let userLastName = JSON[index!].valueForKey("user")!.valueForKey("last_name") as? String {
                                        self.usernameLabel.text = userFirstName + " " + userLastName
                                    } else {
                                        self.usernameLabel.text = userFirstName
                                    }
                                }
                                if let cover = JSON[index!].valueForKey("album")!.valueForKey("cover_big") as? String {
                                    self.albumtImage.kf_setImageWithURL(NSURL(string: cover)!, placeholderImage: Image(named: "PlayingCoverPlaceholder"))
                                    self.albumBG.kf_setImageWithURL(NSURL(string: cover)!)
                                }
                            }
                        } else {
                            if self.tracks.count != 0 {
                                self.tracks.removeAll()
                            }
                            dispatch_async(dispatch_get_main_queue()){
                                self.albumtImage.image = Image(named: "PlayingCoverPlaceholder")
                                self.albumBG.image = nil
                                self.usernameLabel.text = ""
                                self.artistLabel.text = ""
                                self.artistScrollingLabel.text = ""
                                self.songLabel.text = ""
                                self.songScrollingLabel.text = ""
                            }
                        }
                        
                        //Create tracks struct array from JSON
                        if JSON.count > index {
                            var tempTracks = [Track]()
                            for i in index! + 1..<JSON.count {
                                var newTrack = Track(title: "", artist: "", album: "", cover: "", user: "")
                                if let title = JSON[i].valueForKey("title_short") as? String {
                                    newTrack.title = title
                                }
                                if let artist = JSON[i].valueForKey("artist")!.valueForKey("name") as? String {
                                    newTrack.artist = artist
                                }
                                if let album = JSON[i].valueForKey("album")!.valueForKey("title") as? String {
                                    newTrack.album = album
                                }
                                if let cover = JSON[i].valueForKey("album")!.valueForKey("cover_medium") as? String {
                                    newTrack.cover = cover
                                }
                                if let userFirstName = JSON[i].valueForKey("user")!.valueForKey("first_name") as? String{
                                    if let userLastName = JSON[i].valueForKey("user")!.valueForKey("last_name") as? String {
                                        newTrack.user = userFirstName + " " + userLastName
                                    } else {
                                        newTrack.user = userFirstName
                                    }
                                }
                                tempTracks.append(newTrack)
                            }
                            self.tracks = tempTracks
                        }
                      
                        //Refresh TableView
                        dispatch_async(dispatch_get_main_queue()){
                            self.stopLoad()
                            self.tableView.reloadData()
                        }
                    } else {
                        dispatch_async(dispatch_get_main_queue()){
                            self.stopLoad()
                            self.alertView.showError("Erro", subTitle: "Não foi possivel obter fila de músicas!", closeButtonTitle: "OK", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                        }
                    }

                } catch let error as NSError {
                    dispatch_async(dispatch_get_main_queue()){
                        self.stopLoad()
                        self.alertView.showError("Erro", subTitle: "Não foi possivel obter fila de músicas!", closeButtonTitle: "OK", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                    }
                    print(error)
                }
            }
        }
        task.resume()
    }
    
    private func startLoadOverlay(){
        overlay = UIView(frame: CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height))
        overlay.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        self.activityIndicator.startAnimating()
        self.view.addSubview(self.overlay)
        self.view.bringSubviewToFront(self.activityIndicator)
    }
    
    private func stopLoad(){
        if refreshControl.refreshing == false {
            self.activityIndicator.stopAnimating()
            self.overlay.removeFromSuperview()
        } else {
            self.refreshControl.endRefreshing()
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0:
            if tracks.count == 0 {
                return 0
            } else {
                return 1
            }
        case 1:
            if refreshControl.refreshing == true {
                return 0
            } else {
                return tracks.count
            }
        case 2:
            return 1
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch (indexPath.section) {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("header", forIndexPath: indexPath)
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            return cell
            
        case 1:
            let cell: QueueTableViewCell = tableView.dequeueReusableCellWithIdentifier("queue", forIndexPath: indexPath) as! QueueTableViewCell
            cell.separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 0)
            cell.layoutMargins = UIEdgeInsetsZero
            if refreshControl.refreshing == false {
        
                cell.trackCover.kf_setImageWithURL(NSURL(string: self.tracks[indexPath.row].cover)!,placeholderImage: Image(named: "CoverPlaceHolder"))
                cell.trackTitle.text = self.tracks[indexPath.row].title
                if self.tracks[indexPath.row].album != "" {
                    cell.trackArtist.text = self.tracks[indexPath.row].artist + " - " + self.tracks[indexPath.row].album
                } else {
                    cell.trackArtist.text = self.tracks[indexPath.row].artist
                }
                cell.trackUser.text = self.tracks[indexPath.row].user
                cell.trackOrder.text = String(indexPath.row + 1)
            }
            return cell
        case 2:
            let cell: FooterTableViewCell = tableView.dequeueReusableCellWithIdentifier("footer") as! FooterTableViewCell
            cell.separatorInset = UIEdgeInsets(top: 0, left: view.bounds.maxX, bottom: 0, right: 0)
            cell.layoutMargins = UIEdgeInsetsZero
            if self.tracks.count == 0 {
                cell.footerLabel.hidden = false
                cell.footerPlaceholder.hidden = false
            } else {
                cell.footerPlaceholder.hidden = true
                cell.footerLabel.hidden = true
            }
            return cell
            
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier("queue", forIndexPath: indexPath)
            cell.separatorInset = UIEdgeInsets(top: 0, left: view.bounds.maxX, bottom: 0, right: 0)
            cell.layoutMargins = UIEdgeInsetsZero
            return cell
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch (indexPath.section) {
        case 0:
            return 30
        case 1:
            return 65
        case 2:
            if self.tracks.count == 0 {
                return 260 + (self.view.bounds.maxY - kHeaderHeight)
            } else if 230 + (self.view.bounds.maxY - kHeaderHeight - (CGFloat(tracks.count) * 65)) > 0 {
                return 230 + (self.view.bounds.maxY - kHeaderHeight - (CGFloat(tracks.count) * 65))
            } else {
                return 0
            }
        default:
            return 0
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        updateInitialLabels()
        updateScrollingLabels()
        updateHeaderView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

/*

    QUEUE AND FOOTER CELL CLASSES

*/

class QueueTableViewCell: UITableViewCell {

    @IBOutlet weak var trackOrder: UILabel!
    @IBOutlet weak var trackTitle: UILabel!
    @IBOutlet weak var trackArtist: UILabel!
    @IBOutlet weak var trackCover: UIImageView!
    @IBOutlet weak var trackUser: UILabel!
    
}

class FooterTableViewCell: UITableViewCell {
    
    @IBOutlet weak var footerPlaceholder: UIImageView!
    @IBOutlet weak var footerLabel: UILabel!
    
}

