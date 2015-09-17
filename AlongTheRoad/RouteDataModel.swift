//
//  RouteDataModel.swift
//  AlongTheRoad
//
//  Created by Linus Aidan Meyer-Teruel on 8/31/15.
//  Copyright (c) 2015 Linus Aidan Meyer-Teruel. All rights reserved.
//

import UIKit
import MapKit

class RouteDataModel: NSObject {
    
    static let sharedInstance = RouteDataModel()

    var destination: String
    var startingPoint: String
    var route: MKRoute?
    var routes: [AnyObject]
    var searchRadius:Int
    var searchSection: String
    var restaurants: [AnyObject]
    var isDestination: Bool
    var restaurantDictionary: [String: AnyObject]
    var selectedRestaurant: AnyObject?
    var currentLocation: CLLocation?
    var modeOfTravel: MKDirectionsTransportType

    override init(){
        routes = []
        destination = ""
        startingPoint = ""
        searchRadius = 5000//Default at the beginning
        searchSection = "food"
        restaurants = [AnyObject]()
        isDestination = false
        restaurantDictionary = [String: AnyObject]()
        modeOfTravel = MKDirectionsTransportType.Automobile
    }
    
}