//
//  SettingsViewController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 03/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit

class SettingsViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    
    @IBOutlet weak var anonymousSwitch: UISwitch!
    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var logoutButton: FBSDKLoginButton!
    
    @IBAction func setAnonymous(sender: AnyObject) {
        if anonymousSwitch.on == true {
            user[0].anonymous = 1
        } else {
            user[0].anonymous = 0
        }
        UserDAO.update(user[0])
    }
    
    private var user: [User] = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        user = UserDAO.fetchUser()
        username.text = user[0].name
        
        if user[0].anonymous == 1 {
            anonymousSwitch.on = true
        } else {
            anonymousSwitch.on = false
        }
        
        logoutButton.readPermissions = ["public_profile", "email", "user_friends"]
        logoutButton.delegate = self
        
        let paths:[AnyObject] = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        
        if paths.count > 0
        {
            if let dirPath = paths[0] as? String
            {
                let readPath = dirPath + "/profilePic.jpg"
                let image = UIImage(contentsOfFile: readPath)
                bgImage.image = image
                profilePic.image = maskRoundedImage(image!)
            }
        }
        
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!)
    {
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!)
    {
        deleteFBUserData()
        setSessionInactive()
        performSegueWithIdentifier("toLogin", sender: self)
    }
    
    private func setSessionInactive() {
        var session: [Session] = [Session]()
        session = SessionDAO.fetchSession()
        session[0].active = 0
        SessionDAO.update(session[0])
    }
    
    private func deleteFBUserData() {
        // Erase Profile Name
        UserDAO.delete(user[0])
        
        // Erase Profile Picture
        var documentsDirectory:String?
        if let path:[AnyObject] = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory , NSSearchPathDomainMask.UserDomainMask, true) {
            
            if path.count > 0 {
                documentsDirectory = path[0] as? String
                let filePath = documentsDirectory! + "/profilePic.jpg"
                
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(filePath)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func maskRoundedImage(imageView: UIImage) -> UIImage {
        let imageView = UIImageView(image: imageView)
        imageView.layer.cornerRadius = min(imageView.bounds.size.height/2, imageView.bounds.size.width/2)
        imageView.layer.masksToBounds = true
        
        UIGraphicsBeginImageContext(imageView.bounds.size)
        let context = UIGraphicsGetCurrentContext()
        imageView.layer.renderInContext(context!)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
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
