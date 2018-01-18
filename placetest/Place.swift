//
//  Place.swift
//  placetest
//
//  Created by Benjamin Vigier on 11/20/17.
//  Copyright © 2017 Benjamin Vigier. All rights reserved.
//

import Foundation
import CoreLocation

class Place{
    
    let name: String
    let category: String
    let distance: Double
    let categoryIconImage: UIImage?
    let coordinates : CLLocation
    let altitude : Double = 0.0
    let placeImageURL: String?
    let placeImageWidth: Int?
    let placeImageHeight: Int?
    
    init(name: String, category: String, distance: Double, categoryIconImage: UIImage?, placeImageURL: String?, placeImageWidth: Int?, placeImageHeight: Int?, coordinates: CLLocation){
        
        self.name = name
        self.category = category
        self.distance = distance
        self.coordinates = coordinates
        self.categoryIconImage = categoryIconImage ?? nil
        self.placeImageURL = placeImageURL ?? nil
        self.placeImageWidth = placeImageWidth ?? nil
        self.placeImageHeight = placeImageHeight ?? nil
        
    }
    
}
