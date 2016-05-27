//
//  AppDelegate.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 28/01/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit
import Google
import FBSDKCoreKit
import FBSDKLoginKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var session = [Session]()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
       
        //Facebook Login
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)

        //Custom Navigation Bar
        let navigationBarAppear = UINavigationBar.appearance()
        navigationBarAppear.tintColor = UIColor.init(red: 255/255, green: 0/255, blue: 90/255, alpha: 1)
        navigationBarAppear.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.init(red: 255/255, green: 0/255, blue: 90/255, alpha: 1), NSFontAttributeName: UIFont(name: "Helvetica Neue", size: 18)!]

        //If session active, refresh token and bypass views
        session = SessionDAO.fetchSession()
        if session.count != 0 && session[0].token != nil {
            refreshTokenSucceeded()
        } else {
            goToLoginVC()
        }
        
        //Configure Page Controller
        let pageController = UIPageControl.appearance()
        pageController.pageIndicatorTintColor = UIColor.lightGrayColor()
        pageController.currentPageIndicatorTintColor = UIColor.whiteColor()
        pageController.backgroundColor = UIColor.clearColor()
        pageController.bounds.origin.y += 120
        
        return true
    }
    
    private func goToLoginVC() {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        window?.rootViewController = storyboard.instantiateViewControllerWithIdentifier("LoginVC")
        window?.makeKeyAndVisible()
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
                        self.deleteUserAndSession()
                        self.goToLoginVC()
                        print(error)
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
                                    self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
                                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                    self.window?.rootViewController = storyboard.instantiateViewControllerWithIdentifier("tabVC")
                                    self.window?.makeKeyAndVisible()
                                }

                            } catch let error as NSError {
                                self.deleteUserAndSession()
                                self.goToLoginVC()
                                print(error)
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
                self.deleteUserAndSession()
                self.goToLoginVC()
                print(error)
            }
        }
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        return GIDSignIn.sharedInstance().handleURL(url, sourceApplication: options[UIApplicationOpenURLOptionsSourceApplicationKey] as? String, annotation: options[UIApplicationOpenURLOptionsAnnotationKey] as? String) || FBSDKApplicationDelegate.sharedInstance().application(app, openURL: url, sourceApplication: options[UIApplicationOpenURLOptionsSourceApplicationKey] as! String, annotation: options[UIApplicationOpenURLOptionsAnnotationKey])
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }

}