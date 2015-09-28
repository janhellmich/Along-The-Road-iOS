//
//  MapHelpers.swift
//  AlongTheRoad
//
//  Created by Jan Hellmich on 9/14/15.
//  Copyright (c) 2015 Linus Aidan Meyer-Teruel. All rights reserved.
//

import Foundation

class MapHelpers {
    func getTotalDistance(point1: CLLocationCoordinate2D, point2: CLLocationCoordinate2D) -> Double {
//        var lat1 = startingPoint.latitude;
//        var lat2 = currentVenue.objectForKey("location")!.objectForKey("lat") as!Double
//        var lon1 = startingPoint.longitude
//        var lon2 = currentVenue.objectForKey("location")!.objectForKey("lng") as!Double
        var lat1 = point1.latitude
        var lat2 = point2.latitude
        var lon1 = point1.longitude
        var lon2 = point2.longitude
        
        
        func DegreesToRadians (value:Double) -> Double {
            return value * M_PI / 180.0
        }
        
        let R:Double = 6371000 // metres
        let latRad1 = DegreesToRadians(lat1)
        let latRad2 = DegreesToRadians(lat2)
        let change1 = DegreesToRadians(lat2-lat1)
        let change2 = DegreesToRadians(lon2-lon1)
        
        let l = Double(sin(change1/2) * sin(change1/2))
        let k = Double(cos(latRad1) * cos(latRad2) *
            sin(change2/2) * sin(change2/2))
        
        let a = Double( l + k)
        
        let c = 2 * atan2(sqrt(a), sqrt(1-a));
        
        let d = R * c;
        return d
    }
    
    // turn meters to miles
    func metersToMiles(distance: Double) -> Double {
        return distance * 0.0006214
    }
    
    // turn miles to meters
    func milesToMeters(distance: Double) -> Double {
        return distance / 0.0006214
    }
    
    func roundDouble (number: Double) -> Double {
        var num = number
        if number >= 100 {
            num = round(num)
        } else {
            num = round(num*10)/10
        }
        
        return num
    }

}