//
//  RestaurantStructure.swift
//  AlongTheRoad
//
//  Created by Linus Aidan Meyer-Teruel on 9/8/15.
//  Copyright (c) 2015 Linus Aidan Meyer-Teruel. All rights reserved.
//

import UIKit
import CoreLocation

struct RestaurantStructure {
    var name = ""
    var url = ""
    var imageUrl = ""
    var distanceToRoad = 0.0
    var address = ""
    var totalDistance = 0.0
    var openUntil = ""
    var rating = 0.0
    var priceRange = 0
    var location = CLLocationCoordinate2D()
    var streetAddress = ""
    var city = ""
    var state = ""
    var postalCode = ""
    var category = ""
    var tip = ""
}
