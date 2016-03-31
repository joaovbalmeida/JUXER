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
    @IBOutlet weak var welcomeText2: UILabel!
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
            welcomeText2.hidden = true
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
    
    private func storeSessionToken(userToken: String){
        session = SessionDAO.fetchSession()
        session[0].token = userToken
        SessionDAO.update(session[0])
    }
    
    private func saveAndSubmitToServer(name: NSString, email: NSString, lastName: NSString, firstName: NSString, id: NSString, pictureUrl: String)
    {
        let user = User()
        user.name = "\(name)"
        user.pictureUrl = "\(pictureUrl)"
        user.id = "\(id)"
        user.lastName = "\(lastName)"
        user.firstName = "\(firstName)"
        user.email = "\(email)"
        user.anonymous = 0
        UserDAO.insert(user)
        
        let jsonObject: [String : AnyObject] =
            [ "email": "\(email)",
              "first_name": "\(firstName)",
              "last_name": "\(lastName)",
              "username": "\(email)",
              "picture": "\(pictureUrl)",
              "fb_id": "\(id)" ]
        
        if NSJSONSerialization.isValidJSONObject(jsonObject) {
            
            do {
                
                let JSON = try NSJSONSerialization.dataWithJSONObject(jsonObject, options: [])
                
                // create post request
                
                let url = NSURL(string: "http://10.0.0.68:3000/api/user/login/")
                //let url = NSURL(string: "http://198.211.98.86/api/user/login/")
                let request = NSMutableURLRequest(URL: url!)
                request.HTTPMethod = "POST"
                
                // insert json data to the request
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                request.HTTPBody = JSON
                
                let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
                    if error != nil{
                        print(error)
                        return
                    }
                    let resultData = NSString(data: data!, encoding: NSUTF8StringEncoding)
                    print(resultData!)
                }
                task.resume()
            } catch {
                print(error)
            }
        }
    }
    
    private func getFBUser(){
        
        if((FBSDKAccessToken.currentAccessToken()) != nil)
        {
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "email, name, first_name, last_name, id"]).startWithCompletionHandler({ (connection, result, error) -> Void in
                
                if (error == nil)
                {
                    let userName: NSString = result.valueForKey("name") as! NSString
                    let userEmail:  NSString = result.valueForKey("email") as! NSString
                    let userFirstName: NSString = result.valueForKey("first_name") as! NSString
                    let userLastName: NSString = result.valueForKey("last_name") as! NSString
                    let userId: NSString = result.valueForKey("id") as! NSString
                    let userPictureUrl: String = "https://graph.facebook.com/\(userId)/picture?type=large"
                    
                    self.saveAndSubmitToServer(userName, email: userEmail, lastName: userLastName, firstName: userFirstName, id: userId, pictureUrl: userPictureUrl)
                    
                    let url = NSURL(string: userPictureUrl)
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
