//
//  LearningViewController.swift
//  BEN-A6
//
//  Created by Nicole Sliwa on 4/16/15.
//  Copyright (c) 2015 Team B.E.N. All rights reserved.
//
// Tutorial for moving textView with keyboard: http://stackoverflow.com/questions/25693130/move-textfield-when-keyboard-appears-swift

import UIKit
import CoreLocation
import CoreMotion

class LearningViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate, NSURLSessionTaskDelegate, CLLocationManagerDelegate, UITextFieldDelegate {

    // UI elements
    @IBOutlet weak var image_learn: UIImageView!
    @IBOutlet weak var picker_location: UIPickerView!
    @IBOutlet weak var text_location: UITextField!
    @IBOutlet weak var text_progress: UITextField!
    
    @IBOutlet weak var button_addLocation: UIButton!
    @IBOutlet weak var button_upload: UIButton!
    
//    // This constraint ties an element at zero points from the bottom layout guide
//    @IBOutlet var keyboardHeightLayoutConstraint: NSLayoutConstraint?
    
    // gets gps data
    var locationManager: CLLocationManager! = nil
    var capturedLocation: CLLocationCoordinate2D! = nil
    var timer: NSTimer! = nil
    
    // placeholders to store learning metadata
    var capturedImage: UIImage! = nil
    var pickerData:NSMutableArray = ["Peruna Statue","Dallas Hall Fountain","Blanton Fountain","Meadows School Fountain","Fondren Fountain","Meadows Museum Fountain","Centennial Fountain"]
    
    // gets photo metadata
    var capturedCameraPosition: CMAttitude! = nil
    var capturedMagneticField: CMCalibratedMagneticField! = nil
    var capturedTime: NSNumber = 0
    
    // keeps track of currently selected location label
    var locationLabel: NSString = ""
    
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
        
        // setup pickerview delegation
        picker_location.dataSource = self
        picker_location.delegate = self
        
        // setup gps delegation
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        // setup textview delegation
        text_location.delegate = self
        
        //setup NSURLSession delegation (ephemeral)
        let sessionConfig: NSURLSessionConfiguration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        
        sessionConfig.timeoutIntervalForRequest = 5.0;
        sessionConfig.timeoutIntervalForResource = 8.0;
        sessionConfig.HTTPMaximumConnectionsPerHost = 1;
        
        session = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        
//        //setup notification for keyboard appear/disappear
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardNotification:", name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        registerForKeyboardNotifications()
        
        let defaults = NSUserDefaults.standardUserDefaults()

        if let id = defaults.integerForKey("dsid") as Int? {
            dsid = id
        }
        
        if let serverURL = defaults.stringForKey("Server_URL") as String? {
            SERVER_URL = serverURL
        }
        else {
            NSLog("error in learning")
        }
        
        
        // initialize data
        image_learn.image = capturedImage
        button_upload.backgroundColor = UIColor.clearColor()
        
        populatePickerData()
        
        timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: Selector("turnOffGPS"), userInfo: nil, repeats: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        deregisterFromKeyboardNotifications()
        
        timer.invalidate()
    }
    
//    deinit {
//        NSNotificationCenter.defaultCenter().removeObserver(self)
//    }
    
    // Called on: viewWillLoad
    func populatePickerData() {
        
//        // disable buttons while processing
//        button_upload.enabled = false
//        button_addLocation.enabled = false
        
        // completion handler: updates picker with new location labels
        getLocations()
//            { (locations) -> Void in
//            self.pickerData.removeAllObjects()
//            self.pickerData.addObjectsFromArray(locations as! [AnyObject])
//            
//            //            self.picker_location.reloadAllComponents()
//            //
//            //            // enable buttons after processing
//            //            self.button_upload.enabled = true
//            //            self.button_addLocation.enabled = true
//        })
        
    }
    
    @IBAction func onClick_add(sender: UIButton) {
        self.view.endEditing(true)
        
//        button_upload.enabled = false
//        button_addLocation.enabled = false
        
        if(text_location.text != "") {
            self.button_addLocation.backgroundColor = UIColor.clearColor()
            addNewLocation(text_location.text)
        }
        else {
            errorCount++
            errorMsgs = errorMsgs + (NSString(format:"Error %d: Need to provide location label\n", errorCount) as String)

            self.text_location.placeholder = "Must provide location"
            self.button_addLocation.backgroundColor = UIColor.redColor()
            
            NSLog(self.errorMsgs)
        }
        
    }
    
    @IBAction func onClick_upload(sender: UIButton) {
        
        // TODO: make sure captuerMagneticField, capturedTime, and locationLabel contain correct info
        
        // convert UIImage to NSData
        var imageData = UIImagePNGRepresentation(image_learn.image)
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
        
        
        if(locationLabel == ""){
            errorCount++
            errorMsgs = errorMsgs + (NSString(format:"Error %d: Need to select location label\n", errorCount) as String)
            
            text_progress.text = "Select location label"
            button_upload.backgroundColor = UIColor.redColor()
            
            NSLog(errorMsgs)
        }
        else {
            // API call
            sendFeatureData(data, label: locationLabel)
        }
    }
    
    func sendFeatureData( data: NSDictionary, label:NSString ) {
        // Add a data point and a label to the database for the current dataset ID
        
        // TODO: get correct dsid
        
        // reset errors
        self.errorCount = 0
        self.errorMsgs = ""
        
        self.button_addLocation.userInteractionEnabled = false
        self.button_upload.userInteractionEnabled = false
        
        // setup the url
        let baseURL: NSString = NSString(format: "%@/AddLearningData",SERVER_URL)
        let postURL: NSURL = NSURL(string: baseURL as String)!
        
        // data to send in body of post request (send arguments as json)
        var error: NSError?
        var jsonUpload: NSDictionary = ["feature":data, "label": label, "dsid":dsid]
//        var jsonUpload: NSDictionary = ["feature":"data", "label": label, "dsid":0]
        
        let requestBody: NSData! = NSJSONSerialization.dataWithJSONObject(jsonUpload, options: NSJSONWritingOptions.PrettyPrinted, error: &error)
        
        //        NSLog("request: %@",  NSString(data: requestBody, encoding: NSUTF8StringEncoding)!)
        
        // create a custom HTTP POST request
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: postURL)
        
        request.HTTPMethod = "POST"
        request.HTTPBody = requestBody
        
        NSLog("requestBody: %@",  NSString(data: request.HTTPBody!, encoding: NSUTF8StringEncoding)!)
        
//        // disable buttons while processing
//        button_upload.enabled = false
//        button_addLocation.enabled = false
        
        // start the request, print the responses etc.
        let postTrack: NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: { ( d:NSData!, response:NSURLResponse!, err:NSError! ) -> Void in
            if(err == nil) {
                NSLog("response: %@", response)
                NSLog("data: %@",  NSString(data: d, encoding: NSUTF8StringEncoding)!)
                
                if let responseData: NSDictionary = NSJSONSerialization.JSONObjectWithData(d, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSDictionary {
                    
                    if let results: NSString = responseData["label"] as? NSString {
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            // do stuff
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
                    self.text_progress.text = "Learning Upload Successful"
                    self.button_upload.backgroundColor = UIColor.greenColor()
                }
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                // enable buttons after processing
                self.button_addLocation.userInteractionEnabled = true
                self.button_upload.userInteractionEnabled = true
            }
            
        })
        
        postTrack.resume()
        
    }

    func getLocations() {
        // Add a data point and a label to the database for the current dataset ID
        
        // reset errors
        self.errorCount = 0
        self.errorMsgs = ""
        
        self.button_addLocation.userInteractionEnabled = false
        self.button_upload.userInteractionEnabled = false
        
        // setup the url
        var baseURL: NSString = NSString(format: "%@/GetLocations",SERVER_URL)
        
        var postURL: NSURL = NSURL(string: baseURL as String)!
        
        // data to send in body of post request (send arguments as json)
        var error: NSError?
        
        // create a custom HTTP POST request
        var request: NSMutableURLRequest = NSMutableURLRequest(URL: postURL)
        
        request.HTTPMethod = "GET"
        
        // start the request, print the responses etc.
        let postTrack: NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: { ( data:NSData!, response:NSURLResponse!, err:NSError! ) -> Void in
            if(err == nil) {
                NSLog("response: %@", response)
                NSLog("data: %@",  NSString(data: data, encoding: NSUTF8StringEncoding)!)
                
                if let responseData: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSDictionary {
                    
                    if let results: NSArray = (responseData.valueForKey("locations") as? NSArray) {
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.pickerData.removeAllObjects()
                            self.pickerData.addObjectsFromArray(results as [AnyObject])
                            
                            self.picker_location.reloadAllComponents()
                            
                            self.button_addLocation.userInteractionEnabled = true
                            self.button_upload.userInteractionEnabled = true
                            
                            self.button_addLocation.backgroundColor = UIColor.clearColor()
                            self.text_location.placeholder = ""
                            
                            if(self.pickerData.count > 0) {
                                self.locationLabel = self.pickerData[0] as! NSString
                            }
                        }
                        
//                        completionHandler?(results)
                        
                    }
                    else {
                        self.errorCount++
                        self.errorMsgs = self.errorMsgs + (NSString(format:"Error %d: Failed to get location labels\n", self.errorCount) as String)
                        
                    }
                }
                    
                    
                else {
                    self.errorCount++
                    self.errorMsgs = self.errorMsgs + (NSString(format:"Error %d: Failed to get data\n", self.errorCount) as String)
                    
                }
                
            }
                
            else {
                self.errorCount++
                self.errorMsgs = self.errorMsgs + (NSString(format:"Error %d: Failed to connect to server\n", self.errorCount) as String)
                
            }
            
            if(self.errorCount > 0) {
//                completionHandler?([])
                
                dispatch_async(dispatch_get_main_queue(),{
                    self.text_progress.placeholder = NSString(format:"%d Errors Occured", self.errorCount) as String
                    self.locationLabel = ""
                    
                    self.button_addLocation.backgroundColor = UIColor.redColor()
                    
                    self.pickerData.removeAllObjects()
//                    self.pickerData.addObjectsFromArray(results as [AnyObject])
                    self.picker_location.reloadAllComponents()
                    
                    //                    self.picker_location.reloadAllComponents()
                    
                    self.button_addLocation.hidden = false
                    self.text_location.hidden = false
                    
                    self.button_addLocation.userInteractionEnabled = true
                    self.button_upload.userInteractionEnabled = true
                    
                    NSLog(self.errorMsgs)
                    
                })
            }
            
        })
        
        postTrack.resume()
        
    }
    
    func addNewLocation( location: NSString ) {
        // Add a data point and a label to the database for the current dataset ID
        
        // reset errors
        self.errorCount = 0
        self.errorMsgs = ""
        
        self.button_addLocation.userInteractionEnabled = false
        self.button_upload.userInteractionEnabled = false
        
        // setup the url
        let baseURL: NSString = NSString(format: "%@/AddLocation",SERVER_URL)
        let postURL: NSURL = NSURL(string: baseURL as String)!
        
        // data to send in body of post request (send arguments as json)
        var error: NSError?
        var jsonUpload: NSDictionary = ["location":location]
        
        let requestBody: NSData! = NSJSONSerialization.dataWithJSONObject(jsonUpload, options: NSJSONWritingOptions.PrettyPrinted, error: &error)
        
        // create a custom HTTP POST request
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: postURL)
        
        request.HTTPMethod = "POST"
        request.HTTPBody = requestBody
        
        // start the request, print the responses etc.
        let postTrack: NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: { ( data:NSData!, response:NSURLResponse!, err:NSError! ) -> Void in
            if(err == nil) {
                NSLog("response: %@", response)
                NSLog("data: %@",  NSString(data: data, encoding: NSUTF8StringEncoding)!)
                
                if let responseData: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSDictionary {
                    
                    if let results: NSArray = (responseData.valueForKey("locations") as? NSArray) {
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.pickerData.removeAllObjects()
                            self.pickerData.addObjectsFromArray(results as [AnyObject])
                            
                            self.picker_location.reloadAllComponents()
                            
                            self.button_addLocation.hidden = true
                            self.text_location.hidden = true
                            self.text_location.text = ""
                            
                            self.button_addLocation.userInteractionEnabled = true
                            self.button_upload.userInteractionEnabled = true
                            
                            self.button_addLocation.backgroundColor = UIColor.clearColor()
                            self.text_location.placeholder = ""
                        }
                        
//                        completionHandler?(results)
                        
                    }
                    else {
                        self.errorCount++
                        self.errorMsgs = self.errorMsgs + (NSString(format:"Error %d: Failed to get location labels\n", self.errorCount) as String)
                        
                    }
                }
                    
                    
                else {
                    self.errorCount++
                    self.errorMsgs = self.errorMsgs + (NSString(format:"Error %d: Failed to get data\n", self.errorCount) as String)
                    
                }
                
            }
                
            else {
                self.errorCount++
                self.errorMsgs = self.errorMsgs + (NSString(format:"Error %d: Failed to connect to server\n", self.errorCount) as String)
                
            }
            
            if(self.errorCount > 0) {
//                completionHandler?([])
                dispatch_async(dispatch_get_main_queue()) {
                    self.text_location.placeholder = NSString(format:"%d Errors Occured", self.errorCount) as String
                    self.locationLabel = ""
                    
                    self.button_addLocation.backgroundColor = UIColor.redColor()
                    
                    self.pickerData.removeAllObjects()
                    self.picker_location.reloadAllComponents()
                    
                    NSLog(self.errorMsgs)
                    
                    
//                    self.picker_location.selectRow(0, inComponent: 0, animated: true)
                    self.button_addLocation.hidden = false
                    self.text_location.hidden = false
                    
//                    self.button_addLocation.enabled = true
//                    self.button_upload.enabled = true
                    
//                    self.picker_location.reloadAllComponents()
                    
                        self.button_addLocation.userInteractionEnabled = true
                        self.button_upload.userInteractionEnabled = true
                    
                    
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
        vc.switchMode = false
        
    }

    
    
    // MARK: - Delegation handling
    
    // handle textview delegation
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {  //delegate method
        NSLog("end editing")
        textField.resignFirstResponder()
        button_addLocation.backgroundColor = UIColor.clearColor()
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        
        button_addLocation.backgroundColor = UIColor.clearColor()
        
        NSLog("should return")
        
        return true
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        NSLog("touches began")
        
        button_addLocation.backgroundColor = UIColor.clearColor()
        
        self.view.endEditing(true)
    }
    
    
    
    
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
    
    
    
    
    
    // Tutorial for UIPickerView: http://makeapppie.com/tag/uipickerview-in-swift/
    //MARK: - Delegates and data sources
    //MARK: Data Sources
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        // +1 to account for 'add new data' element
        return pickerData.count+1
    }
    
    //MARK: Delegates
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        if(row < pickerData.count) {
            return pickerData[row] as! String
        }
        else {
            return "<Add New Data>"
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        NSLog("picked")
        
        // toggle visibility of elements to 'add new location label' (on if last row in picker selected)
        if(row < pickerData.count){
            locationLabel = pickerData[row] as! NSString
            
            button_addLocation.hidden = true
            text_location.hidden = true
            text_location.text = ""
            
            button_addLocation.backgroundColor = UIColor.clearColor()
            text_location.placeholder = ""
            
        }
        else {
            button_addLocation.hidden = false
            text_location.hidden = false
        }
    }
    
    
    
//    // Move textView for keyboard
//    func keyboardNotification(notification: NSNotification) {
//        if let userInfo = notification.userInfo {
//            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue()
//            let duration:NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
//            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
//            let animationCurveRaw = animationCurveRawNSN?.unsignedLongValue ?? UIViewAnimationOptions.CurveEaseInOut.rawValue
//            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
//            self.keyboardHeightLayoutConstraint?.constant = endFrame?.size.height ?? 0.0
//            UIView.animateWithDuration(duration,
//                delay: NSTimeInterval(0),
//                options: animationCurve,
//                animations: { self.view.layoutIfNeeded() },
//                completion: nil)
//        }
//    }
    
    
    func registerForKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasShown:", name: UIKeyboardWillShowNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
        
    }
    
    func deregisterFromKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
    }
    
    func keyboardWasShown(notification: NSNotification) {
        
        self.view.frame.origin.y -= 220
//        let info: NSDictionary = notification.userInfo!
//        let keyboardSize: CGSize = info.objectForKey(UIKeyboardFrameBeginUserInfoKey)?.CGRectValue().size()!
//        let buttonOrigin: CGPoint = button_addLocation.frame.origin
//        let buttonHeight: CGFloat = button_addLocation.frame.size.height
//        let visibleRect: CGRect = self.view.frame
//        visibleRect.size.height = visibleRect.size.height -  keyboardSize.height
//        
//        if( !CGRectContainsPoint(visibleRect, buttonOrigin) ) {
//            let scrollPoint: CGPoint = CGPointMake(0.0, buttonOrigin.y - visibleRect.size.height + buttonHeight)
//            scrollView.setContentOffset(scrollPoint, animated:true)
//        }
//        
    }
    
    func keyboardWillBeHidden(notification: NSNotification) {
        
        self.view.frame.origin.y += 220
        
    }
//
//    
//    - (void)keyboardWillBeHidden:(NSNotification *)notification {
//    
//    [self.scrollView setContentOffset:CGPointZero animated:YES];
//    
//    }
    
}
