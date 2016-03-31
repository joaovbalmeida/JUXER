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

    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
       
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Custom Navigation Bar
        let navigationBarAppear = UINavigationBar.appearance()
        navigationBarAppear.tintColor = UIColor.init(red: 255/255, green: 0/255, blue: 90/255, alpha: 1)
        navigationBarAppear.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.init(red: 255/255, green: 0/255, blue: 90/255, alpha: 1), NSFontAttributeName: UIFont(name: "Helvetica Neue", size: 18)!]
        
        // Check Token
        var session = [Session]()
        session = SessionDAO.fetchSession()
        
        let url = NSURL(string: "http://10.0.0.68:3000/api/user/me/")
        let request = NSMutableURLRequest(URL: url!)
        request.addValue("JWT \(session[0].token!)", forHTTPHeaderField: "Authorization")
        request.HTTPMethod = "GET"
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            if error != nil {
                print(error)
                return
            } else {
                do {
                    let resultJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                    print(resultJSON)
                    
                } catch let error as NSError {
                    print(error)
                }
            }
        }
        task.resume()
        
        //let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        //let LoginVC = mainStoryboard.instantiateViewControllerWithIdentifier("LoginVC") as!
        //LoginViewController
        //window!.rootViewController = LoginVC
        
        return true
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