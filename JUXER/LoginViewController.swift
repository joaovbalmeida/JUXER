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

class LoginViewController: UIViewController, UIPageViewControllerDataSource  {

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var welcomeText: UILabel!
    @IBOutlet weak var welcomeText2: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBAction func loginButtonPressed(sender: AnyObject) {
        
        let fbLoginManager : FBSDKLoginManager = FBSDKLoginManager()
        
        fbLoginManager.logInWithReadPermissions(["public_profile", "email", "user_friends"], fromViewController: self) { (result, error) in
            
            if error != nil
            {
                print(error.localizedDescription)
            }
            else if result.isCancelled
            {
                print(result.description)
            }
            else
            {
                self.loginButton.hidden = true
                self.getFBUser()
                self.performSegueWithIdentifier("getEvent", sender: self)
            }
        }
    }
    
    var pageViewController: UIPageViewController!
    var pageLabels: NSArray!
    var pageImages: NSArray!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Gradient Background
        let view: UIView = UIView(frame: CGRectMake(0, 0, self.view.frame.width, self.view.frame.height))
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [UIColor.init(red: 191/255, green: 0/255, blue: 96/255, alpha: 1).CGColor, UIColor.init(red: 93/255, green: 0/255, blue: 94/255, alpha: 1).CGColor]
        view.layer.insertSublayer(gradient, atIndex: 0)
        self.view.layer.insertSublayer(view.layer, atIndex: 0)
        
        //Assing Page Objects
        self.pageLabels = NSArray(objects: "Deixe seu evento mais animado!", "Escaneie o código do evento.", "Escolha uma música entre as disponíveis nas playlists.", "Aproveite as músicas escolhidas por outras pessoas enquanto a sua está na fila!")
        self.pageImages = NSArray(objects: "JukeboxIcon", "BarcodeIcon", "IdeiaIcon", "DancingIcon")
        
        //Configure PageViewController
        self.pageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("PageViewController") as! UIPageViewController
        self.pageViewController.dataSource = self
        
        let startVC = self.viewControllerAtIndex(0) as ContentViewController
        let viewControllers = NSArray(object: startVC)
        
        self.pageViewController.setViewControllers(viewControllers as? [UIViewController], direction: .Forward, animated: true, completion: nil)
        
        self.pageViewController.view.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
        
        //Add PageViewController
        self.addChildViewController(self.pageViewController)
        self.view.addSubview(self.pageViewController.view)
        self.pageViewController.didMoveToParentViewController(self)
        
        //Bring Login Button to front
        self.view.bringSubviewToFront(loginButton)
        
    }

    private func storeSessionToken(userToken: String){
        let session = Session()
        session.token = userToken
        SessionDAO.insert(session)
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
                let url = NSURL(string: "http://198.211.98.86/api/user/login/")
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
                    var resultData = NSString(data: data!, encoding: NSUTF8StringEncoding)!
                    resultData = resultData.stringByReplacingOccurrencesOfString("\"", withString: "")
                    self.storeSessionToken(String(resultData))
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
                    let request = NSURLRequest(URL: url!)
                    let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
                        
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
                    task.resume()
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

    // MARK: - Page View Methods
    
    func viewControllerAtIndex(index: Int) -> ContentViewController {
        
        if (self.pageLabels.count == 0) || (index >= self.pageLabels.count) {
            return ContentViewController()
        }
        let viewController: ContentViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ContentViewController") as! ContentViewController
 
        viewController.pageLabel = self.pageLabels[index] as! String
        viewController.pageIndex = index
        viewController.pageIcon = self.pageImages[index] as! String
        
        return viewController
        
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        let viewController = viewController as! ContentViewController
        var index = viewController.pageIndex as Int
        
        if index == NSNotFound {
            return nil
        }
        
        index += 1
        
        if index == self.pageLabels.count {
            return nil
        }
        
        return self.viewControllerAtIndex(index)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        let viewController = viewController as! ContentViewController
        var index = viewController.pageIndex as Int
        
        if index == 0 || index == NSNotFound {
            return nil
        }
        
        index -= 1
        return self.viewControllerAtIndex(index)
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 4
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    
}
