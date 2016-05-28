//
//  LoadViewController.swift
//  Juxer
//
//  Created by Joao Victor Almeida on 27/05/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit
import Google
import FBSDKCoreKit
import FBSDKLoginKit

class LoadViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    private var session = [Session]()
    var window: UIWindow?

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func viewDidAppear(animated: Bool) {
        activityIndicator.startAnimating()
        
        //If session active, refresh token and bypass views
        session = SessionDAO.fetchSession()
        if session.count != 0 && session[0].token != nil {
            refreshTokenSucceeded()
        } else {
            goToLoginVC()
        }
    }

    private func goToLoginVC() {
        self.performSegueWithIdentifier("getLogin", sender: self)
    }
    
    private func deleteUserAndSession(){
        SessionDAO.delete(session[0])
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        if let user:[User] = UserDAO.fetchUser() {
            UserDAO.delete(user[0])
        }
    }
    
    private func refreshTokenSucceeded()  {
        
        let jsonObject: [String : AnyObject] =
            [ "token": "\(session[0].token!)"]
        
        if NSJSONSerialization.isValidJSONObject(jsonObject) {
            
            do {
                let JSON = try NSJSONSerialization.dataWithJSONObject(jsonObject, options: [])
                
                // create post request
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                let url = NSURL(string: "http://juxer.club/api-token-refresh/")
                let request = NSMutableURLRequest(URL: url!)
                request.HTTPMethod = "POST"
                
                // insert json data to the request
                request.setValue("JWT \(session[0].token!)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                request.HTTPBody = JSON
                
                let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    if error != nil{
                        print(error)
                        self.deleteUserAndSession()
                        self.goToLoginVC()
                    } else {
                        let httpResponse = response! as! NSHTTPURLResponse
                        if httpResponse.statusCode == 200 {
                            do {
                                let resultJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                                
                                //Update New Token
                                var newToken = resultJSON.valueForKey("token") as! String
                                newToken = newToken.stringByRemovingPercentEncoding!
                                newToken = newToken.stringByReplacingOccurrencesOfString("\"", withString: "")
                                self.session[0].token = newToken
                                SessionDAO.update(self.session[0])
                                
                                //Change Initial View
                                dispatch_async(dispatch_get_main_queue()){
                                    self.performSegueWithIdentifier("bypassLogin", sender: self)
                                }
                                
                            } catch let error as NSError {
                                print(error)
                                self.deleteUserAndSession()
                                self.goToLoginVC()
                            }
                        } else {
                            print(httpResponse.statusCode)
                            self.deleteUserAndSession()
                            self.goToLoginVC()
                        }
                    }
                }
                task.resume()
            } catch {
                print(error)
                self.deleteUserAndSession()
                self.goToLoginVC()
            }
        }
    }
}
