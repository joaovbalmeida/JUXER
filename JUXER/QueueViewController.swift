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

    @IBAction func unwindToVC(segue: UIStoryboardSegue) {
        juxerButton.hidden = false
        juxerLabel.hidden = false
    }
    @IBAction func refresh(sender: AnyObject) {
        getQueue()
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var juxerButton: UIButton!
    @IBOutlet weak var juxerLabel: UILabel!
    
    @IBOutlet weak var albumBG: UIImageView!
    @IBOutlet weak var albumtImage: UIImageView!
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var songScrollingLabel: UILabel!
    @IBOutlet weak var artistScrollingLabel: UILabel!
    
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var placeholderIcon: UIImageView!
    @IBOutlet weak var placeholderLabel: UILabel!

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
        
        tableView.tableHeaderView = nil
        tableView.addSubview(headerView)
        
        tableView.contentInset = UIEdgeInsets(top: kHeaderHeight, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -kHeaderHeight)

        tableView.allowsSelection = false
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        juxerLabel.hidden = true
        juxerButton.hidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        juxerButton.hidden = false
        juxerLabel.hidden = false
        updateHeaderView()
    }

    func updateHeaderView() {
        var buttonRect = CGRect(x: view.bounds.midX - 76, y: -tableView.contentOffset.y - 15, width: 152, height: 35)
        var headerRect = CGRect(x: 0, y: -kHeaderHeight, width: view.bounds.width , height: kHeaderHeight)
        if tableView.contentOffset.y <= -120 {
            headerRect.size.height = -tableView.contentOffset.y
            headerRect.origin.y = tableView.contentOffset.y
            buttonRect.origin.y = -tableView.contentOffset.y - 15
        } else if tableView.contentOffset.y > -120 {
            headerRect.size.height = 120
            headerRect.origin.y = tableView.contentOffset.y
            buttonRect.origin.y = 105
        }
        juxerLabel.frame = buttonRect
        juxerButton.frame = buttonRect
        headerView.frame = headerRect
    }
    
    func updateFooterView() {
        var FooterRect = CGRect(x: 0, y: 518, width: 600, height: 500)
        dispatch_async(dispatch_get_main_queue()){
            if self.tracks.count == 0 {
                self.placeholderIcon.hidden = false
                self.placeholderLabel.hidden = false
                FooterRect.size.height = 500
            } else if self.tracks.count == 1 {
                self.placeholderIcon.hidden = true
                self.placeholderLabel.hidden = true
                FooterRect.size.height = 430
            } else if self.tracks.count == 2 {
                self.placeholderIcon.hidden = true
                self.placeholderLabel.hidden = true
                FooterRect.size.height = 360
            } else if self.tracks.count == 3 {
                self.placeholderIcon.hidden = true
                self.placeholderLabel.hidden = true
                FooterRect.size.height = 290
            } else if self.tracks.count == 4 {
                self.placeholderIcon.hidden = true
                self.placeholderLabel.hidden = true
                FooterRect.size.height = 220
            } else if self.tracks.count == 5 {
                self.placeholderIcon.hidden = true
                self.placeholderLabel.hidden = true
                FooterRect.size.height = 150
            } else {
                self.placeholderIcon.hidden = true
                self.placeholderLabel.hidden = true
                FooterRect.size.height = 80
            }
        }
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
                    let index = resultJSON.valueForKey("index")! as! Int
                    
                    //Refresh Now Playing Track
                    dispatch_async(dispatch_get_main_queue()) {
                        self.songLabel.text = JSON[index].valueForKey("title_short") as? String
                        self.artistLabel.text = JSON[index].valueForKey("artist")!.valueForKey("name") as? String
                        self.albumtImage.kf_setImageWithURL(NSURL(string: String(JSON[index].valueForKey("album")!.valueForKey("cover_big")!))!, placeholderImage: Image(named: "BigCoverPlaceHolder.png"))
                        self.albumBG.kf_setImageWithURL(NSURL(string: String(JSON[index].valueForKey("album")!.valueForKey("cover_big")!))!)
                        self.songScrollingLabel.text = self.songLabel.text
                        self.artistScrollingLabel.text = self.artistLabel.text
                    }
                    
                    //Create tracks struct array from JSON
                    if JSON.count > index {
                        for i in index + 1..<JSON.count {
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
                    
                    self.updateFooterView()

                } catch let error as NSError {
                    print(error)
                }
            }
        }
        task.resume()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0:
            return 1
        case 1:
            return tracks.count
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
        default:
            return 70
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

    QUEUE CELL CLASS

*/

class QueueTableViewCell: UITableViewCell {

    @IBOutlet weak var trackOrder: UILabel!
    @IBOutlet weak var trackTitle: UILabel!
    @IBOutlet weak var trackArtist: UILabel!
    @IBOutlet weak var trackCover: UIImageView!
    
}

