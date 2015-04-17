//
//  PredictingViewController.swift
//  BEN-A6
//
//  Created by Nicole Sliwa on 4/16/15.
//  Copyright (c) 2015 Team B.E.N. All rights reserved.
//

import UIKit
import CoreLocation
import CoreMotion

class PredictingViewController: UIViewController, CLLocationManagerDelegate, NSURLSessionTaskDelegate {

    // UI elements
    @IBOutlet weak var image_predict: UIImageView!
    var capturedImage: UIImage! = nil
    
    @IBOutlet weak var button_upload: UIButton!
    
    @IBOutlet weak var text_progress: UITextField!
    @IBOutlet weak var text_location: UITextField!
    @IBOutlet weak var text_info: UITextView!
    
    // gets gps data
    var locationManager: CLLocationManager! = nil
    var capturedLocation: CLLocationCoordinate2D! = nil
    var timer: NSTimer! = nil
    
    // gets photo metadata
    var capturedCameraPosition: CMAttitude! = nil
    var capturedMagneticField: CMCalibratedMagneticField! = nil
    var capturedTime: NSNumber = 0
    
    // session config
    //    let SERVER_URL: NSString = "http://guests-mac-mini-2.local:8000"
    var SERVER_URL: NSString = "http://nicoles-macbook-pro.local:8000"
    let UPDATE_INTERVAL = 1/10.0
    
    var session: NSURLSession! = nil
    var taskID = 0
    var dsid = 0
    
    // keeps track of errors
    var errorCount = 0
    var errorMsgs = ""
    
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
        
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if let id = defaults.integerForKey("dsid") as Int? {
            dsid = id
        }
        
        if let serverURL = defaults.stringForKey("Server_URL") as String? {
            SERVER_URL = serverURL
        }
        else {
            NSLog("error in predicting")
        }
        
        // initialize data
        image_predict.image = capturedImage
        button_upload.backgroundColor = UIColor.clearColor()
        
        timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: Selector("turnOffGPS"), userInfo: nil, repeats: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        timer.invalidate()
    }
    
    
    
    
    func askWatson() {
        
        //TODO:
        // get question for watson based on location
        // API call
        // populate info
    }
    
    
    @IBAction func onClick_upload(sender: UIButton) {
        
        // TODO: make sure captuerMagneticField, capturedTime, and locationLabel contain correct info
        
        // convert UIImage to NSData
        var imageData = UIImagePNGRepresentation(image_predict.image)
        let base64ImageString = imageData.base64EncodedStringWithOptions(.allZeros)
        
        // build data dictionary
        var data: NSMutableDictionary = NSMutableDictionary()
//        data["img"] = base64ImageString
        data["gps"] = NSDictionary(dictionary: ["lat": capturedLocation.latitude, "long": capturedLocation.longitude])
        data["compass"] = NSDictionary(dictionary: ["x": capturedMagneticField.field.x, "y": capturedMagneticField.field.y, "z": capturedMagneticField.field.z])
//        data["time"] = capturedTime
        
        // update text label with progress
        // update button background color with progress
        button_upload.backgroundColor = UIColor.blueColor()
        self.text_progress.text = "Uploading"
        
        // API call
        predictFeature(data)
        
        // future dev:
        // askWatson()
    }
    
    func predictFeature(featureData: NSDictionary) {
        // Add a data point and a label to the database for the current dataset ID
        
        // TODO: get correct dsid
        
        errorCount = 0
        errorMsgs = ""
        
        self.button_upload.userInteractionEnabled = false
        
        // setup the url
        let baseURL: NSString = NSString(format: "%@/PredictLocation",SERVER_URL)
        let postURL: NSURL = NSURL(string: baseURL as String)!
        
        // data to send in body of post request (send arguments as json)
        var error: NSError?
                var jsonUpload: NSDictionary = ["feature":featureData, "dsid":dsid]
//        var jsonUpload: NSDictionary = ["feature":"data", "dsid":0]
        
        let requestBody: NSData! = NSJSONSerialization.dataWithJSONObject(jsonUpload, options: NSJSONWritingOptions.PrettyPrinted, error: &error)
        
        //        NSLog("request: %@",  NSString(data: requestBody, encoding: NSUTF8StringEncoding)!)
        
        // create a custom HTTP POST request
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: postURL)
        
        request.HTTPMethod = "POST"
        request.HTTPBody = requestBody
        
        NSLog("requestBody: %@",  NSString(data: request.HTTPBody!, encoding: NSUTF8StringEncoding)!)
        
        // disable buttons while processing
//        button_upload.enabled = false
        
        // start the request, print the responses etc.
        let postTrack: NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: { ( d:NSData!, response:NSURLResponse!, err:NSError! ) -> Void in
            if(err == nil) {
                NSLog("response: %@", response)
                NSLog("data: %@",  NSString(data: d, encoding: NSUTF8StringEncoding)!)
                
                //                let jsonResponse: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: 0, error: nil)
                //                let results: NSDictionary = jsonResponse.valueForKey("locations")
                
                if let responseData: NSDictionary = NSJSONSerialization.JSONObjectWithData(d, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSDictionary {
                    
                    if let labelResponse: NSString = responseData["label"] as? NSString {
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.button_upload.backgroundColor = UIColor.greenColor()
                            self.text_location.text = labelResponse as String
                            self.text_progress.text = "Successful Response"
                        }
                        
                    }
                    else {
                        self.errorCount++
                        self.errorMsgs = self.errorMsgs + (NSString(format:"Error %d: Failed to get location label returned\n", self.errorCount) as String)
                    }
                    
                    
                }
                else {
                    self.errorCount++
                    self.errorMsgs = self.errorMsgs + (NSString(format:"Error %d: Server returned bad data\n", self.errorCount) as String)
                }
            }
                
            else {
                self.errorCount++
                self.errorMsgs = self.errorMsgs + (NSString(format:"Error %d: Failed to connect to server\n", self.errorCount) as String)
            }
            
            if(self.errorCount > 0) {
                dispatch_async(dispatch_get_main_queue()) {
                    self.text_progress.text = NSString(format:"%d Errors Occured", self.errorCount) as String
                    self.button_upload.backgroundColor = UIColor.redColor()
                    
                    NSLog(self.errorMsgs)
                }
            }
            else {
                dispatch_async(dispatch_get_main_queue()) {
                    self.text_progress.text = "Prediction Upload Successful"
                    self.button_upload.backgroundColor = UIColor.greenColor()
                }
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                // enable buttons after processing
                self.button_upload.userInteractionEnabled = true
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


    
    
    //MARK: - Delegation Setup
    
    // Tutorial for retrieving gps location: http://dev.iachieved.it/iachievedit/corelocation-on-ios-8-with-swift/
    // Location Manager Delegate stuff
    // If failed
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        locationManager.stopUpdatingLocation()
        if (error == nil) {
            NSLog("error: %s", error)
            //button_upload.enabled = false
            errorCount++
            errorMsgs = errorMsgs + (NSString(format:"Error %d: Failed to get GPS data\n", errorCount) as String)
        }
        else {
            //button_upload.enabled = true
            errorCount++
            errorMsgs = errorMsgs + (NSString(format:"Error %d: Failed to get GPS data\n", errorCount) as String)
        }
    }
    
    // get gps location right after image capture
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
    
    // stop updating GPS after timer ends (multiple reads to ensure clean data / proper init)
    func turnOffGPS() {
        locationManager.stopUpdatingLocation()
    }

    
    
    
}
