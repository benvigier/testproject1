//
//  ViewController.swift
//  placetest
//
//  Created by Ben Vigier on 11/20/17.
//  Copyright © 2017 Benjamin Vigier. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftyJSON
import Alamofire
import ProgressHUD
import FBSDKPlacesKit
import GoogleMaps
import GooglePlaces
import GooglePlacePicker
import GoogleMapsCore

class ViewController: UIViewController,CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource, GMSPlacePickerViewControllerDelegate{
    
    //Pre-linked Outlets
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var placeTableView: UITableView!
    @IBOutlet weak var pickerButton: UIButton!
    @IBOutlet weak var nearbySwitchContainerView: UIView!
    
    //Constants & variables
    
    let GOOGLE_NEARBYPLACE_SEARCH_URL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
    let FACEBOOK_CURRENTPLACE_SEARCH_URL = "https://graph.facebook.com/v2.11/current_place/results?"
    let GOOGLE_API_KEY = "AIzaSyD8htgqYPVgAo3mRG_1CbI62adeigZhcos"
    let GOOGLE_API_KEY_FOR_SDK = "AIzaSyBr4D7SOxkwhUj-6qACVv5HI4K4Tn_yhMM"
    let PLACE_SEARCH_RADIUS = "100"
    let FACEBOOK_CURRENTPLACE_MIN_CONFIDENCE_LEVEL = FBSDKPlaceLocationConfidence.FBSDKPlaceLocationConfidenceLow //other possible values: medium or high
    let locationManager = CLLocationManager()
    let fbPlaceManager = FBSDKPlacesManager()
    
    var SEARCH_MODE = "CURRENT" //gets replaced by "NEARBY" when the nearby switch is on
    var googlePlacesClient : GMSPlacesClient!
    var currentLocation : CLLocation = CLLocation()
    var googlePlaces : [Place] = []
    var facebookPlaces : [Place] = []
    var isGoogleSelected = true
    var locationCurrentlyStoppedByMe = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        placeTableView.layer.cornerRadius = 5
        refreshButton.layer.cornerRadius = 5
        pickerButton.layer.cornerRadius = 5
        nearbySwitchContainerView.layer.cornerRadius = 5
        
        
        GMSPlacesClient.provideAPIKey(GOOGLE_API_KEY_FOR_SDK)
        GMSServices.provideAPIKey(GOOGLE_API_KEY_FOR_SDK)
        googlePlacesClient = GMSPlacesClient.shared()
        
        //Setting up the TableView delegate and initial state
        placeTableView.delegate = self
        placeTableView.dataSource = self
        //placeTableView.isHidden = true
        
        //Setting up the location manager.
        locationManager.delegate = self
        locationManager.desiredAccuracy = CoreLocation.kCLLocationAccuracyBest
        
        //Requesting User Permission to Access Core Location
        print("Requesting User Authorization to access Location Services")
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationCurrentlyStoppedByMe = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateStatusLabel(status : String){
        //statusLabel.text = status
    }
    
    
    
    
    /***************************************************************/
    //MARK: - UI CONTROL MANAGEMENT
    /***************************************************************/
    
    
    //MARK: - Segmented Control Action
    /***************************************************************/
    
    @IBAction func segmentedControl(_ sender: UISegmentedControl) {
     
        let selection = sender.selectedSegmentIndex
        
        if selection == 0{
            print("Google selected")
            isGoogleSelected = true
        }
        
        if selection == 1{
            print("Facebook selected")
            isGoogleSelected = false
        }
        //ProgressHUD.show()
        self.placeTableView.reloadData()
        //ProgressHUD.dismiss()
    }
    
   
    //MARK: - Refresh Button Pressed
    /***************************************************************/
    
    @IBAction func refreshButtonPressed(_ sender: Any) {
        print("Refresh Button pressed")
        refreshAllResults()
    }
    
    func refreshAllResults(){
        clearTableView()
        locationManager.startUpdatingLocation()
        locationCurrentlyStoppedByMe = false
    }
    
    
    //MARK: - Google Current Place Picker Implementation
    /***************************************************************/
    
    // To receive the results from the place picker 'self' will need to conform to
    // GMSPlacePickerViewControllerDelegate and implement this code.
    
    func placePicker(_ viewController: GMSPlacePickerViewController, didPick place: GMSPlace) {
        // Dismiss the place picker, as it cannot dismiss itself.
        viewController.dismiss(animated: true, completion: nil)
        
        print("Place name \(place.name)")
        print("Place address \(place.formattedAddress)")
        print("Place types \(place.types)")
    }
    
    func placePickerDidCancel(_ viewController: GMSPlacePickerViewController) {
        // Dismiss the place picker, as it cannot dismiss itself.
        viewController.dismiss(animated: true, completion: nil)
        
        print("No place selected")
    }
    
    
    
    //MARK: - Picker Button Control Action
    /***************************************************************/
    
    @IBAction func pickerButtonPressed(_ sender: Any) {
        print("Picker Button pressed")
        
        let config = GMSPlacePickerConfig(viewport: nil)
        let placePicker = GMSPlacePickerViewController(config: config)
        placePicker.delegate = self
        present(placePicker, animated: true, completion: nil)
    }
    
    //MARK: - Nearby Switch Control Action
    /***************************************************************/
    @IBAction func nearbySwitchChanged(_ sender: UISwitch) {
        print("Switch changed - IsOn = \(sender.isOn)")
        if sender.isOn{
            self.SEARCH_MODE = "NEARBY"
            refreshAllResults()
        }
        else{
            self.SEARCH_MODE = "CURRENT"
            refreshAllResults()
        }
    }
    
    func clearTableView(){
        googlePlaces = []
        facebookPlaces = []
        placeTableView.reloadData()
    }
    
    
    
    
    /***************************************************************/
    //MARK: - Location Manager Delegate Methods
    /***************************************************************/
    
    
    //Write the didUpdateLocations method here:
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if locationCurrentlyStoppedByMe{
            print("LOCATION UPDATE RECEIVED - NOT REQUESTED BY ME")
            return
        }
        
        print("LOCATION UPDATE RECEIVED - REQUESTED BY ME")
        
        if locations.count == 0{
            updateStatusLabel(status: "No location received")
            print("No location returned in location update event")
            return
        }
        
        currentLocation = locations[locations.count-1]
        
        //weeding out invalid location updates from Core Location Services
        if currentLocation.horizontalAccuracy <= 0{
            updateStatusLabel(status: "Location horizontal accuracy is invalid")
            print("Invalid horizontal accuracy in latest location update")
            return
        }
        
        print("LOCATION ACCURACY VALID")
        
        //
        // Add accuracry checks here to assess whether good enough or wait more
        //
        
        //Core Location Services provided a valid location - Stopping location updates to save battery
        locationManager.stopUpdatingLocation()
        locationCurrentlyStoppedByMe = true
        
        print("LOCATION UPDATES STOPPED")
        
        if SEARCH_MODE == "NEARBY" {
            //Fetching Google Nearby Place Search results for current location
            getNearbyPlacesFromGoogle(rankby: "") //rankby not yet implemented
        }
        else{
            //Fetching Google Current Place candidates
            print("CALLING GET CURRENT PLACES")
            getCurrentPlaces()
        }
     
    }
    
    //Write the didFailWithError method here:
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location failed with Error:\n:\(error)")
    }

 
    
    /***************************************************************/
    //MARK: - NEARBY PLACE SEARCH
    /***************************************************************/
   
    func getNearbyPlaces(){
        ProgressHUD.show()
        getNearbyPlacesFromGoogle(rankby: "")
    }
    
    
    //MARK: - Google Nearby Place Search
    /***************************************************************/
    
    
    func getNearbyPlacesFromGoogle(rankby: String){

        let googleParam = ["key" : GOOGLE_API_KEY, "location" :String(currentLocation.coordinate.latitude)+","+String(currentLocation.coordinate.longitude),"radius" : PLACE_SEARCH_RADIUS]
    
        //resetting the current Google Places array
        self.googlePlaces = []
        
        ProgressHUD.show()
        
        
        Alamofire.request(GOOGLE_NEARBYPLACE_SEARCH_URL, method: .get, parameters: googleParam).responseJSON {
            response in
            if response.result.isSuccess {
                print("Google Place data received")
            }
            else{
                print("Network Error while receiving Google place data - Error =\(response.result.error!)")
            }
            
            let placeJSON : JSON = JSON(response.result.value!)
            print("\n\nGOOGLE PLACE JSON CONTENT = \(placeJSON)")
            
            self.parseGooglePlaceSearchJSON(json : placeJSON)
            
            //Now Fetching FB Data
            //self.getCurrentPlacesFromFacebook(minConfidenceLevel: self.FACEBOOK_CURRENTPLACE_MIN_CONFIDENCE_LEVEL)
            self.getFacebookNearbyPlaces()
        }
        
    }
    
    func parseGooglePlaceSearchJSON(json : JSON){
        
        //Checking whether the JSON content defines an error
        if json["status"] != "OK"{
            print("The Google Pace JSON contains an error")
            return
        }
        
        //Updating the Google places array
        let results = json["results"]
        
        for i in 0...results.count-1{
            
            /*print("LAT = \(results[i]["geometry"]["location"]["lat"])")
            print("LON = \(results[i]["geometry"]["location"]["lng"])")*/
            let lat = results[i]["geometry"]["location"]["lat"].double!
            let lon = results[i]["geometry"]["location"]["lng"].double!
            
            let placeCoordinates = CLLocation(latitude: lat, longitude: lon)
            let distanceInMeters = placeCoordinates.distance(from: self.currentLocation)
            let iconURL = URL(string: results[i]["icon"].string!)
            var iconImage : UIImage?
            
            if iconURL != nil {
                let imageData = NSData(contentsOf: iconURL!)
             
                if imageData != nil{
                    iconImage = UIImage(data: imageData! as Data)!
                }
                else{
                    print("Got a NIL for icon image data")
                }
             }
            
            self.googlePlaces.append(Place(
                name: results[i]["name"].string!,
                category: results[i]["types"][0].string!,
                distance: distanceInMeters,
                categoryIconImage: iconImage,
                placeImageURL: results[i]["photos"][0]["photo_reference"].string ?? nil,
                placeImageWidth: results[i]["width"][0]["width"].int ?? nil,
                placeImageHeight: results[i]["height"][0]["height"].int ?? nil,
                coordinates: placeCoordinates
            ))
        }
    }
    
    
    //MARK: - Facebook Nearby Place Search
    /***************************************************************/
    
    func getFacebookNearbyPlaces(){
        
        let placeFields = [FBSDKPlacesFieldKeyName, FBSDKPlacesFieldKeyAbout, FBSDKPlacesFieldKeyPlaceID, FBSDKPlacesFieldKeyLocation, FBSDKPlacesFieldKeyCategories]
        
        //resetting the current FB Places array
        self.facebookPlaces = []
        
        print("RETRIEVING FACEBOOK NEARBY PLACES DATA")
        
        let graphRequest = fbPlaceManager.placeSearchRequest(for: currentLocation, searchTerm: nil, categories: nil, fields: placeFields, distance: Double(PLACE_SEARCH_RADIUS)!, cursor: nil)
        
        if graphRequest == nil{
            return
        }
        
        print ("Nearyby Place Graph Request not nil :)")
        
        graphRequest!.start(completionHandler: { (connection, result, requestError) in
            
            if result == nil{
                print("FB NEARBY SEARCH ERROR = \(requestError!)")
            }
            else{
                print("FB NEARBY SEARCH RESULTS RECEIVED")
                print("RESULTS = \(result!)")
                
                if let myResult = result as? NSDictionary{
                    
                    let json = JSON(myResult)
                    
                    if json["data"] == JSON.null{
                        print("FB NEARBY SEARCH RESULTS CONTAIN AN ERROR")
                        return
                    }
                    
                    self.parseFacebookNearbyPlacesJSON(json: json["data"])
                    
                    //refreshing the UITableView
                    self.placeTableView.reloadData()
                    ProgressHUD.dismiss()
                    
                    
                }
                else{
                    print("Could not convert the Facebook Place Search NSDictionary to a JSON :(")
                }
            }
            
        })
    }
    
    
    func parseFacebookNearbyPlacesJSON(json : JSON){
        
        //Updating the Facebook places array
        
        if json.count == 0{
            print("NO RESULTS IN FB RESPONSE")
            
            self.facebookPlaces = []
            self.facebookPlaces.append(Place(
                name: "No results",
                category: "",
                distance: -1.0,
                categoryIconImage: nil,
                placeImageURL: "",
                placeImageWidth: 0,
                placeImageHeight: 0,
                coordinates: currentLocation)
            )
            
            return
        }
        
        print("FB RESULTS = \(json)")
        
        for i in 0...json.count-1{
            
            /*print("LAT = \(results[i]["geometry"]["location"]["lat"])")
             print("LON = \(results[i]["geometry"]["location"]["lng"])")*/
            let lat = json[i]["location"]["latitude"].double!
            let lon = json[i]["location"]["longitude"].double!
            
            let placeCoordinates = CLLocation(latitude: lat, longitude: lon)
            let distanceInMeters = placeCoordinates.distance(from: self.currentLocation)
            
            /*
             //Retrieving the topic icon from FB
             
             let params = ["icon_size" : "36", "fields" : "icon_url"]
             
             let graphRequest = FBSDKGraphRequest(graphPath: "/\(json[i]["category_list"][0]["id"].string!)", parameters: params, httpMethod: "GET").start(completionHandler: { (graphRequestConnection, result, requestError) in
             
             if result == nil{
             print("FB PLACE NAME = \(json[i]["name"].string!)")
             print("CATEGORY = \(json[i]["category_list"][0]["name"].string!) || \(json[i]["category_list"][0]["id"].string!)")
             print ("\n\nIcon graph request ERROR = \(requestError!)")
             }
             else{
             print("FB PLACE NAME = \(json[i]["name"].string!)")
             print("CATEGORY = \(json[i]["category_list"][0]["name"].string!) || \(json[i]["category_list"][0]["id"].string!)")
             print("\n\nIcon graph request results = \(result!)")
             }
             
             })*/
            
            self.facebookPlaces.append(Place(
                name: json[i]["name"].string!,
                category: json[i]["category_list"][0]["name"].string!,
                distance: distanceInMeters,
                categoryIconImage: nil,
                placeImageURL: "",
                placeImageWidth: 0,
                placeImageHeight: 0,
                coordinates: placeCoordinates
            ))
        }
    }
    
    
    
    
    /***************************************************************/
    //MARK: - CURRENT PLACE SEARCH
    /***************************************************************/
   
    func getCurrentPlaces(){
        
        print("Get Current Places - HERE 1")
        ProgressHUD.show()
        print("Get Current Places - HERE 2")
        getCurrentPlaceFromGoogleSDK()
        print("Get Current Places - AFTER GET CURRENT PLACE FROM GOOGLE SDK")
    }
    
    
    //MARK: - Google Current Place Search VIA SDK
    /***************************************************************/
    func getCurrentPlaceFromGoogleSDK(){
        
        print("Get Current Place from Google SDK - HERE 0")
        
        googlePlacesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            if let error = error {
                print("Google SDK Current Place error: \(error.localizedDescription)")
                self.locationManager.stopUpdatingLocation()
                self.locationCurrentlyStoppedByMe = true
                return
            }
            
            self.locationManager.stopUpdatingLocation()
            self.locationCurrentlyStoppedByMe = true
            
            print("Get Current Place from Google SDK - HERE 1")
            
            self.googlePlaces = []
            
            if let placeLikelihoodList = placeLikelihoodList {
                
                print("Get Current Place from Google SDK - HERE 2")
                
                for likelihood in placeLikelihoodList.likelihoods {
                    let place = likelihood.place
                    
                    let placeCoordinates = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
                    let distanceInMeters = placeCoordinates.distance(from: self.currentLocation)
                    
                  /*
                    print("Current Place candidate name \(place.name) at likelihood \(likelihood.likelihood)")
                    print("Current Place candidate address \(place.formattedAddress)")
                    print("Current Place candidate types \(place.types)") */
                    
                    
                    self.googlePlaces.append(Place(
                        name: place.name,
                        category: place.types[0],
                        distance: distanceInMeters,
                        categoryIconImage: nil,
                        placeImageURL: nil,
                        placeImageWidth: nil,
                        placeImageHeight: nil,
                        coordinates: placeCoordinates
                    ))
                }
            }
            
            if let placeLikelihoodList = placeLikelihoodList {
                
                print("Get Current Place from Google SDK - HERE 3")
                
                let place = placeLikelihoodList.likelihoods.first?.place
                if let place = place {
                    print("MOST LIKELY Place name = \(place.name)")
                    print("MOST LIKELY Place address = " + (place.formattedAddress?.components(separatedBy: ", ")
                        .joined(separator: "\n"))!)
                    print("MOST LIKELY Place types = \(place.types)")
                }
            }
            
            //Now Fetching FB Data
            print("Get Current Place from Google SDK - HERE 4")
            self.getCurrentPlacesFromFacebook(minConfidenceLevel: self.FACEBOOK_CURRENTPLACE_MIN_CONFIDENCE_LEVEL)
        })
        
    }
    
    
    
    
    
    //MARK: - Facebook Current Place Search
    /***************************************************************/
    
    func getCurrentPlacesFromFacebook(minConfidenceLevel: FBSDKPlaceLocationConfidence){
        
        let placeFields = [FBSDKPlacesFieldKeyName, FBSDKPlacesFieldKeyAbout, FBSDKPlacesFieldKeyPlaceID, FBSDKPlacesFieldKeyLocation]
        let placeFieldsWithConfidence = [FBSDKPlacesFieldKeyName, FBSDKPlacesFieldKeyAbout, FBSDKPlacesFieldKeyPlaceID, FBSDKPlacesFieldKeyLocation, FBSDKPlacesFieldKeyCategories, FBSDKPlacesFieldKeyConfidence]
        
        
        //resetting the current FB Places array
        self.facebookPlaces = []
        
        print("RETRIEVING FACEBOOK CURRENT PLACE DATA")
        
        self.fbPlaceManager.generateCurrentPlaceRequest(withMinimumConfidenceLevel: minConfidenceLevel, fields: placeFieldsWithConfidence) { (graphRequest, error) in
            if graphRequest != nil {
                print ("CurrentPlace Graph Request not nil :)")
              
                graphRequest!.start(completionHandler: { (connection, result, requestError) in
                    if result == nil{
                        print("FB ERROR = \(requestError!)")
                    } else{
                                print("FB RESULTS RECEIVED")
                        
                                if let myResult = result as? NSDictionary{
                                  
                                    let json = JSON(myResult)
                                    
                                    if json["data"] == JSON.null{
                                        print("FB RESULTS CONTAIN AN ERROR")
                                        return
                                    }
                                    
                                    self.parseFacebookCurrentPlaceJSON(json: json["data"])
                                    
                                    //refreshing the UITableView
                                    self.placeTableView.reloadData()
                                    ProgressHUD.dismiss()

                                    
                                } else{
                                    print("Could not convert the Facebook NSDictionary to a JSON :(")
                                }
                        }
                    
                })
            }
            else{
                print("Graph request instance is nil :( - Error = \(error!)")
            }
        }
    }
    
    func parseFacebookCurrentPlaceJSON(json : JSON){
       
        //Updating the Facebook places array
        
        if json.count == 0{
            print("NO RESULTS IN FB RESPONSE")
            
            self.facebookPlaces = []
            self.facebookPlaces.append(Place(
                name: "No results",
                category: "",
                distance: -1.0,
                categoryIconImage: nil,
                placeImageURL: "",
                placeImageWidth: 0,
                placeImageHeight: 0,
                coordinates: currentLocation)
            )
        
            return
        }
        
        print("FB RESULTS = \(json)")
        
        for i in 0...json.count-1{
            
            /*print("LAT = \(results[i]["geometry"]["location"]["lat"])")
             print("LON = \(results[i]["geometry"]["location"]["lng"])")*/
            let lat = json[i]["location"]["latitude"].double!
            let lon = json[i]["location"]["longitude"].double!
            
            let placeCoordinates = CLLocation(latitude: lat, longitude: lon)
            let distanceInMeters = placeCoordinates.distance(from: self.currentLocation)
            
            /*
            //Retrieving the topic icon from FB
            
            let params = ["icon_size" : "36", "fields" : "icon_url"]
            
            let graphRequest = FBSDKGraphRequest(graphPath: "/\(json[i]["category_list"][0]["id"].string!)", parameters: params, httpMethod: "GET").start(completionHandler: { (graphRequestConnection, result, requestError) in
                
                if result == nil{
                    print("FB PLACE NAME = \(json[i]["name"].string!)")
                    print("CATEGORY = \(json[i]["category_list"][0]["name"].string!) || \(json[i]["category_list"][0]["id"].string!)")
                    print ("\n\nIcon graph request ERROR = \(requestError!)")
                }
                else{
                    print("FB PLACE NAME = \(json[i]["name"].string!)")
                    print("CATEGORY = \(json[i]["category_list"][0]["name"].string!) || \(json[i]["category_list"][0]["id"].string!)")
                    print("\n\nIcon graph request results = \(result!)")
                }
                
            })*/
   
            self.facebookPlaces.append(Place(
                name: json[i]["name"].string!,
                //category: json[i]["category_list"][0]["name"].string!,
                category: "Confidence: \(json[i]["confidence_level"].string!)",
                distance: distanceInMeters,
                categoryIconImage: nil,
                placeImageURL: "",
                placeImageWidth: 0,
                placeImageHeight: 0,
                coordinates: placeCoordinates
            ))
        }
    }
    
    
    
    func sortNearbyPlacesByDistance(){
        
    }
    
    
    
    /***************************************************************/
    //MARK: - UITableView Management
    /***************************************************************/
    
    
    //MARK: - UITableViewDataSource Protocol Implementation
    /***************************************************************/
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isGoogleSelected{
            return googlePlaces.count
        } else{
            return facebookPlaces.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // CHANGER ICI POUR UTILISER SOIT FBPLACES SOIT GOOGLE PLACES
        if isGoogleSelected{
            return configureGoogleTableCell(tableView: tableView, cellForRowAt: indexPath)
        } else{
            return configureFacebookTableCell(tableView: tableView, cellForRowAt: indexPath)
        }
    }
    
    
    //MARK: - Table View Additional Operations
    /***************************************************************/
    
    func configureGoogleTableCell(tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceTableViewCell", for: indexPath) as? PlaceTableViewCell
            else{
                fatalError("The dequeued cell is not an instance of PlaceTableViewCaell.")
        }
        
        
        if googlePlaces.count == 0{
            return cell;
        }
        
        // Configure the cell
        //print("Configuring cell")
        cell.titleLabel.text = googlePlaces[indexPath.row].name
        cell.descriptionLabel.text = googlePlaces[indexPath.row].category
        
        let distanceValue = googlePlaces[indexPath.row].distance
        if(distanceValue >= 0){
            cell.distanceLabel.text = String(Int(googlePlaces[indexPath.row].distance)) + "m"
        }
        else{
            cell.distanceLabel.text = "--"
        }
        
        //loading icon images synchronously (should update to do so asynchronously)
        cell.iconImageView.image = googlePlaces[indexPath.row].categoryIconImage
        /*
         let iconURL = URL(string: googlePlaces[indexPath.row].categoryIconURL)
         
         if iconURL != nil {
         let imageData = NSData(contentsOf: iconURL!)
         
         if imageData != nil{
         cell.iconImageView.image = UIImage(data: imageData! as Data)
         }
         else{
         print("Got a NIL for icon image data while building the cell")
         }
         }*/
        
        
        return cell
    }
    
    
    func configureFacebookTableCell(tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceTableViewCell", for: indexPath) as? PlaceTableViewCell
            else{
                fatalError("The dequeued cell is not an instance of PlaceTableViewCaell.")
        }
        
        if facebookPlaces.count == 0{
            return cell;
        }
        
        // Configure the cell
        //print("Configuring cell")
        cell.titleLabel.text = facebookPlaces[indexPath.row].name
        cell.descriptionLabel.text = facebookPlaces[indexPath.row].category
        
        let distanceValue = facebookPlaces[indexPath.row].distance
        if(distanceValue >= 0){
            cell.distanceLabel.text = String(Int(facebookPlaces[indexPath.row].distance)) + "m"
        }
        else{
            cell.distanceLabel.text = "--"
        }
        
        cell.iconImageView.image = nil
        
        //loading icon images synchronously (should update to do so asynchronously)
        
        return cell
    }
 
    
    
  
}

