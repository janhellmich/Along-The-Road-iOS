//
//  ViewController.swift
//  AlongTheRoad
//
//  Created by Linus Aidan Meyer-Teruel on 8/29/15.
//  Copyright (c) 2015 Linus Aidan Meyer-Teruel. All rights reserved.
//

import UIKit
import MapKit
import GoogleMaps
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var startingPoint: UITextField!
    @IBOutlet weak var destination: UITextField!
    
    var coreLocationManager = CLLocationManager()
    var locationManager:LocationManager!
    var currentLocation:CLLocationCoordinate2D!
    
    let routeData = RouteDataModel.sharedInstance
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func selectedSegment(sender: UISegmentedControl) {
        println(sender.selectedSegmentIndex)
        switch sender.selectedSegmentIndex {
        case 0:
            routeData.modeOfTravel = MKDirectionsTransportType.Automobile
        case 1:
            routeData.modeOfTravel = MKDirectionsTransportType.Walking
        default:
            break
        }
    }
    
    @IBAction func submit(sender: UIButton) {
        // validate user input
        if startingPoint.text == "Current Location" && routeData.currentLocation == nil {
            errorLabel.text = "Cannot find current location. Please set manually."
        } else if destination.text == "" {
            errorLabel.text = "Please provide a destination."
        } else if startingPoint.text == destination.text {
            errorLabel.text = "Origin and destination cannot be the same."
        } else {
            errorLabel.text = ""
            performSegueWithIdentifier("show-routes", sender: nil)
        }
    }

    var placesClient: GMSPlacesClient?

    @IBAction func goToAutoComplete(sender: UITextField) {
        // specify whether the destination of origin field is clicked
        if (sender.placeholder == "Destination") {
            routeData.isDestination = true;
        } else {
            routeData.isDestination = false;
        }
        performSegueWithIdentifier("autocomplete", sender: nil)
    }

    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.view.endEditing(true)
    }
    
    
    override func viewWillAppear(animated: Bool) {
        placesClient = GMSPlacesClient()
        
        coreLocationManager.delegate = self
        coreLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        coreLocationManager.requestWhenInUseAuthorization()
        coreLocationManager.startUpdatingLocation()
        
        startingPoint.text = routeData.startingPoint
        destination.text = routeData.destination
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorLabel.text = ""
        routeData.startingPoint = "Current Location"
//        routeData.destination = "San Jose"
    }
    
    override func viewDidAppear(animated: Bool) {
        
        var nav = navigationController?.navigationBar
        nav?.barTintColor = UIColor(red: 102/255, green: 205/255, blue: 170/255, alpha: 0.1)
        nav?.tintColor = UIColor.whiteColor()
        nav?.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]

        
//        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
//        imageView.contentMode = UIViewContentMode.ScaleAspectFit
//        
//        let image = UIImage(named: "logo-white")
//        imageView.image = image
//        navigationItem.titleView = imageView
        
        
    }
    
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        var location = locations.last as! CLLocation
        
        routeData.currentLocation = location
        println(location.coordinate.latitude)
        println(location.coordinate.longitude)
        
        coreLocationManager.stopUpdatingLocation()
    }
    
    
    
}

