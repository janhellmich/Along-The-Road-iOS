//
//  DetailViewController.swift
//  AlongTheRoad
//
//  Created by Linus Aidan Meyer-Teruel on 9/7/15.
//  Copyright (c) 2015 Linus Aidan Meyer-Teruel. All rights reserved.
//

import UIKit
import WebKit
import MapKit
import AddressBook


class DetailViewController: UIViewController {

    var restaurantData = RestaurantDataModel.sharedInstance
    
    @IBAction func getDirections(sender: AnyObject) {
        let restaurant = self.restaurantData.selectedRestaurant
        let coord = restaurant.location
        
        let street = restaurant.streetAddress
        let city = restaurant.city
        let state = restaurant.state
        let ZIP = restaurant.postalCode
        let addressDict =
        [kABPersonAddressStreetKey as String: street,
            kABPersonAddressCityKey as String: city,
            kABPersonAddressStateKey as String: state,
            kABPersonAddressZIPKey as String: ZIP]
        
        
        let place = MKPlacemark(coordinate: coord,
            addressDictionary: addressDict)
        
        let mapItem = MKMapItem(placemark: place)
        
        let options = [MKLaunchOptionsDirectionsModeKey:
        MKLaunchOptionsDirectionsModeDriving]
        
        mapItem.openInMapsWithLaunchOptions(options)

    }
    
    @IBOutlet var containerView : UIView! = nil
    var webView: WKWebView?
    
    override func loadView() {
        super.loadView()
        
        self.webView = WKWebView()
        self.view = self.webView!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let restaurant = self.restaurantData.selectedRestaurant


        
        let url = NSURL(string: restaurant.url)
        
        if url != nil {
            let req = NSURLRequest(URL:url!)
            self.webView!.loadRequest(req)
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
