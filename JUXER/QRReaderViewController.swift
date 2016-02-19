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
    
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureVideoCapture()
        self.addVideoPreviewLayer()
        self.addBlurEffect()
        
        view.bringSubviewToFront(topLabel)
        view.bringSubviewToFront(bottomLabel)
        
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
        
        let metadataOutput = AVCaptureMetadataOutput()
        
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
        topView.frame = CGRectMake(0, 0, view.bounds.width, view.bounds.height/4)
        view.addSubview(topView)
        view.bringSubviewToFront(topView)
        
        bottomView = UIVisualEffectView.init(effect: blurEffect)
        bottomView.frame = CGRectMake(0, view.bounds.maxY - 150, view.bounds.width, view.bounds.height/4)
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
                foundCode(metadataObject!.stringValue)
            }
        }
    }
    
    // Set session to Active
    private func setSessionActive() {
        var session: [Session] = [Session]()
        session = SessionDAO.fetchSession()
        session[0].active = 1
        SessionDAO.update(session[0])
    }
    
    func foundCode(code: String) {
        print(code)
        setSessionActive()
        performSegueWithIdentifier("toHome", sender: self)
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
