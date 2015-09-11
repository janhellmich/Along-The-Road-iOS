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
    
    var priceSelcted: [Int]
    var minRatingSelected: Int
    var openSelected: Bool
    
    override init() {
        priceSelcted = [Int]()
        minRatingSelected = 0
        openSelected = false
    }
}
