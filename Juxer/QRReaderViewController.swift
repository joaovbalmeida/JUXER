//
//  QRReaderViewController.swift
//  Juxer
//
//  Created by Joao Victor Almeida on 12/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit
import AVFoundation
import SCLAlertView

class QRReaderViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var captureSession: AVCaptureSession!
    let videoCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    var previewLayer: AVCaptureVideoPreviewLayer!
    var frameView: UIView!
    var topView: UIVisualEffectView!
    var bottomView: UIVisualEffectView!
    let metadataOutput = AVCaptureMetadataOutput()
    var overlay: UIView!
    
    @IBOutlet weak var topLabelConstraint: NSLayoutConstraint!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var LabelConstraint: NSLayoutConstraint!
    @IBOutlet weak var Label: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(QRReaderViewController.avCaptureInputPortFormatDescriptionDidChangeNotification(_:)), name:AVCaptureInputPortFormatDescriptionDidChangeNotification, object: nil)

        self.configureVideoCapture()
        self.addVideoPreviewLayer()
        self.addBlurEffect()
        
        LabelConstraint.constant = ((self.view.bounds.height/5)/5) * 1.5
        topLabelConstraint.constant = ((self.view.bounds.height/5)/5) * 1.5
        
        view.bringSubviewToFront(backButton)
        view.bringSubviewToFront(Label)
        view.bringSubviewToFront(topLabel)
        
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
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        if let touchPoint = touches.first {
            let x = touchPoint.locationInView(self.view).y / view.bounds.size.height
            let y = 1.0 - touchPoint.locationInView(self.view).x / view.bounds.size.width
            let focusPoint = CGPoint(x: x, y: y)
            
            if captureSession.running {
                do {
                    try videoCaptureDevice.lockForConfiguration()
                    videoCaptureDevice.focusPointOfInterest = focusPoint
                    videoCaptureDevice.focusMode = .AutoFocus
                    videoCaptureDevice.exposurePointOfInterest = focusPoint
                    videoCaptureDevice.exposureMode = AVCaptureExposureMode.AutoExpose
                    videoCaptureDevice.unlockForConfiguration()
                }
                catch {
                    print(error)
                }
            }
        }
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
                startLoadOverlay()
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                validateQRCode(metadataObject!.stringValue)
            }
        }
    }
    
    func validateQRCode(code: String) {
        
        let appearance = SCLAlertView.SCLAppearance(showCloseButton: false)
        let alertView = SCLAlertView(appearance: appearance)
        
        // convert String to NSData
        let data: NSData = code.dataUsingEncoding(NSUTF8StringEncoding)!
        
        // convert NSData to 'AnyObject' then make request usign data, to validate QR Code
        do{
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            if let id = json.valueForKey("id") as? Int {
                
                var session: [Session] = [Session]()
                session = SessionDAO.fetchSession()
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                let url = NSURL(string: "http://juxer.club/api/event/\(id)/")
                let request = NSMutableURLRequest(URL: url!)
                
                request.HTTPMethod = "GET"
                request.setValue("JWT \(session[0].token!)", forHTTPHeaderField: "Authorization")
                
                let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    if error != nil {
                        print(error)
                        dispatch_async(dispatch_get_main_queue()){
                            alertView.addButton("OK"){
                                self.stopLoadOverlay()
                            }
                            alertView.showError("Erro", subTitle: "Não foi possivel conectar ao servidor!", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                        }
                        return
                        
                    } else {
                        let httpResponse = response as! NSHTTPURLResponse
                        let string = NSString(data: data!, encoding: NSUTF8StringEncoding)
                        //If code is valid, persist and perform segue, else show error message!
                        if httpResponse.statusCode == 200 {
                            session[0].active = 1
                            session[0].id = id
                            SessionDAO.update(session[0])
                            
                            dispatch_async(dispatch_get_main_queue()){
                                self.performSegueWithIdentifier("gotEvent", sender: self)
                            }
                            
                        } else {
                            print(httpResponse.statusCode)
                            print(string)
                            dispatch_async(dispatch_get_main_queue()){
                                alertView.addButton("OK"){
                                    self.stopLoadOverlay()
                                }
                                alertView.showError("Código Inválido", subTitle: "Não foi possivel validar o código, tente novamente!", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                            }
                        }
                    }
                }
                task.resume()
            } else {
                dispatch_async(dispatch_get_main_queue()){
                    alertView.addButton("OK"){
                        self.stopLoadOverlay()
                    }
                    alertView.showError("Código Inválido", subTitle: "Nenhum evento com o código escaneado!", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
                }
            }
            
        } catch let error as NSError {
            print(error)
            dispatch_async(dispatch_get_main_queue()){
                alertView.addButton("OK"){
                    self.stopLoadOverlay()
                }
                alertView.showError("Código Inválido", subTitle: "Nenhum evento com o código escaneado!", colorStyle: 0xFF005A, colorTextButton: 0xFFFFFF)
            }
        }
    }
    
    func startLoadOverlay(){
        overlay = UIView(frame: CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height))
        overlay.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        self.activityIndicator.startAnimating()
        self.view.addSubview(self.overlay)
        self.view.bringSubviewToFront(self.activityIndicator)
    }
    
    func stopLoadOverlay(){
        self.frameView.frame = CGRectZero
        self.activityIndicator.stopAnimating()
        self.overlay.removeFromSuperview()
        self.captureSession.startRunning()
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
