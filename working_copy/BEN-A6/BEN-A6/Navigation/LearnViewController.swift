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
    @IBOutlet weak var image_learn: UIImageView!
    @IBOutlet weak var picker_location: UIPickerView!
    @IBOutlet weak var text_location: UITextField!
    @IBOutlet weak var text_progress: UITextField!
    
    @IBOutlet weak var button_addLocation: UIButton!
    @IBOutlet weak var button_upload: UIButton!
    
    
    var locationManager: CLLocationManager! = nil
    var capturedLocation: CLLocationCoordinate2D! = nil
    var timer: NSTimer! = nil
    
    var capturedImage: UIImage! = nil
    var pickerData:NSMutableArray = ["Mozzarella","Gorgonzola","Provolone","Brie","Maytag Blue","Sharp Cheddar","Monterrey Jack","Stilton","Gouda","Goat Cheese", "Asiago"]
    
    var capturedCameraPosition: CMAttitude! = nil
    var capturedMagneticField: CMCalibratedMagneticField! = nil
    var capturedTime: NSNumber = 0
    
    var locationLabel: NSString = ""
    
    let SERVER_URL: NSString = "http://guests-mac-mini-2.local:8000"
    let UPDATE_INTERVAL = 1/10.0
    
    var session: NSURLSession! = nil
    var taskID = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        picker_location.dataSource = self
        picker_location.delegate = self
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        text_location.delegate = self
        
        //setup NSURLSession (ephemeral)
        let sessionConfig: NSURLSessionConfiguration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        
        sessionConfig.timeoutIntervalForRequest = 5.0;
        sessionConfig.timeoutIntervalForResource = 8.0;
        sessionConfig.HTTPMaximumConnectionsPerHost = 1;
        
        session = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        image_learn.image = capturedImage
        button_upload.backgroundColor = UIColor.clearColor()
        
        populatePickerData()
        
        timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: Selector("turnOffGPS"), userInfo: nil, repeats: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        timer.invalidate()
    }
    
    func populatePickerData() {
        
        // TODO
        // API Call:
        // 1) get location: []
        
        getLocations( { (locations) -> Void in
            self.pickerData.removeAllObjects()
            self.pickerData.addObjectsFromArray(locations as! [AnyObject])
            
            self.picker_location.reloadAllComponents()
        })
        
    }
    
    // Tutorial for UIPickerView: http://makeapppie.com/tag/uipickerview-in-swift/
    //MARK: - Delegates and data sources
    //MARK: Data Sources
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count+1
    }
    
    //MARK: Delegates
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        if(row < pickerData.count) {
            return pickerData[row] as! String
        }
        else {
            return "Add New Data"
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        NSLog("picked")
        if(row < pickerData.count){
            locationLabel = pickerData[row] as! NSString
            
            //button_addLocation.enabled = false
            button_addLocation.hidden = true
            
            //text_location.userInteractionEnabled = false
            text_location.hidden = true
        }
        else {
            //button_addLocation.enabled = true
            button_addLocation.hidden = false
            
            //text_location.userInteractionEnabled = true
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
    
    @IBAction func onClick_add(sender: UIButton) {
        self.view.endEditing(true)
        
        // TODO
        // API Calls:
        // 1) add new location ( string )
        
        addNewLocation(text_location.text, completionHandler: { (locations) -> Void in
            self.pickerData.removeAllObjects()
            self.pickerData.addObjectsFromArray(locations as! [AnyObject])
            
            self.picker_location.reloadAllComponents()
        })
        
    }
    
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
        
        //TODO:
        // API Call:
        // 1) send up image data
        // update button background color with progress
        // update text label with progress
        
        var imageData = UIImagePNGRepresentation(image_learn.image)
        let base64ImageString = imageData.base64EncodedStringWithOptions(.allZeros)
        
        var data: NSMutableDictionary = NSMutableDictionary()
        data["img"] = "image data"//base64ImageString
        data["gps"] = NSDictionary(dictionary: ["lat": capturedLocation.latitude, "long": capturedLocation.longitude])
        data["compass"] = NSDictionary(dictionary: ["x": capturedMagneticField.field.x, "y": capturedMagneticField.field.y, "z": capturedMagneticField.field.z])
        data["time"] = "time"
        
        sendFeatureData(data, l: locationLabel)
        
        button_upload.backgroundColor = UIColor.blueColor()
        self.text_progress.text = "Uploading"
    }
    
    func sendFeatureData3( data: NSDictionary, label:NSString ) {
        // Add a data point and a label to the database for the current dataset ID
        
        // setup the url
        let baseURL: NSString = NSString(format: "%@/AddLearningData",SERVER_URL)
        let postURL: NSURL = NSURL(string: baseURL as String)!
        
        // data to send in body of post request (send arguments as json)
        var error: NSError?
        var jsonUpload: NSDictionary = ["feature":data, "label": label,
            "dsid":0]
        
        //TODO -> actually get dsid
        
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
                
                //                let jsonResponse: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: 0, error: nil)
                //                let results: NSDictionary = jsonResponse.valueForKey("locations")
                
                var responseData: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                
                var results: NSArray = responseData.valueForKey("location") as! NSArray
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.button_upload.backgroundColor = UIColor.greenColor()
                    self.text_progress.text = "Successful Response"
                }
                
            }
                
            else {
                NSLog("response: %@", response)
                NSLog("data: %@",  NSString(data: data, encoding: NSUTF8StringEncoding)!)
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.button_upload.backgroundColor = UIColor.redColor()
                    self.text_progress.text = "Server Error: Failed to Connect"
                }
            }
            
        })
        
        postTrack.resume()
        
    }

    
    func sendFeatureData( d: NSDictionary, l:NSString ) {
        // Add a data point and a label to the database for the current dataset ID
        
        // setup the url
        let baseURL: NSString = NSString(format: "%@/AddLearningData",SERVER_URL)
        let postURL: NSURL = NSURL(string: baseURL as String)!
        
        // data to send in body of post request (send arguments as json)
        var error: NSError?
        var jsonUpload: NSDictionary = ["feature":d, "label": l, "dsid":0]
        
        let requestBody: NSData! = NSJSONSerialization.dataWithJSONObject(jsonUpload, options: NSJSONWritingOptions.PrettyPrinted, error: &error)
        
        NSLog("request: %@",  NSString(data: requestBody, encoding: NSUTF8StringEncoding)!)
        
        // create a custom HTTP POST request
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: postURL)
        
        request.HTTPMethod = "POST"
        request.HTTPBody = requestBody
        
        NSLog("requestBody: %@",  NSString(data: request.HTTPBody!, encoding: NSUTF8StringEncoding)!)
        
        // start the request, print the responses etc.
        let postTrack: NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: { ( d:NSData!, response:NSURLResponse!, err:NSError! ) -> Void in
            if(err == nil) {
                NSLog("response: %@", response)
                NSLog("data: %@",  NSString(data: d, encoding: NSUTF8StringEncoding)!)
                
                //                let jsonResponse: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: 0, error: nil)
                //                let results: NSDictionary = jsonResponse.valueForKey("locations")
                
                var responseData: NSDictionary = NSJSONSerialization.JSONObjectWithData(d, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                
                //var results: NSArray = responseData.valueForKey("locations") as! NSArray
                
                dispatch_async(dispatch_get_main_queue()) {
                    // do stuff
                }
                
            }
                
            else {
                dispatch_async(dispatch_get_main_queue()) {
                    self.text_progress.text = "Server Error: Failed to Get Viable Locations"
                }
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
                        completionHandler?([])
                        dispatch_async(dispatch_get_main_queue()) {
                            self.text_progress.text = "Server Error: Failed to Get Viable Locations"
                        }
                    }
                }
                
                //var results: NSArray = responseData.valueForKey("locations") as! NSArray
                
                
                
                else {
                    completionHandler?([])
                    dispatch_async(dispatch_get_main_queue()) {
                        self.text_progress.text = "Server Error: Failed to Get Viable Locations"
                    }
                }
                
            }
            
            else {
                completionHandler?([])
                dispatch_async(dispatch_get_main_queue()) {
                    self.text_progress.text = "Server Error: Failed to Get Viable Locations"
                }
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
                
//                let jsonResponse: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: 0, error: nil)
//                let results: NSDictionary = jsonResponse.valueForKey("locations")
                
                var responseData: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                
                var results: NSArray = responseData.valueForKey("locations") as! NSArray
                
                dispatch_async(dispatch_get_main_queue()) {
                    // do stuff
                }
                
                completionHandler?(results)
                
            }
                
            else {
                completionHandler?([])
                dispatch_async(dispatch_get_main_queue()) {
                    self.text_progress.text = "Server Error: Failed to Get Viable Locations"
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
