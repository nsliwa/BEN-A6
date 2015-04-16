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
    
    @IBOutlet weak var switch_mode: UISwitch!
    @IBOutlet weak var button_predict: UIButton!
    @IBOutlet weak var button_learn: UIButton!
    
    @IBOutlet weak var button_flash: UIButton!
    @IBOutlet weak var icon_learn: UIImageView!
    @IBOutlet weak var icon_predict: UIImageView!
    
    var switchMode = false
    var capturedImage: UIImage! = nil
    
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
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        
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
        self.videoManager.setProcessingBlock( { (imageInput) -> (CIImage) in
            
            
            var orientation = UIApplication.sharedApplication().statusBarOrientation
            
            if(self.videoManager.getCapturePosition() == AVCaptureDevicePosition.Back) {
                if(orientation == UIInterfaceOrientation.LandscapeLeft) {
                    orientation = UIInterfaceOrientation.LandscapeRight;
                }
                else if(orientation == UIInterfaceOrientation.LandscapeRight) {
                    orientation = UIInterfaceOrientation.LandscapeLeft;
                }
                
            }
            
            var img = imageInput
            
            self.takeScreenShot(img)
            
            return img
        })
        
        if(motionManager.deviceMotionAvailable) {
            motionManager.startDeviceMotionUpdatesUsingReferenceFrame(CMAttitudeReferenceFrame.XMagneticNorthZVertical, toQueue: NSOperationQueue.currentQueue(), withHandler: {
                (deviceMotion, error) -> Void in
                
                self.capturedMagneticField = deviceMotion.magneticField
                self.capturedPosition = deviceMotion.attitude
                
                NSLog(deviceMotion.description)
                
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
        
        self.videoManager.start()
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.videoManager.stop()
        
        if(motionManager.deviceMotionAvailable) {
            self.motionManager.stopDeviceMotionUpdates()
        }
    }
    
    
    @IBAction func onClick_toggleFlash(sender: UIButton) {
        
        if(self.videoManager.toggleFlash()){
            self.videoManager.turnOnFlashwithLevel(0.1)
        }
        
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
        
    }
    
    @IBAction func captureImage(segue:UIStoryboardSegue) {
        
    }
    
    func takeScreenShot(img:CIImage) {
        let ctx = CIContext(options:nil)
        let cgImage = ctx.createCGImage(img, fromRect:img.extent())
        
        let orientation = self.videoManager.getImageOrientationFromUIOrientation(UIApplication.sharedApplication().statusBarOrientation)
        
        NSLog("orientation: %d", orientation)
        
        var uiImage = UIImage()
        
        if(orientation == 5){
            uiImage = UIImage(CGImage: cgImage, scale: 1.0, orientation: UIImageOrientation.Right)!
        }else if(orientation == 3){
            uiImage = UIImage(CGImage: cgImage, scale: 1.0, orientation: UIImageOrientation.Up)!
        }else {
            uiImage = UIImage(CGImage: cgImage, scale: 1.0, orientation: UIImageOrientation.Down)!
        }
        
        capturedImage = uiImage
    }

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
            vc.capturedImage = capturedImage
            
            vc.capturedCameraPosition = capturedPosition
            vc.capturedMagneticField = capturedMagneticField
            vc.capturedTime = hour
            
            NSLog("segue_predict")
        }
        
    }
}
