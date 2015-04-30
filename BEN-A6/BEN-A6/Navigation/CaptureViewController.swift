//
//  CaptureViewController.swift
//  BEN-A6
//
//  Created by Nicole Sliwa on 4/8/15.
//  Copyright (c) 2015 Team B.E.N. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion

class CaptureViewController: UIViewController {
    var videoManager : VideoAnalgesic! = nil
    var motionManager : CMMotionManager! = nil
    
    let captureSession = AVCaptureSession()
    // If we find a device we'll store it here for later use
    var captureDevice : AVCaptureDevice?
    
    let sessionQueue = dispatch_queue_create("camera", DISPATCH_QUEUE_SERIAL)
    
    let stillCameraOutput = AVCaptureStillImageOutput()
    
    
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    @IBOutlet weak var switch_mode: UISwitch!
    @IBOutlet weak var button_predict: UIButton!
    @IBOutlet weak var button_learn: UIButton!
    
    @IBOutlet weak var button_flash: UIButton!
    @IBOutlet weak var icon_learn: UIImageView!
    @IBOutlet weak var icon_predict: UIImageView!
    
    var switchMode = false
    var capturedImage: Array<UIImage> = []
    
    var capturedMagneticField: CMCalibratedMagneticField! = nil
    var capturedPosition: CMAttitude! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        icon_learn.layer.cornerRadius = 10.0
        icon_predict.layer.cornerRadius = 10.0
        
        self.view.backgroundColor = nil
        
        self.videoManager = VideoAnalgesic.sharedInstance
        self.videoManager.setCameraPosition(AVCaptureDevicePosition.Back)
        
        motionManager = CMMotionManager()
        if(motionManager.deviceMotionAvailable) {
            motionManager.magnetometerUpdateInterval = 0.1
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.showsDeviceMovementDisplay = true
        }
        
        
        if self.captureSession.canAddOutput(self.stillCameraOutput) {
            self.captureSession.addOutput(self.stillCameraOutput)
        }
        
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        
        
        
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                }
            }
        }
        
        if captureDevice != nil {
            beginSession()
        }
        
        

        
    }
    
    func beginSession() {
        var err : NSError? = nil
        captureSession.addInput(AVCaptureDeviceInput(device: captureDevice, error: &err))
        
        if err != nil {
            println("error: \(err?.localizedDescription)")
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.addSublayer(previewLayer)
        previewLayer?.frame = self.view.layer.frame
        
        captureSession.startRunning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSLog("view will appear")
        
            switch_mode.on = switchMode
            
            if(switch_mode.on) {
                button_predict.hidden = false
                button_predict.enabled = true
                
                button_learn.hidden = true
                button_learn.enabled = false
            }
            else {
                button_predict.hidden = true
                button_predict.enabled = false
                
                button_learn.hidden = false
                button_learn.enabled = true
            }
        
        if(motionManager.deviceMotionAvailable) {
            motionManager.startDeviceMotionUpdatesUsingReferenceFrame(CMAttitudeReferenceFrame.XMagneticNorthZVertical, toQueue: NSOperationQueue.currentQueue(), withHandler: {
                (deviceMotion, error) -> Void in
                
                if (error == nil) {
                
                    if let magField = deviceMotion?.magneticField as CMCalibratedMagneticField? {
                        self.capturedMagneticField = magField
                    }
    //                self.capturedMagneticField = deviceMotion.magneticField
                    if let attitude = deviceMotion?.attitude as CMAttitude? {
                        self.capturedPosition = attitude
                    }
    //                self.capturedPosition = deviceMotion.attitude
                    
    //                if let descr = deviceMotion?.description {
    //                    NSLog(descr)
    //                }
                }
                else {
                    NSLog("error with motionmanager")
                }
                
            })
//            motionManager.startDeviceMotionUpdatesToQueueUsingReference(NSOperationQueue.currentQueue()) {
//                (deviceMotion, error) -> Void in
//                
//                self.capturedMagneticField = deviceMotion.magneticField
//                self.capturedPosition = deviceMotion.attitude
//                
//                NSLog(deviceMotion.description)
//                
//            }
        }
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        
        if(motionManager.deviceMotionAvailable) {
            self.motionManager.stopDeviceMotionUpdates()
        }
    }
    
    
    @IBAction func onClick_toggleFlash(sender: UIButton) {
        /*
        if(self.videoManager.toggleFlash()){
            self.videoManager.turnOnFlashwithLevel(0.1)
        }
        */
    }
    
    @IBAction func onToggle_modeSwitch(sender: UISwitch) {
        if(sender.on) {
            button_predict.hidden = false
            button_predict.enabled = true
            
            button_learn.hidden = true
            button_learn.enabled = false
        }
        else {
            button_predict.hidden = true
            button_predict.enabled = false
            
            button_learn.hidden = false
            button_learn.enabled = true
        }
    }
    
    @IBAction func onClick_captureImage(sender: UIButton) {
//        if(switch_mode.on) {
//            let destinationVC = self.storyboard?.instantiateViewControllerWithIdentifier("PredictVC");
//            
//            Predict *destViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"YourDestinationViewId"];
//            [self.navigationController pushViewController:destViewController animated:YES];
//        }
//        else {
//            
//        }
        
        
        NSLog("Taking pictures")
        
       
            
            let connection = self.stillCameraOutput.connectionWithMediaType(AVMediaTypeVideo)
            
            
            
            // update the video orientation to the device one
            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)!            
        
        var set: Array<Float> = []
        for index in 0...99 {
            set.append(0.0)
        }
            
            var settings = set.map {
                (bias:Float) -> AVCaptureAutoExposureBracketedStillImageSettings in
                
                AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettingsWithExposureTargetBias(bias)
            }
            
            var counter = settings.count
        
            self.stillCameraOutput.captureStillImageBracketAsynchronouslyFromConnection(connection, withSettingsArray: settings) {
                (sampleBuffer, settings, error) -> Void in
                
                
                if error == nil {
                    
                    // if the session preset .Photo is used, or if explicitly set in the device's outputSettings
                    // we get the data already compressed as JPEG
                    
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    
                    // the sample buffer also contains the metadata, in case we want to modify it
                    let metadata:NSDictionary = CMCopyDictionaryOfAttachments(nil, sampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate)).takeUnretainedValue()
                    
                    if let image = UIImage(data: imageData) {
                        self.capturedImage.append(image)
                    }
                }
                else {
                    NSLog("error while capturing still image: \(error)")
                }
                
                counter--
                if(counter == 0){
                    self.performSegueWithIdentifier("segue_modal_learn", sender: self)
                }
                
            }
            
        //self.stillCameraOutput.
        
        //if(!self.stillCameraOutput.capturingStillImage)
        
        
        
    }
    
    @IBAction func captureImage(segue:UIStoryboardSegue) {
        
    }
    /*
    func takeScreenShot(img:CIImage) {
        
        let orientation = self.videoManager.getImageOrientationFromUIOrientation(UIApplication.sharedApplication().statusBarOrientation)
        
        NSLog("orientation: %d", orientation)

        for index in 0...99{
            NSLog("pic %d", index);
            let ctx = CIContext(options:nil)
            let cgImage = ctx.createCGImage(img, fromRect:img.extent())
        
                
        
            var uiImage = UIImage()
        
            if(orientation == 5){
                uiImage = UIImage(CGImage: cgImage, scale: 1.0, orientation: UIImageOrientation.Right)!
            }else if(orientation == 3){
                uiImage = UIImage(CGImage: cgImage, scale: 1.0, orientation: UIImageOrientation.Up)!
            }else {
                uiImage = UIImage(CGImage: cgImage, scale: 1.0, orientation: UIImageOrientation.Down)!
            }
        
            capturedImage.append(uiImage)
        }
        
    }
*/
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        let date = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(.CalendarUnitHour | .CalendarUnitMinute, fromDate: date)
        let hour = components.hour
        
        if (segue.identifier == "segue_modal_learn") {
            let vc = segue.destinationViewController as! LearningViewController
            vc.capturedImage = capturedImage
            
            vc.capturedCameraPosition = capturedPosition
            vc.capturedMagneticField = capturedMagneticField
            vc.capturedTime = hour
            
            NSLog("segue_learn")
        }
        else if (segue.identifier == "segue_modal_predict") {
            let vc = segue.destinationViewController as! PredictingViewController
            vc.capturedImage = capturedImage[0]
            vc.capturedCameraPosition = capturedPosition
            vc.capturedMagneticField = capturedMagneticField
            vc.capturedTime = hour
            
            NSLog("segue_predict")
        }
        
    }
}
