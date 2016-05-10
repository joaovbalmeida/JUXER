//
//  PlaylistCollectionViewController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 06/05/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit
import SCLAlertView
import Kingfisher
import SwiftDate

class PlaylistCollectionViewController: UICollectionViewController {
    
    let sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Configure Actitivity Indicator
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.frame = CGRect(x: self.view.bounds.maxX/2 - 10, y: self.collectionView!.bounds.midY - 10, width: 20, height: 20)
        self.collectionView!.addSubview(activityIndicator)
        
        activityIndicator.startAnimating()
        
        session = SessionDAO.fetchSession()
        getPlaylists()
    }

    private func getPlaylists(){
        
        //Configure Alert View
        let appearance = SCLAlertView.SCLAppearance(showCloseButton: false)
        let alertView = SCLAlertView(appearance: appearance)
        
        //Erase previous Data
        if self.playlists.count != 0 {
            playlists.removeAll()
        }
        
        let url = NSURL(string: "http://juxer.club/api/playlist/?available=\(session[0].id!)")
        let request = NSMutableURLRequest(URL: url!)
        
        request.HTTPMethod = "GET"
        request.setValue("JWT \(session[0].token!)", forHTTPHeaderField: "Authorization")
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            if error != nil {
                print(error)
                dispatch_async(dispatch_get_main_queue()){
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
                                
                                self.playlists.append(newPlaylist)
                            }
                            
                        }
                        
                        //Refresh TableView
                        dispatch_async(dispatch_get_main_queue()){
                            self.activityIndicator.stopAnimating()
                            self.collectionView!.reloadData()
                        }
                        
                    } catch let error as NSError {
                        print(error)
                        dispatch_async(dispatch_get_main_queue()){
                            alertView.addButton("OK"){
                                self.dismissViewControllerAnimated(true, completion: nil)
                            }
                            alertView.showError("Erro", subTitle: "Não foi possivel obter as Playlists!", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                        }
                    }
                } else {
                    print(httpResponse.statusCode)
                    dispatch_async(dispatch_get_main_queue()){
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

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return playlists.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell: PlaylistCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("playlist", forIndexPath: indexPath) as! PlaylistCollectionViewCell

        if playlists[indexPath.row].cover != "" {
            cell.playlistCover.kf_setImageWithURL(NSURL(string: playlists[indexPath.row].cover)!)
        }
        cell.playlistName.text = playlists[indexPath.row].name
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView!,
                        layout collectionViewLayout: UICollectionViewLayout!,
                               sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {
    return CGSize(width: self.view.frame.width - 100, height: self.collectionView!.frame.height - 100)
    }
    
    func collectionView(collectionView: UICollectionView!,
                        layout collectionViewLayout: UICollectionViewLayout!,
                               insetForSectionAtIndex section: Int) -> UIEdgeInsets {
    return sectionInsets
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

}

class PlaylistCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var playlistCover: UIImageView!
    @IBOutlet weak var playlistName: UILabel!
    
}
