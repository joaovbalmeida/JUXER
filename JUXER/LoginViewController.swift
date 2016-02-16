//
//  LoginViewController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 02/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate  {

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var welcomeText: UILabel!
    @IBOutlet weak var loginButton: FBSDKLoginButton!
    
    private var session: [Session] = [Session]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.readPermissions = ["public_profile", "email", "user_friends"]
        loginButton.delegate = self
        
        self.createSessionIfInexistent()
        
        if FBSDKAccessToken.currentAccessToken() != nil {
            image.hidden = true
            welcomeText.hidden = true
            loginButton.hidden = true
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        if(FBSDKAccessToken.currentAccessToken() != nil && session[0].active == 1)
        {
            performSegueWithIdentifier("passLogin", sender: self)
        }
        else if (FBSDKAccessToken.currentAccessToken() != nil)
        {
            performSegueWithIdentifier("getSession", sender: self)
        }
    }
    
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!)
    {
        if ((error) != nil)
        {
            print(error.localizedDescription)
        }
        else if result.isCancelled
        {
            print(result.description)
        }
        else
        {
            getFBUser()
            self.performSegueWithIdentifier("getSession", sender: self)
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!)
    {
        
    }
    
    private func createSessionIfInexistent(){
        session = SessionDAO.fetchSession()
        if session.count == 0 {
            let newSession = Session()
            newSession.active = 0
            SessionDAO.insert(newSession)
            session.append(newSession)
        }
    }
    
    private func saveData(name: NSString)
    {
        let user = User()
        user.name = "\(name)"
        UserDAO.insert(user)
    }
    
    private func getFBUser(){
        
        if((FBSDKAccessToken.currentAccessToken()) != nil)
        {
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "name"]).startWithCompletionHandler({ (connection, result, error) -> Void in
                
                if (error == nil)
                {
                    let userName : NSString = result.valueForKey("name") as! NSString
                    self.saveData(userName)
                    
                    let id: NSString = result.valueForKey("id") as! NSString
                    let url = NSURL(string: "https://graph.facebook.com/\(id)/picture?type=large")
                    let session = NSURLSession.sharedSession()
                    let request = NSURLRequest(URL: url!)
                    let dataTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
                        
                        if error != nil {
                            print(error)
                        }
                        else {
                            let documentsDirectory:String?
                            var path:[AnyObject] = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
                            
                            if path.count > 0 {
                                documentsDirectory = path[0] as? String
                                let savePath = documentsDirectory! + "/profilePic.jpg"
                                NSFileManager.defaultManager().createFileAtPath(savePath, contents: data, attributes: nil)
                            }
                        }
                        
                    })
                    dataTask.resume()
                } else {
                    print(error)
                }
            })
        }
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
