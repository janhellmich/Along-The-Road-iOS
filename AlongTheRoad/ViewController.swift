//
//  ViewController.swift
//  AlongTheRoad
//
//  Created by Linus Aidan Meyer-Teruel on 8/29/15.
//  Copyright (c) 2015 Linus Aidan Meyer-Teruel. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate {

    
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
    
    @IBAction func submitRoute(sender: AnyObject) {
        
    }
    
    override func viewWillAppear(animated: Bool) {
        placesClient = GMSPlacesClient()
        
        routeData.startingPoint = "Current Location"
        routeData.destination = "San Jose"
        
        coreLocationManager.delegate = self
        coreLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        coreLocationManager.requestWhenInUseAuthorization()
        coreLocationManager.startUpdatingLocation()
        
        startingPoint.text = routeData.startingPoint
        destination.text = routeData.destination
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
    }
    
    
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        var location = locations.last as! CLLocation
        
        routeData.currentLocation = location
        println(location.coordinate.latitude)
        println(location.coordinate.longitude)
        
        coreLocationManager.stopUpdatingLocation()
    }
    
    
    
}

