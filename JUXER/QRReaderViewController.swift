//
//  QRReaderViewController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 12/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit
import AVFoundation

class QRReaderViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var frameView: UIView!
    var topView: UIVisualEffectView!
    var bottomView: UIVisualEffectView!
    let metadataOutput = AVCaptureMetadataOutput()
    
    @IBOutlet weak var LabelConstraint: NSLayoutConstraint!
    @IBOutlet weak var Label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(QRReaderViewController.avCaptureInputPortFormatDescriptionDidChangeNotification(_:)), name:AVCaptureInputPortFormatDescriptionDidChangeNotification, object: nil)

        self.configureVideoCapture()
        self.addVideoPreviewLayer()
        self.addBlurEffect()
        
        LabelConstraint.constant = ((self.view.bounds.height/5)/5) * 1.5
        //bottomLabelConstraint.constant = ((self.view.bounds.height/5)/5) * 1.5
        
        view.bringSubviewToFront(Label)
        //view.bringSubviewToFront(bottomLabel)
        
        self.initializeQRFrame()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession.running == false) {
            captureSession?.startRunning()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession.running == true) {
            captureSession?.stopRunning()
        }
    }
    
    func avCaptureInputPortFormatDescriptionDidChangeNotification(notification: NSNotification) {
        
        let scanRect = CGRect(x: 0, y: self.view.bounds.height/5, width: self.view.bounds.width, height: (self.view.bounds.height/5) * 3)
        metadataOutput.rectOfInterest = previewLayer.metadataOutputRectOfInterestForRect(scanRect)
    }
    
    func configureVideoCapture() {
        let videoCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        let videoInput: AnyObject!
        var error:NSError?
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice) as AVCaptureDeviceInput
        } catch let NSerror as NSError {
            error = NSerror
            if (error != nil) {
                deviceNotSupported()
            }
            videoInput = nil
            return
        }
        
        captureSession = AVCaptureSession()
        
        if (captureSession.canAddInput(videoInput as! AVCaptureInput)) {
            captureSession.addInput(videoInput as! AVCaptureInput)
        } else {
            deviceNotSupported();
            return;
        }
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        } else {
            deviceNotSupported()
            return
        }
    }
    
    func addVideoPreviewLayer(){
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    func addBlurEffect() {
        
        let blurEffect = UIBlurEffect.init(style: UIBlurEffectStyle.Light)
        topView = UIVisualEffectView.init(effect: blurEffect)
        topView.frame = CGRectMake(0, 0, view.bounds.width, view.bounds.height/5)
        view.addSubview(topView)
        view.bringSubviewToFront(topView)
        
        bottomView = UIVisualEffectView.init(effect: blurEffect)
        bottomView.frame = CGRectMake(0, view.bounds.maxY - view.bounds.height/5, view.bounds.width, view.bounds.height/5)
        view.addSubview(bottomView)
        view.bringSubviewToFront(bottomView)
    }

    func initializeQRFrame() {
        frameView = UIView()
        frameView.layer.borderColor = UIColor.init(red: 255/255, green: 0/255, blue: 90/255, alpha: 1).CGColor
        frameView.layer.borderWidth = 3
        view.addSubview(frameView)
        view.bringSubviewToFront(frameView)
    }
    
    func deviceNotSupported() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        presentViewController(ac, animated: true, completion: nil)
        captureSession = nil
    }
    
    
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        captureSession.stopRunning()
        
        if metadataObjects == nil || metadataObjects.count == 0 {
            frameView.frame = CGRectZero
            return
        }
        
        let metadataObject = metadataObjects.first
        
        if metadataObject?.type == AVMetadataObjectTypeQRCode {
            let barCodeObject = previewLayer.transformedMetadataObjectForMetadataObject(metadataObject as! AVMetadataMachineReadableCodeObject) as! AVMetadataMachineReadableCodeObject
            frameView.frame = barCodeObject.bounds
            
            if metadataObject?.stringValue != nil {
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                validateQRCode(metadataObject!.stringValue)
            }
        }
    }
    
    func validateQRCode(code: String) {
        // convert String to NSData
        let data: NSData = code.dataUsingEncoding(NSUTF8StringEncoding)!
        
        // convert NSData to 'AnyObject' then make request usign data, to validate QR Code
        do{
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            let id = json.valueForKey("id") as! Int
            
            var session: [Session] = [Session]()
            session = SessionDAO.fetchSession()
            
            let url = NSURL(string: "http://198.211.98.86/api/event/\(id)/")
            let request = NSMutableURLRequest(URL: url!)
            
            request.HTTPMethod = "GET"
            request.setValue("JWT \(session[0].token!)", forHTTPHeaderField: "Authorization")
            
            let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
                if error != nil {
                    print(error)
                    
                    self.captureSession.startRunning()
                    self.frameView.frame = CGRectZero
                    return
                    
                } else {
                    let httpResponse = response as! NSHTTPURLResponse
                    
                    //If code is valid, persist and perform segue, else show error message!
                    if httpResponse.statusCode == 200 {
                        session[0].active = 1
                        session[0].id = id
                        SessionDAO.update(session[0])
                        
                        dispatch_async(dispatch_get_main_queue()){
                            self.performSegueWithIdentifier("toHome", sender: self)
                        }
                        
                    } else {
                        self.captureSession.startRunning()
                        self.frameView.frame = CGRectZero
                    }
                }
            }
            task.resume()
            
        } catch let error as NSError {
            print(error)
            
            captureSession.startRunning()
            frameView.frame = CGRectZero
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Portrait
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
