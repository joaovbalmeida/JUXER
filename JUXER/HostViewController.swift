//
//  HostViewController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 24/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit

class HostViewController: UIViewController {

    @IBOutlet weak var eventImage: UIImageView!
    @IBOutlet weak var eventDescription: UILabel!
    @IBOutlet weak var eventBG: UIImageView!
    @IBOutlet weak var eventName: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getEvent()
    }
    
    private func getEvent(){
        
        var session = [Session]()
        session = SessionDAO.fetchSession()
        
        //let url = NSURL(string: "http://198.211.98.86/api/event/12/")
        let url = NSURL(string: "http://10.0.0.68:3000/api/event/12/")
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
                    dispatch_async(dispatch_get_main_queue(), {
                        self.eventName.text = resultJSON.valueForKey("name")! as? String
                        self.eventDescription.text = resultJSON.valueForKey("description")! as? String

                        var string = resultJSON.valueForKey("picture")! as! String
                        string = string.stringByReplacingOccurrencesOfString("127.0.0.1:8000", withString: "10.0.0.68:3000")
                        let imageUrl  = NSURL(string: string)
                        let imageRequest = NSURLRequest(URL: imageUrl!)
                        let imageTask = NSURLSession.sharedSession().dataTaskWithRequest(imageRequest, completionHandler: { (data, response, error) in
                            if error != nil {
                                print(error)
                            } else {
                                self.eventBG.image = UIImage(data: data!)
                                self.eventImage.image = UIImage(data: data!)
                            }
                        })
                        imageTask.resume()
                    })
     
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
