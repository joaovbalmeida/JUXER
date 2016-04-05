//
//  AppDelegate.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 28/01/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit
import CoreData
import FBSDKCoreKit
import FBSDKLoginKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private var session = [Session]()
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
       
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Custom Navigation Bar
        let navigationBarAppear = UINavigationBar.appearance()
        navigationBarAppear.tintColor = UIColor.init(red: 255/255, green: 0/255, blue: 90/255, alpha: 1)
        navigationBarAppear.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.init(red: 255/255, green: 0/255, blue: 90/255, alpha: 1), NSFontAttributeName: UIFont(name: "Helvetica Neue", size: 18)!]
        
        //Manage Session Token
        session = SessionDAO.fetchSession()
        if session.count != 0 && session[0].token != nil {
            refreshToken()
            
            //Bypass Login VC
            self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let initialViewController = storyboard.instantiateViewControllerWithIdentifier("tabVC")
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
        }
        
        return true
    }
    
    private func refreshToken() {
        print(session[0].token)
        
        let jsonObject: [String : AnyObject] =
            [ "token": "\(session[0].token!)"]
        
        if NSJSONSerialization.isValidJSONObject(jsonObject) {
            
            do {
                let JSON = try NSJSONSerialization.dataWithJSONObject(jsonObject, options: [])
                
                // create post request
                let url = NSURL(string: "http://198.211.98.86/api-token-refresh/")
                let request = NSMutableURLRequest(URL: url!)
                request.HTTPMethod = "POST"
                
                // insert json data to the request
                request.setValue("JWT \(session[0].token!)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                request.HTTPBody = JSON
                
                let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
                    if error != nil{
                        print(error)
                        return
                    } else {
                        do {
                            let resultJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                            var newToken = resultJSON.valueForKey("token") as! String
                            newToken = newToken.stringByRemovingPercentEncoding!
                            newToken = newToken.stringByReplacingOccurrencesOfString("\"", withString: "")
                            self.session[0].token = newToken
                            SessionDAO.update(self.session[0])
                            
                        } catch let error as NSError {
                            print(error)
                        }
                    }
                }
                task.resume()
            } catch {
                print(error)
            }
        }
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
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