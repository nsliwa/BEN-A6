//
//  LearnViewController.swift
//  BEN-A6
//
//  Created by Nicole Sliwa on 4/15/15.
//  Copyright (c) 2015 Team B.E.N. All rights reserved.
//

import UIKit
import CoreLocation
import CoreMotion

class LearnViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate, NSURLSessionTaskDelegate, CLLocationManagerDelegate, UITextFieldDelegate {
    // UI elements
    @IBOutlet weak var image_learn: UIImageView!
    @IBOutlet weak var picker_location: UIPickerView!
    @IBOutlet weak var text_location: UITextField!
    @IBOutlet weak var text_progress: UITextField!
    
    @IBOutlet weak var button_addLocation: UIButton!
    @IBOutlet weak var button_upload: UIButton!
    
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
    let SERVER_URL: NSString = "http://nicoles-macbook-pro.local:8000"
    let UPDATE_INTERVAL = 1/10.0
    
    var session: NSURLSession! = nil
    var taskID = 0
    
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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // initialize data
        image_learn.image = capturedImage
        button_upload.backgroundColor = UIColor.clearColor()
        
        populatePickerData()
        
        timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: Selector("turnOffGPS"), userInfo: nil, repeats: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        timer.invalidate()
    }
    
    // Called on: viewWillLoad
    func populatePickerData() {
        // disable buttons while processing
        button_upload.enabled = false
        button_addLocation.enabled = false
        
        // completion handler: updates picker with new location labels
        getLocations( { (locations) -> Void in
            self.pickerData.removeAllObjects()
            self.pickerData.addObjectsFromArray(locations as! [AnyObject])
            
//            self.picker_location.reloadAllComponents()
//            
//            // enable buttons after processing
//            self.button_upload.enabled = true
//            self.button_addLocation.enabled = true
        })
        
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
        }
        else {
            button_addLocation.hidden = false
            text_location.hidden = false
        }
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
    
    @IBAction func onClick_add(sender: UIButton) {
        self.view.endEditing(true)
        
        errorCount = 0
        errorMsgs = ""
        
        button_upload.enabled = false
        button_addLocation.enabled = false
        
        addNewLocation(text_location.text, completionHandler: { (locations) -> Void in
            self.pickerData.removeAllObjects()
            self.pickerData.addObjectsFromArray(locations as! [AnyObject])
            
//            self.picker_location.reloadAllComponents()
            
            // select last added label
            self.picker_location.selectRow(self.pickerData.count - 1, inComponent: 0, animated: true)
            
            self.button_upload.enabled = true
            self.button_addLocation.enabled = true
        })
        
    }
    
    // handle textview delegation
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {  //delegate method
        NSLog("end editing")
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        
        NSLog("should return")
        
        return true
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        NSLog("touches began")
        self.view.endEditing(true)
    }
    
    @IBAction func onClick_upload(sender: UIButton) {
        
        // TODO: make sure captuerMagneticField, capturedTime, and locationLabel contain correct info
        
        errorCount = 0
        errorMsgs = ""
        
        // convert UIImage to NSData
        var imageData = UIImagePNGRepresentation(image_learn.image)
        let base64ImageString = imageData.base64EncodedStringWithOptions(.allZeros)
        
        // build data dictionary
        var data: NSMutableDictionary = NSMutableDictionary()
        data["img"] = base64ImageString
        data["gps"] = NSDictionary(dictionary: ["lat": capturedLocation.latitude, "long": capturedLocation.longitude])
        data["compass"] = NSDictionary(dictionary: ["x": capturedMagneticField.field.x, "y": capturedMagneticField.field.y, "z": capturedMagneticField.field.z])
        data["time"] = capturedTime
        
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
    
//    func sendFeatureData3( data: NSDictionary, label:NSString ) {
//        // Add a data point and a label to the database for the current dataset ID
//        
//        // setup the url
//        let baseURL: NSString = NSString(format: "%@/AddLearningData",SERVER_URL)
//        let postURL: NSURL = NSURL(string: baseURL as String)!
//        
//        // data to send in body of post request (send arguments as json)
//        var error: NSError?
//        var jsonUpload: NSDictionary = ["feature":data, "label": label,
//            "dsid":0]
//        
//        //TODO -> actually get dsid
//        
//        let requestBody: NSData! = NSJSONSerialization.dataWithJSONObject(jsonUpload, options: NSJSONWritingOptions.PrettyPrinted, error: &error)
//        
//        // create a custom HTTP POST request
//        let request: NSMutableURLRequest = NSMutableURLRequest(URL: postURL)
//        
//        request.HTTPMethod = "POST"
//        request.HTTPBody = requestBody
//        
//        // start the request, print the responses etc.
//        let postTrack: NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: { ( data:NSData!, response:NSURLResponse!, err:NSError! ) -> Void in
//            if(err == nil) {
//                NSLog("response: %@", response)
//                NSLog("data: %@",  NSString(data: data, encoding: NSUTF8StringEncoding)!)
//                
//                //                let jsonResponse: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: 0, error: nil)
//                //                let results: NSDictionary = jsonResponse.valueForKey("locations")
//                
//                var responseData: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
//                
//                var results: NSArray = responseData.valueForKey("location") as! NSArray
//                
//                dispatch_async(dispatch_get_main_queue()) {
//                    self.button_upload.backgroundColor = UIColor.greenColor()
//                    self.text_progress.text = "Successful Response"
//                }
//                
//            }
//                
//            else {
//                NSLog("response: %@", response)
//                NSLog("data: %@",  NSString(data: data, encoding: NSUTF8StringEncoding)!)
//                
//                dispatch_async(dispatch_get_main_queue()) {
//                    self.button_upload.backgroundColor = UIColor.redColor()
//                    self.text_progress.text = "Server Error: Failed to Connect"
//                }
//            }
//            
//        })
//        
//        postTrack.resume()
//        
//    }

    
    func sendFeatureData( data: NSDictionary, label:NSString ) {
        // Add a data point and a label to the database for the current dataset ID
        
        // TODO: get correct dsid
        
        // setup the url
        let baseURL: NSString = NSString(format: "%@/AddLearningData",SERVER_URL)
        let postURL: NSURL = NSURL(string: baseURL as String)!
        
        // data to send in body of post request (send arguments as json)
        var error: NSError?
//        var jsonUpload: NSDictionary = ["feature":data, "label": label, "dsid":0]
        var jsonUpload: NSDictionary = ["feature":"data", "label": label, "dsid":0]
        
        let requestBody: NSData! = NSJSONSerialization.dataWithJSONObject(jsonUpload, options: NSJSONWritingOptions.PrettyPrinted, error: &error)
        
//        NSLog("request: %@",  NSString(data: requestBody, encoding: NSUTF8StringEncoding)!)
        
        // create a custom HTTP POST request
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: postURL)
        
        request.HTTPMethod = "POST"
        request.HTTPBody = requestBody
        
        NSLog("requestBody: %@",  NSString(data: request.HTTPBody!, encoding: NSUTF8StringEncoding)!)
        
        // disable buttons while processing
        button_upload.enabled = false
        button_addLocation.enabled = false
        
        // start the request, print the responses etc.
        let postTrack: NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: { ( d:NSData!, response:NSURLResponse!, err:NSError! ) -> Void in
            if(err == nil) {
                NSLog("response: %@", response)
                NSLog("data: %@",  NSString(data: d, encoding: NSUTF8StringEncoding)!)
                
                //                let jsonResponse: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: 0, error: nil)
                //                let results: NSDictionary = jsonResponse.valueForKey("locations")
                
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
                self.button_upload.enabled = true
                self.button_addLocation.enabled = true
            }
            
        })
        
        postTrack.resume()
        
    }
    
    
//    func sendFeatureArray2( data: NSDictionary, label:NSString ) {
//        // Add a data point and a label to the database for the current dataset ID
//        
//        // setup the url
//        let baseURL: NSString = NSString(format: "%@/AddLabeledInstance", SERVER_URL)
//        let postURL: NSURL = NSURL(string: baseURL as String)!
//        
//        // data to send in body of post request (send arguments as json)
//        var error: NSError?
//        var jsonUpload: NSDictionary = ["feature":data, "label": label,
//            "dsid":"<self.dsid>"]
//        
//        if let requestBody: NSData = NSJSONSerialization.dataWithJSONObject(jsonUpload, options: NSJSONWritingOptions.PrettyPrinted, error: &error) {
//         
//            // create a custom HTTP POST request
//            let request: NSMutableURLRequest = NSMutableURLRequest(URL: postURL)
//            
//            request.HTTPMethod = "POST"
//            request.HTTPBody = requestBody
//            
//            NSLog("request: %@",  NSString(data: requestBody, encoding: NSUTF8StringEncoding)!)
//            
//            // start the request, print the responses etc.
//            let postTrack: NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: { ( data:NSData!, response:NSURLResponse!, err:NSError! ) -> Void in
//                if(err == nil) {
//                    NSLog("response: %@", response)
//                    NSLog("data: %@",  NSString(data: data, encoding: NSUTF8StringEncoding)!)
//                    
//                    var responseData: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
//                    
//                    
//                    // we should get back the feature data from the server and the label it parsed
//                    var featuresResponse: NSString = NSString(format: "%@", responseData.valueForKey("feature") as! NSString)
//                    var labelResponse: NSString = NSString(format: "%@", responseData.valueForKey("label") as! NSString)
//                    
//                    NSLog("received %@ and %@",featuresResponse,labelResponse)
//                    
//                    dispatch_async(dispatch_get_main_queue()) {
//                        self.button_upload.backgroundColor = UIColor.greenColor()
//                        self.text_progress.text = "Successful Response"
//                    }
//                    
//                }
//                else {
//                    dispatch_async(dispatch_get_main_queue()) {
//                        self.button_upload.backgroundColor = UIColor.redColor()
//                        self.text_progress.text = "Server Error"
//                    }
//                }
//                
//            })
//            
//            postTrack.resume()
//            
//        }
//        
//    }
    
    func getLocations( completionHandler: ((NSArray!) -> Void)? ) {
        // Add a data point and a label to the database for the current dataset ID
        
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
                            // do stuff
                        }
                        
                        completionHandler?(results)
                        
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
                completionHandler?([])
                
                dispatch_async(dispatch_get_main_queue(),{
                    self.text_progress.text = NSString(format:"%d Errors Occured", self.errorCount) as String
                    self.locationLabel = ""
                    
                    self.button_upload.backgroundColor = UIColor.redColor()
                    
//                    self.picker_location.reloadAllComponents()
                    
                    dispatch_async(dispatch_get_main_queue(),{
                        self.picker_location.selectRow(0, inComponent: 0, animated: true)
                        self.button_addLocation.hidden = false
                        self.text_location.hidden = false
                        
                        self.button_addLocation.enabled = true
                        self.button_upload.enabled = true
                        
                        NSLog(self.errorMsgs)
                    })
                })
            }
            
        })
        
        postTrack.resume()
        
    }
    
    func addNewLocation( location: NSString, completionHandler: ((NSArray!) -> Void)? ) {
        // Add a data point and a label to the database for the current dataset ID
        
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
                            // do stuff
                        }
                        
                        completionHandler?(results)
                        
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
                completionHandler?([])
                dispatch_async(dispatch_get_main_queue()) {
                    self.text_progress.text = NSString(format:"%d Errors Occured", self.errorCount) as String
                    self.locationLabel = ""
                    
                    self.button_upload.backgroundColor = UIColor.redColor()
                    
                    NSLog(self.errorMsgs)
                    
                    
                    self.picker_location.selectRow(0, inComponent: 0, animated: true)
                    self.button_addLocation.hidden = false
                    self.text_location.hidden = false
                    
                    self.button_addLocation.enabled = true
                    self.button_upload.enabled = true
                    
                    self.picker_location.reloadAllComponents()
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

    
}
