//
//  PredictViewController.swift
//  BEN-A6
//
//  Created by Nicole Sliwa on 4/15/15.
//  Copyright (c) 2015 Team B.E.N. All rights reserved.
//

import UIKit
import CoreLocation
import CoreMotion

class PredictViewController: UIViewController, CLLocationManagerDelegate, NSURLSessionTaskDelegate {

    @IBOutlet weak var image_predict: UIImageView!
    var capturedImage: UIImage! = nil
    
    @IBOutlet weak var button_upload: UIButton!
    
    @IBOutlet weak var text_progress: UITextField!
    @IBOutlet weak var text_location: UITextField!
    @IBOutlet weak var text_info: UITextView!
    
    var locationManager: CLLocationManager! = nil
    var capturedLocation: CLLocationCoordinate2D! = nil
    var timer: NSTimer! = nil
    
    var capturedCameraPosition: CMAttitude! = nil
    var capturedMagneticField: CMCalibratedMagneticField! = nil
    var capturedTime: NSNumber = 0
    
    let SERVER_URL: NSString = "http://guests-mac-mini.local:8000"
    let UPDATE_INTERVAL = 1/10.0
    
    var session: NSURLSession! = nil
    var taskID = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        //setup NSURLSession (ephemeral)
        let sessionConfig: NSURLSessionConfiguration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        
        sessionConfig.timeoutIntervalForRequest = 5.0;
        sessionConfig.timeoutIntervalForResource = 8.0;
        sessionConfig.HTTPMaximumConnectionsPerHost = 1;
        
        session = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        image_predict.image = capturedImage
        button_upload.backgroundColor = UIColor.clearColor()
        
        timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: Selector("turnOffGPS"), userInfo: nil, repeats: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        timer.invalidate()
    }
    
    // Tutorial for retrieving gps location: http://dev.iachieved.it/iachievedit/corelocation-on-ios-8-with-swift/
    // Location Manager Delegate stuff
    // If failed
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        locationManager.stopUpdatingLocation()
        if (error == nil) {
            NSLog("error: %s", error)
            button_upload.enabled = false
        }
        //        else {
        //            button_upload.enabled = true
        //        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        var locationArray = locations as NSArray
        var locationObj = locationArray.lastObject as! CLLocation
        var coord = locationObj.coordinate
        
        capturedLocation = CLLocationCoordinate2DMake(coord.latitude, coord.longitude)
        
        NSLog("lat: %f", coord.latitude)
        NSLog("long: %f", coord.longitude)
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        println("didChangeAuthorizationStatus")
        
        switch status {
        case .NotDetermined:
            println(".NotDetermined")
            break
            
        case .AuthorizedAlways:
            println(".Authorized Always")
            locationManager.startUpdatingLocation()
            break
            
        case .AuthorizedAlways:
            println(".Authorized When in Use")
            locationManager.startUpdatingLocation()
            break
            
        case .Denied:
            println(".Denied")
            break
            
        default:
            println("Unhandled authorization status")
            break
            
        }
    }
    
    func turnOffGPS() {
        locationManager.stopUpdatingLocation()
    }
    
    func askWatson() {
        
        //TODO:
        // get question for watson based on location
        // API call
        // populate info
    }
    
    @IBAction func onClick_upload(sender: UIButton) {
        
        //TODO:
        // API Call:
        // 1) send up image data
        // update button background color with progress
        // update text label with progress
        // update location with returned text
        
        var data: NSMutableDictionary = NSMutableDictionary()
        data["img"] = image_predict.image
        data["gps"] = NSDictionary(dictionary: ["lat": capturedLocation.latitude, "long": capturedLocation.longitude])
        data["compass"] = NSDictionary(dictionary: ["x": capturedMagneticField.field.x, "y": capturedMagneticField.field.y, "z": capturedMagneticField.field.z])
        data["time"] = "time"
        
        predictFeature(data)
        
        button_upload.backgroundColor = UIColor.blueColor()
        self.text_progress.text = "Uploading"
        
//        askWatson()
    }
    
    func predictFeature(featureData: NSDictionary) {
        // send the server new feature data and request back a prediction of the class
        
        // setup the url
        let baseURL: NSString = NSString(format: "%@/PredictLocation",SERVER_URL)
        let postURL: NSURL = NSURL(string: baseURL as String)!
        
        // data to send in body of post request (send arguments as json)
        var error: NSError?
        var jsonUpload: NSDictionary = ["feature":featureData,
            "dsid":"<self.dsid>"]
        
        let requestBody: NSData! = NSJSONSerialization.dataWithJSONObject(jsonUpload, options: NSJSONWritingOptions.PrettyPrinted, error: &error)
        
        // create a custom HTTP POST request
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: postURL)
        
        request.HTTPMethod = "POST"
        request.HTTPBody = requestBody
        
        // start the request, print the responses etc.
        let postTrack: NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: { ( data:NSData!, response:NSURLResponse!, err:NSError! ) -> Void in
            if(err == nil) {
                var responseData: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                
                var labelResponse: NSString = NSString(format: "%@", responseData.valueForKey("prediction") as! NSString)
                
                NSLog("%@",labelResponse)
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.button_upload.backgroundColor = UIColor.greenColor()
                    self.text_location.text = labelResponse as String
                    self.text_progress.text = "Successful Response"
//                    if(labelResponse == "<possible label>") {
//                        // do stuff
//                    }
                }
                
            }
            else {
                dispatch_async(dispatch_get_main_queue()) {
                    self.button_upload.backgroundColor = UIColor.redColor()
                    self.text_progress.text = "Server Error"
                }
            }
        })
        
        postTrack.resume()
        
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        let vc = segue.destinationViewController as! CaptureViewController
        vc.switchMode = true
        
    }


}
