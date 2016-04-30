//
//  HostViewController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 24/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit
import Kingfisher
import SwiftDate

class HostViewController: UIViewController {

    @IBOutlet weak var eventImage: UIImageView!

    @IBOutlet weak var eventDate: UILabel!
    @IBOutlet weak var aboutLabel: UILabel!
    @IBOutlet weak var dataLabel: UILabel!
    @IBOutlet weak var eventDescription: UITextView!
    @IBOutlet weak var eventBG: UIImageView!
    @IBOutlet weak var eventName: UILabel!
    
    @IBOutlet weak var scanLabel: UILabel!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var iconImage: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var session = [Session]()
        session = SessionDAO.fetchSession()
        
        if session[0].active == 1 {
            getEvent(session)
        } else {
            dataLabel.hidden = true
            aboutLabel.hidden = true
            scanLabel.hidden = false
            scanButton.hidden = false
            iconImage.hidden = false
            instructionLabel.hidden = false
        }
    }
    
    private func getEvent(session: [Session]){
        
        let url = NSURL(string: "http://198.211.98.86/api/event/\(session[0].id!)/")
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
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.eventBG.kf_setImageWithURL(NSURL(string: resultJSON.valueForKey("picture")! as! String)!)
                        self.eventImage.kf_setImageWithURL(NSURL(string: resultJSON.valueForKey("picture")! as! String)!)
                        self.eventName.text = resultJSON.valueForKey("name")! as? String
                        self.eventDescription.text = resultJSON.valueForKey("description")! as? String
            
                        if let dateString = resultJSON.valueForKey("starts_at") as? String {
                            let startDate = dateString.toDateFromISO8601()!
                            self.eventDate.text = NSDateFormatter.localizedStringFromDate(startDate, dateStyle: .ShortStyle, timeStyle: .ShortStyle)
                        }
                        
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
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
