//
//  LoginViewController.swift
//  Juxer
//
//  Created by Joao Victor Almeida on 02/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import SCLAlertView
import GoogleSignIn
import Google
import SafariServices

class LoginViewController: UIViewController, UIPageViewControllerDataSource, GIDSignInDelegate, GIDSignInUIDelegate, UITextViewDelegate, SFSafariViewControllerDelegate {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var welcomeText2: UILabel!
    @IBOutlet weak var ggLoginButton: UIButton!
    @IBOutlet weak var fbLoginButton: UIButton!
    @IBOutlet weak var terms: UITextView!
    
    @IBAction func ggLoginButtonPressed(sender: AnyObject) {
        
        // Initialize sign-in
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        
        
        if configureError != nil {
            print(configureError.debugDescription)
        }else {
            GIDSignIn.sharedInstance().shouldFetchBasicProfile = true
            GIDSignIn.sharedInstance().delegate = self
            GIDSignIn.sharedInstance().uiDelegate = self
            GIDSignIn.sharedInstance().signIn()
        }
    }
    
    @IBAction func fbLoginButtonPressed(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue()){
            self.startLoadOverlay()
        }
        
        let fbLoginManager : FBSDKLoginManager = FBSDKLoginManager()
        
        fbLoginManager.logInWithReadPermissions(["public_profile", "email", "user_friends"], fromViewController: self) { (result, error) in
            
            if error != nil
            {
                print(error.localizedDescription)
                dispatch_async(dispatch_get_main_queue()){
                    self.stopLoadOverlay()
                    SCLAlertView().showError("Error".localized, subTitle: "Unable to Login. Please, try again!".localized, closeButtonTitle: "OK", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                }
            }
            else if result.isCancelled
            {
                dispatch_async(dispatch_get_main_queue()){
                    self.stopLoadOverlay()
                }
                print(result.debugDescription)
            }
            else
            {
                self.saveAndSubmitFBUser()
            }
        }
    }

    var overlay: UIView!
    var pageViewController: UIPageViewController!
    var pageLabels: NSArray!
    var pageImages: NSArray!
    let termsAndConditionsURL = "http://www.juxer.club";
    let privacyURL = "http://www.juxer.club";
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance().uiDelegate = self
        
        //Gradient Background
        let view: UIView = UIView(frame: CGRectMake(0, 0, self.view.frame.width, self.view.frame.height))
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [UIColor.init(red: 191/255, green: 0/255, blue: 96/255, alpha: 1).CGColor, UIColor.init(red: 93/255, green: 0/255, blue: 94/255, alpha: 1).CGColor]
        view.layer.insertSublayer(gradient, atIndex: 0)
        self.view.layer.insertSublayer(view.layer, atIndex: 0)
        
        //Assing Page Objects
        self.pageLabels = NSArray(objects: "Experience a new way of music interaction in your events!".localized , "After logging in scan the event QR Code.".localized , "Order songs from the event availables playlists.".localized , "Enjoy the songs chosen by others while yours is in the queue!".localized)
        self.pageImages = NSArray(objects: "JukeboxIcon", "BarcodeIcon", "IdeiaIcon", "DancingIcon")
        
        //Configure PageViewController
        self.pageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("PageViewController") as! UIPageViewController
        self.pageViewController.dataSource = self
        let startVC = self.viewControllerAtIndex(0) as ContentViewController
        let viewControllers = NSArray(object: startVC)
        self.pageViewController.setViewControllers(viewControllers as? [UIViewController], direction: .Forward, animated: true, completion: nil)
        self.pageViewController.view.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height *  6/7)
        
        //Add PageViewController
        self.addChildViewController(self.pageViewController)
        self.view.addSubview(self.pageViewController.view)
        self.pageViewController.didMoveToParentViewController(self)
        
        //Links for Terms of User
        configureTerms()
        
        //Bring Login Button to front
        self.view.bringSubviewToFront(fbLoginButton)
        self.view.bringSubviewToFront(ggLoginButton)
        
    }
    
    private func saveAndSubmitFBUser(){
        
        if((FBSDKAccessToken.currentAccessToken()) != nil)
        {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "email, name, first_name, last_name, id"]).startWithCompletionHandler({ (connection, result, error) -> Void in
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if error == nil && result != nil
                {
                    let userName: NSString = result.valueForKey("name") as! NSString
                    let userEmail:  NSString = result.valueForKey("email") as! NSString
                    let userFirstName: NSString = result.valueForKey("first_name") as! NSString
                    let userLastName: NSString = result.valueForKey("last_name") as! NSString
                    let userId: NSString = result.valueForKey("id") as! NSString
                    let userPictureUrl: String = "https://graph.facebook.com/\(userId)/picture?type=large"
                    
                    let user = User()
                    user.name = "\(userName)"
                    user.pictureUrl = "\(userPictureUrl)"
                    user.id = "\(userId)"
                    user.lastName = "\(userLastName)"
                    user.firstName = "\(userFirstName)"
                    user.email = "\(userEmail)"
                    user.anonymous = 0
                    
                    let jsonObject: [String : AnyObject] =
                        [ "email": "\(userEmail)",
                            "first_name": "\(userFirstName)",
                            "last_name": "\(userLastName)",
                            "username": "\(userEmail)",
                            "picture": "\(userPictureUrl)",
                            "fb_id": "\(userId)" ]
                    
                    if NSJSONSerialization.isValidJSONObject(jsonObject) {
                        
                        do {
                            
                            let JSON = try NSJSONSerialization.dataWithJSONObject(jsonObject, options: [])
                            
                            // create post request
                            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                            let request = NSMutableURLRequest(URL: NSURL(string: "http://juxer.club/api/user/login/")!)
                            request.HTTPMethod = "POST"
                            
                            // insert json data to the request
                            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                            request.HTTPBody = JSON
                            
                            let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
                                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                                
                                if error != nil{
                                    print(error)
                                    self.logOut()
                                    dispatch_async(dispatch_get_main_queue()){
                                        self.stopLoadOverlay()
                                        self.showConectionErrorAlert()
                                    }
                                } else {
                                    let httpResponse = response as! NSHTTPURLResponse
                                    if httpResponse.statusCode == 200 {
                                        UserDAO.insert(user)
                                        var resultData = NSString(data: data!, encoding: NSUTF8StringEncoding)!
                                        resultData = resultData.stringByReplacingOccurrencesOfString("\"", withString: "")
                                        self.storeSessionToken(String(resultData))
                                        self.getProfilePictureAndSegue(userPictureUrl)
                                        
                                    } else {
                                        self.logOut()
                                        dispatch_async(dispatch_get_main_queue()){
                                            self.stopLoadOverlay()
                                            self.showErrorAlert()
                                        }
                                    }
                                }
                            }
                            task.resume()
                        } catch {
                            print(error)
                            self.logOut()
                            dispatch_async(dispatch_get_main_queue()){
                                self.stopLoadOverlay()
                                self.showErrorAlert()
                            }
                        }
                    }
                } else {
                    print(error)
                    self.logOut()
                    dispatch_async(dispatch_get_main_queue()){
                        self.stopLoadOverlay()
                        self.showErrorAlert()
                    }
                }
            })
        }
    }
    
    func getProfilePictureAndSegue(url: String){
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let url = NSURL(string: url)
        let request = NSURLRequest(URL: url!)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if error != nil {
                print(error)
                self.deleteUser()
                self.logOut()
                dispatch_async(dispatch_get_main_queue()){
                    self.stopLoadOverlay()
                    self.showConectionErrorAlert()
                }
            } else {
                let httpResponse = response as! NSHTTPURLResponse
                if httpResponse.statusCode == 200 {
                    let documentsDirectory:String?
                    var path:[AnyObject] = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
                    
                    if path.count > 0 {
                        documentsDirectory = path[0] as? String
                        let savePath = documentsDirectory! + "/profilePic.jpg"
                        NSFileManager.defaultManager().createFileAtPath(savePath, contents: data, attributes: nil)
                        dispatch_async(dispatch_get_main_queue()){
                            self.performSegueWithIdentifier("toHome", sender: self)
                        }
                    }
                } else {
                    self.deleteUser()
                    self.logOut()
                    dispatch_async(dispatch_get_main_queue()){
                        self.stopLoadOverlay()
                        self.showErrorAlert()
                    }
                }
            }
        })
        task.resume()
    }
    
    func showErrorAlert(){
        SCLAlertView().showError("Error".localized, subTitle: "Unable to Login ,please try again!".localized, closeButtonTitle: "OK", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
    }
    
    func showConectionErrorAlert(){
        SCLAlertView().showError("Connection Error".localized, subTitle: "Unable to reach server, please try again!".localized, closeButtonTitle: "OK", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
    }
    
    private func storeSessionToken(userToken: String){
        let session = Session()
        session.token = userToken
        SessionDAO.insert(session)
    }
    
    func startLoadOverlay(){
        overlay = UIView(frame: CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height))
        overlay.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        self.activityIndicator.startAnimating()
        self.view.addSubview(self.overlay)
        self.view.bringSubviewToFront(self.activityIndicator)
        self.fbLoginButton.userInteractionEnabled = false
        self.ggLoginButton.userInteractionEnabled = false
    }
    
    func stopLoadOverlay(){
        self.activityIndicator.stopAnimating()
        self.overlay.removeFromSuperview()
        self.fbLoginButton.userInteractionEnabled = true
        self.ggLoginButton.userInteractionEnabled = true
    }
    
    private func deleteUser(){
        if let user:[User] = UserDAO.fetchUser() {
            UserDAO.delete(user[0])
        }
    }
    
    private func logOut(){
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        GIDSignIn.sharedInstance().signOut()
    }
    
    // MARK: - Configure Links in for Terms of Use
    
    func configureTerms() {
        self.terms.delegate = self
        let str = "By using this app you agree to our Terms and Conditions and Privacy Policy".localized
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.Center
        let attributedString = NSMutableAttributedString(string: str,
            attributes: [NSFontAttributeName:
                UIFont.systemFontOfSize(10, weight: UIFontWeightLight), NSForegroundColorAttributeName: UIColor.whiteColor(), NSParagraphStyleAttributeName: paragraphStyle])
        
        //Add Attributes
        var foundRange = attributedString.mutableString.rangeOfString("Terms and Conditions".localized)
        attributedString.addAttribute(NSLinkAttributeName, value: termsAndConditionsURL, range: foundRange)
        attributedString.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(10, weight: UIFontWeightSemibold), range: foundRange)
        foundRange = attributedString.mutableString.rangeOfString("Privacy Policy".localized)
        attributedString.addAttribute(NSLinkAttributeName, value: privacyURL, range: foundRange)
        attributedString.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(10, weight: UIFontWeightSemibold), range: foundRange)
        
        terms.attributedText = attributedString
        self.view.bringSubviewToFront(terms)
    }
    
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        let svc: SFSafariViewController = SFSafariViewController(URL: URL)
        svc.delegate = self
        if (URL.absoluteString == termsAndConditionsURL) {
            presentViewController(svc, animated: true , completion: nil)
        } else if (URL.absoluteString == privacyURL) {
            presentViewController(svc, animated: true , completion: nil)
        }
        return false
    }
    
    // MARK: - Google Sign In Delegate
    
    func signIn(signIn: GIDSignIn!, dismissViewController viewController: UIViewController!) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func signIn(signIn: GIDSignIn!, presentViewController viewController: UIViewController!) {
        viewController.modalTransitionStyle = .CoverVertical
        self.presentViewController(viewController, animated: true, completion: nil)
    }
    
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError!) {
        if (error == nil) {
            self.startLoadOverlay()
            
            let juxerUser = User()
            juxerUser.id = "\(user.userID)"
            juxerUser.name = "\(user.profile.name)"
            juxerUser.firstName = "\(user.profile.givenName)"
            juxerUser.lastName = "\(user.profile.familyName)"
            juxerUser.email = "\(user.profile.email)"
            juxerUser.pictureUrl = "\(user.profile.imageURLWithDimension(150).absoluteString)"
            juxerUser.anonymous = 0

            let jsonObject: [String : AnyObject] =
                [ "email": "\(user.profile.email)",
                  "first_name": "\(user.profile.givenName)",
                  "last_name": "\(user.profile.familyName)",
                  "username": "\(user.profile.email)",
                  "picture": "\(user.profile.imageURLWithDimension(150).absoluteString)",
                  "fb_id": "\(user.userID)" ]
            
            if NSJSONSerialization.isValidJSONObject(jsonObject) {
                
                do {
                    
                    let JSON = try NSJSONSerialization.dataWithJSONObject(jsonObject, options: [])
                    
                    // create post request
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                    let request = NSMutableURLRequest(URL: NSURL(string: "http://juxer.club/api/user/login/")!)
                    request.HTTPMethod = "POST"
                    
                    // insert json data to the request
                    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                    request.HTTPBody = JSON
                    
                    let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        
                        if error != nil{
                            print(error)
                            GIDSignIn.sharedInstance().signOut()
                            dispatch_async(dispatch_get_main_queue()){
                                self.stopLoadOverlay()
                                self.showConectionErrorAlert()
                            }
                        } else {
                            let httpResponse = response as! NSHTTPURLResponse
                            if httpResponse.statusCode == 200 {
                                UserDAO.insert(juxerUser)
                                var resultData = NSString(data: data!, encoding: NSUTF8StringEncoding)!
                                resultData = resultData.stringByReplacingOccurrencesOfString("\"", withString: "")
                                self.storeSessionToken(String(resultData))
                                if user.profile.hasImage {
                                    self.getProfilePictureAndSegue(juxerUser.pictureUrl!)
                                } else {
                                    dispatch_async(dispatch_get_main_queue()){
                                        self.performSegueWithIdentifier("toHome", sender: self)
                                    }
                                }
                                
                            } else {
                                GIDSignIn.sharedInstance().signOut()
                                dispatch_async(dispatch_get_main_queue()){
                                    self.stopLoadOverlay()
                                    self.showErrorAlert()
                                }
                            }
                        }
                    }
                    task.resume()
                } catch {
                    print(error)
                    GIDSignIn.sharedInstance().signOut()
                    dispatch_async(dispatch_get_main_queue()){
                        self.stopLoadOverlay()
                        self.showErrorAlert()
                    }
                }
            }
            
        } else {
            print("\(error.localizedDescription)")
        }
    }
    
    func signIn(signIn: GIDSignIn!, didDisconnectWithUser user: GIDGoogleUser!, withError error: NSError!) {
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
