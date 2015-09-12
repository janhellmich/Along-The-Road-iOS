//
//  RestaurantFilterData.swift
//  AlongTheRoad
//
//  Created by Jan Hellmich on 9/11/15.
//  Copyright (c) 2015 Linus Aidan Meyer-Teruel. All rights reserved.
//

import UIKit

class RestaurantFilterData: NSObject {
    
    static let sharedInstance = RestaurantFilterData()
    
    var pricesSelcted: [Bool]
    var minRatingSelected: Int
    var openSelected: Bool
    var distanceFromOrigin: Double
    
    override init() {
        pricesSelcted = [false, false, false, false]
        minRatingSelected = 7
        openSelected = false
        distanceFromOrigin = 0.0
    }
}
