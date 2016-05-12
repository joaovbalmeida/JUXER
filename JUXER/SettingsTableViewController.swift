//
//  SettingsTableViewController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 09/05/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit
import Kingfisher
import SCLAlertView

class SettingsTableViewController: UITableViewController {

    @IBOutlet weak var anonymousSwitch: UISwitch!
    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var username: UILabel!
    
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
        
        
        //Load Profile Picture
        let paths:[AnyObject] = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        if paths.count > 0
        {
            if let dirPath = paths[0] as? String
            {
                let readPath = dirPath + "/profilePic.jpg"
                let image = UIImage(contentsOfFile: readPath)
                bgImage.image = image
                if image != nil {
                    profilePic.image = maskRoundedImage(image!)
                } else {
                    profilePic.image = maskRoundedImage(UIImage(named: "ProfilePlaceholder")!)
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == 1 && indexPath.row == 0 {
            let alertView = SCLAlertView()
            alertView.addButton("Sim"){
                
                // Delete Profile
                UserDAO.delete(self.user[0])
                
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
                
                //Delete Session
                var session: [Session] = [Session]()
                session = SessionDAO.fetchSession()
                SessionDAO.delete(session[0])
                
                //Segue to Login View
                self.performSegueWithIdentifier("toLogin", sender: self)
                
            }
            alertView.showWarning("Log Out?", subTitle: "Voce será desconectado do evento!", closeButtonTitle: "Não", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// TABLECELL CLASS

class LogoutTableViewCell: UITableViewCell {
    
    @IBInspectable var selectionColor: UIColor = UIColor.blackColor() {
        didSet {
            configureSelectedBackgroundView()
        }
    }
    
    func configureSelectedBackgroundView() {
        let view = UIView()
        view.backgroundColor = selectionColor
        selectedBackgroundView = view
    }
    
}
