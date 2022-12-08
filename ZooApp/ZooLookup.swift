//
//  ZooLookup.swift
//  ZooApp
//
//  Created by Ian O'Strander and Jaxon Goggins on 11/20/22.
//

import Foundation

struct ZooLookup{
    var name: String
    var data: Data
    
    init(name:String, data: Data){
        self.name = name
        self.data = data
    }
}
