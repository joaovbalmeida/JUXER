//
//  HostViewController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 24/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit
import Kingfisher
import SCLAlertView

class HostViewController: UIViewController {

    @IBOutlet weak var eventImage: UIImageView!
    @IBOutlet weak var eventDescription: UITextView!
    @IBOutlet weak var eventBG: UIImageView!
    @IBOutlet weak var eventName: UILabel!
    @IBOutlet weak var exitButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityIndicatorQR: UIActivityIndicatorView!
    
    @IBOutlet weak var scanLabel: UILabel!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var iconImage: UIImageView!
    
    var session = [Session]()
    
    @IBAction func segueToQR(sender: AnyObject) {
        activityIndicatorQR.startAnimating()
    }
    
    @IBAction func exitEvent(sender: AnyObject) {
        
        let alertView = SCLAlertView()
        alertView.addButton("Sim"){
            
            //Set Session Inactive
            self.session[0].id = nil
            self.session[0].active = 0
            SessionDAO.update(self.session[0])
            
            //Segue to Home
            self.performSegueWithIdentifier("exitEvent", sender: self)
        }
        alertView.showWarning("Sair do evento?", subTitle: "Seus pedidos pendentes continuarão na fila.", closeButtonTitle: "Não", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        eventImage.clipsToBounds = true
        
        session = SessionDAO.fetchSession()
        
        if session[0].active == 1 {
            activityIndicator.startAnimating()
            getEvent(session)
        } else {
            self.navigationItem.rightBarButtonItems = []
            eventDescription.hidden = true
            eventImage.hidden = true
            scanLabel.hidden = false
            scanButton.hidden = false
            iconImage.hidden = false
            instructionLabel.hidden = false
        }
    }
    
    private func getEvent(session: [Session]){
        
        let alertView = SCLAlertView()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        let url = NSURL(string: "http://juxer.club/api/event/\(session[0].id!)/")
        let request = NSMutableURLRequest(URL: url!)
        
        request.HTTPMethod = "GET"
        request.setValue("JWT \(session[0].token!)", forHTTPHeaderField: "Authorization")
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if error != nil {
                print(error)
                dispatch_async(dispatch_get_main_queue()){
                    self.activityIndicator.stopAnimating()
                    alertView.showError("Erro de Conexão", subTitle: "Não foi possivel conectar ao servidor!",closeButtonTitle: "OK" , colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                }
            } else {
                let httpResponse = response as! NSHTTPURLResponse
                if httpResponse.statusCode == 200 {
                    do {
                        let resultJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.activityIndicator.stopAnimating()
                            if let picture = resultJSON.valueForKey("picture") as? String {
                                self.eventBG.kf_setImageWithURL(NSURL(string: picture)!, placeholderImage: UIImage(named: "EventBackground"))
                                self.eventImage.kf_setImageWithURL(NSURL(string: picture)!, placeholderImage: UIImage(named: "BannerPlaceholder"))
                            }
                            if let name = resultJSON.valueForKey("name") as? String {
                                self.eventName.text = name
                            }
                            if let description = resultJSON.valueForKey("description") as? String {
                                self.eventDescription.text = description
                            }
                        }
                        
                    } catch let error as NSError {
                        print(error)
                        dispatch_async(dispatch_get_main_queue()){
                            self.activityIndicator.stopAnimating()
                            alertView.showError("Erro", subTitle: "Não foi possivel obter informações do evento!",closeButtonTitle: "OK" , colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                        }
                    }
                } else {
                    print(httpResponse.statusCode)
                    dispatch_async(dispatch_get_main_queue()){
                        self.activityIndicator.stopAnimating()
                        alertView.showError("Erro", subTitle: "Não foi possivel obter informações do evento!",closeButtonTitle: "OK" , colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                    }
                }
            }
        }
        task.resume()
    }

}
