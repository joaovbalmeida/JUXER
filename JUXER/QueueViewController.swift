//
//  QueueViewController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 25/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import Foundation
import UIKit
import FBSDKShareKit
import Kingfisher

class QueueViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBAction func refresh(sender: AnyObject) {
        getQueue()
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var juxerButton: UIButton!
    @IBOutlet weak var juxerLabel: UILabel!
    
    @IBOutlet weak var requestLabelConstraint: NSLayoutConstraint!
    @IBOutlet weak var requestButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var albumBG: UIImageView!
    @IBOutlet weak var albumtImage: UIImageView!
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var songScrollingLabel: UILabel!
    @IBOutlet weak var artistScrollingLabel: UILabel!
    
    @IBOutlet weak var headerView: UIView!

    private let kHeaderHeight: CGFloat = 380
    let darkBlur = UIBlurEffect(style: UIBlurEffectStyle.Dark)

    private var session = [Session]()
    private var tracks: [Track] = [Track]()
    
    private struct Track {
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
    
        session = SessionDAO.fetchSession()
        
        getQueue()
        
        headerView = tableView.tableHeaderView
        headerView.clipsToBounds = true
        tableView.clipsToBounds = true

        tableView.tableHeaderView = nil
        tableView.addSubview(headerView)
        
        tableView.contentInset = UIEdgeInsets(top: kHeaderHeight, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -kHeaderHeight)

        tableView.allowsSelection = false
        
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
                    let JSON = resultJSON.valueForKey("queue")! as! NSMutableArray
                    
                    //Get now playing index
                    var index = resultJSON.valueForKey("index")! as? Int
                    if index == nil{
                        index = 0
                    }
                    
                    //Refresh Now Playing Track
                    if JSON.count > 0 {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.songLabel.text = JSON[index!].valueForKey("title_short") as? String
                            self.artistLabel.text = JSON[index!].valueForKey("artist")!.valueForKey("name") as? String
                            self.albumtImage.kf_setImageWithURL(NSURL(string: String(JSON[index!].valueForKey("album")!.valueForKey("cover_big")!))!, placeholderImage: Image(named: "BigCoverPlaceHolder.png"))
                            self.albumBG.kf_setImageWithURL(NSURL(string: String(JSON[index!].valueForKey("album")!.valueForKey("cover_big")!))!)
                            self.songScrollingLabel.text = self.songLabel.text
                            self.artistScrollingLabel.text = self.artistLabel.text
                        }
                    } else {
                        dispatch_async(dispatch_get_main_queue()){
                            self.songLabel.text = ""
                            self.artistLabel.text = ""
                            self.albumtImage.image = Image(named: "BigCoverPlaceHolder.png")
                            self.albumBG.image = nil
                            self.songScrollingLabel.text = self.songLabel.text
                            self.artistScrollingLabel.text = self.artistLabel.text
                        }
                    }
                    
                    //Create tracks struct array from JSON
                    if JSON.count > index {
                        for i in index! + 1..<JSON.count {
                            var newTrack = Track(title: "title", artist: "artist", cover: "")
                            newTrack.title = JSON[i].valueForKey("title_short") as! String
                            newTrack.artist = JSON[i].valueForKey("artist")!.valueForKey("name") as! String
                            newTrack.cover = JSON[i].valueForKey("album")!.valueForKey("cover_medium") as! String
                            self.tracks.append(newTrack)
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
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0:
            return 1
        case 1:
            return tracks.count
        case 2:
            if tracks.count < 7 {
                return 1
            } else {
                return 0
            }
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
            cell.trackTitle.text = self.tracks[indexPath.row].title
            cell.trackArtist.text = self.tracks[indexPath.row].artist
            cell.trackOrder.text = String(indexPath.row + 1)
            cell.trackCover.kf_setImageWithURL(NSURL(string: self.tracks[indexPath.row].cover)!,placeholderImage: Image(named: "CoverPlaceHolder.jpg"))
            
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
            cell.separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 0)
            cell.layoutMargins = UIEdgeInsetsZero
            return cell
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch (indexPath.section) {
        case 0:
            return 30
        case 1:
            return 70
        case 2:
            if self.tracks.count == 0 {
                return 230 + (self.view.bounds.maxY - kHeaderHeight)
            } else if self.tracks.count < 7{
                return 230 + (self.view.bounds.maxY - kHeaderHeight - (CGFloat(tracks.count) * 70))
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
    
}

class FooterTableViewCell: UITableViewCell {
    
    @IBOutlet weak var footerPlaceholder: UIImageView!
    @IBOutlet weak var footerLabel: UILabel!
    
}

