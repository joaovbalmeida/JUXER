//
//  QueueViewController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 25/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit
import FBSDKShareKit

class QueueViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBAction func unwindToVC(segue: UIStoryboardSegue) {
        juxerButton.hidden = false
        juxerLabel.hidden = false
    }
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(QueueViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        
        return refreshControl
    }()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var juxerButton: UIButton!
    @IBOutlet weak var juxerLabel: UILabel!
    
    @IBOutlet weak var albumBG: UIImageView!
    @IBOutlet weak var albumtImage: UIImageView!
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var songScrollingLabel: UILabel!
    @IBOutlet weak var artistScrollingLabel: UILabel!
    
    @IBOutlet weak var headerView: UIView!

    private let kHeaderHeight: CGFloat = 380
    let darkBlur = UIBlurEffect(style: UIBlurEffectStyle.Dark)

    private var count: Int = 0
    private var index: Int = 0
    private var tracks: [Track] = [Track]()
    
    struct Track {
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
        
        getQueue()
        
        headerView = tableView.tableHeaderView
        headerView.clipsToBounds = true
        
        tableView.tableHeaderView = nil
        tableView.addSubview(headerView)
        
        tableView.contentInset = UIEdgeInsets(top: kHeaderHeight, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -kHeaderHeight)

        tableView.allowsSelection = false
        
        refreshControl.tintColor = UIColor.whiteColor()
        refreshControl.bounds.origin.y = 350
        self.tableView.addSubview(refreshControl)
       
    }
    
    override func viewDidDisappear(animated: Bool) {
        juxerLabel.hidden = true
        juxerButton.hidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
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
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        
        getQueue()
        
        tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    private func getQueue(){
        var session = [Session]()
        session = SessionDAO.fetchSession()
        
        let url = NSURL(string: "http://198.211.98.86/api/track/queue/\(session[0].id!)/")
        //let url = NSURL(string: "http://10.0.0.68:3000/api/event/12/")
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
                    let coverSmall: [NSString] = resultJSON.valueForKey("queue")!.valueForKey("album")!.valueForKey("cover_small")! as! [NSString]
                    
                    //Refresh Now Playing Track
                    let cover: [NSString] = resultJSON.valueForKey("queue")!.valueForKey("album")!.valueForKey("cover_big")! as! [NSString]
                    let imageUrl  = NSURL(string: String(cover[self.index]))
                    let imageRequest = NSURLRequest(URL: imageUrl!)
                    let imageTask = NSURLSession.sharedSession().dataTaskWithRequest(imageRequest, completionHandler: { (data, response, error) in
                        if error != nil {
                            print(error)
                        } else {
                            dispatch_async(dispatch_get_main_queue()) {
                                self.albumBG.image = UIImage(data: data!)
                                self.albumtImage.image = UIImage(data: data!)
                                self.songLabel.text = title[self.index] as String
                                self.artistLabel.text = "\(artist[self.index] as String) - \(album[self.index] as String)"
                                self.songScrollingLabel.text = self.songLabel.text
                                self.artistScrollingLabel.text = self.artistLabel.text
                            }
                        }
                    })
                    imageTask.resume()
                    
                    //Return how many tracks
                    self.count = title.count - self.index
                    dispatch_async(dispatch_get_main_queue()){
                        self.tableView.reloadData()
                    }
                    
                    //Pass tracks to Struct
                    for i in self.index ..< title.count {
                        var newTrack = Track(title: "title", artist: "artist", cover: "cover")
                        newTrack.title = title[i] as String
                        newTrack.artist = artist[i] as String
                        newTrack.cover = coverSmall[i] as String
                        self.tracks.append(newTrack)
                    }
                    
                    //Pass Object to Cell
                    let destinationView = QueueTableViewCell()
                    destinationView.tracks = self.tracks
                    
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
            if count != 0 {
                return count - 1
            } else {
                return 0 }
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
            let cell = tableView.dequeueReusableCellWithIdentifier("queue", forIndexPath: indexPath)
            cell.separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 0)
            cell.layoutMargins = UIEdgeInsetsZero
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
    
    var tracks: [QueueViewController.Track] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        
    }

}

