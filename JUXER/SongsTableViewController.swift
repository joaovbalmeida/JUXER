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
    
    var activityIndicator: UIActivityIndicatorView!
    var overlay: UIView!
    var alertView = SCLAlertView()
    
    private struct Song {
        var title: String
        var artist: String
        var cover: String
        var id: Int
        
        init (title: String, artist: String, cover: String, id: Int){
            self.title = ""
            self.artist = ""
            self.cover = ""
            self.id = 0
        }
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
        
        session = SessionDAO.fetchSession()
        getSongs()
    
    }
    
    private func getSongs(){
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
                            self.JSONErrorAlert()
                        }
                    }
                } else {
                    print(httpResponse.statusCode)
                    dispatch_async(dispatch_get_main_queue()){
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
                        //Wrap songs in struct
                        if songsData.count != 0 {
                            for item in songsData {
                                var newSong = Song(title: "", artist: "", cover: "",id: 0)
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
                                    if let cover = item.valueForKey("album")!.valueForKey("cover_medium") as? String{
                                        newSong.cover = cover
                                    }
                                    self.songs.append(newSong)
                                }
                            }
                        }
                        dispatch_async(dispatch_get_main_queue()){
                            self.activityIndicator.stopAnimating()
                            self.tableView.reloadData()
                        }
                        
                    } catch let error as NSError {
                        print(error)
                        dispatch_async(dispatch_get_main_queue()){
                            self.JSONErrorAlert()
                        }     
                    }
                } else {
                    print(httpResponse.statusCode)
                    dispatch_async(dispatch_get_main_queue()){
                        self.connectionErrorAlert()
                    }
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
        
        if self.songs[indexPath.row].cover != "" {
            cell.songCover.kf_setImageWithURL(NSURL(string: self.songs[indexPath.row].cover)!,placeholderImage: Image(named: "CoverPlaceHolder.jpg"))
        }
        cell.songTitleLabel.text = self.songs[indexPath.row].title
        cell.songArtistLabel.text = self.songs[indexPath.row].artist
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        dispatch_async(dispatch_get_main_queue()){
           self.startLoadOverlay()
        }
        
        var alertView = SCLAlertView()
        
        let jsonObject: [String : AnyObject] =
            [ "id": self.songs[indexPath.row].id ]
       
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
                            
                            dispatch_async(dispatch_get_main_queue()){
                                let appearance = SCLAlertView.SCLAppearance(showCloseButton: false)
                                alertView = SCLAlertView(appearance: appearance)
                                alertView.addButton("OK"){
                                    self.dismissViewControllerAnimated(true, completion: {})
                                }
                                alertView.showSuccess("Obrigado!", subTitle: "Seu pedido entrará na fila em breve!", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                            }
                
                        } else if httpResponse.statusCode == 422 {
                        
                            if string == "\"Track already on queue\"" {
                                dispatch_async(dispatch_get_main_queue()){
                                    self.stopLoadOverlay()
                                    alertView.showError("Ops", subTitle: "A música pedida já está na fila!", closeButtonTitle: "OK", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                                }
                            } else if string == "\"User has already reached song request limit\"" {
                                dispatch_async(dispatch_get_main_queue()){
                                    self.stopLoadOverlay()
                                    alertView.showError("Limite Atingido", subTitle: "Você atingiu o limite de músicas do evento, espere seus pedidos pendentes acabarem e tente novamente!", closeButtonTitle: "OK", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                                }
                            } else if string == "\"Unavailable track\"" {
                                dispatch_async(dispatch_get_main_queue()){
                                    self.stopLoadOverlay()
                                    alertView.showError("Limite Antigido", subTitle: "O tempo limite de músicas dessa playlist foi atingido!", closeButtonTitle: "OK", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                                }
                            } else {
                                dispatch_async(dispatch_get_main_queue()){
                                    self.stopLoadOverlay()
                                    alertView.showError("Ops", subTitle: "Não foi possivel pedir essa música!", closeButtonTitle: "OK", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                                }
                            }
                        } else {
                            dispatch_async(dispatch_get_main_queue()){
                                self.stopLoadOverlay()
                                alertView.showError("Erro", subTitle: "Ocorreu um erro ao fazer o pedido, tente novamente!", closeButtonTitle: "OK", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
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
        self.alertView.showError("Erro de Conexão", subTitle: "Não foi possivel conectar ao servidor!", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
    }
    
    private func JSONErrorAlert(){
        self.alertView.addButton("OK"){
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        self.alertView.showError("Ocorreu um Erro", subTitle: "Não foi possivel obter as Músicas!", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
    }
    
    private func startLoadOverlay(){
        self.tableView.userInteractionEnabled = false
        self.overlay = UIView(frame: CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height))
        self.overlay.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        self.activityIndicator.startAnimating()
        self.view.addSubview(self.overlay)
        self.view.bringSubviewToFront(self.activityIndicator)
    }
    
    private func stopLoadOverlay(){
        self.activityIndicator.stopAnimating()
        self.overlay.removeFromSuperview()
        self.tableView.userInteractionEnabled = true
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


