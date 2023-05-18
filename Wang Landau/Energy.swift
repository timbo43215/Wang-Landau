//
//  Energy.swift
//  Final Project
//
//  Created by Tim Stack PHYS 440 on 4/28/23.
//

import Foundation

class Energy: ObservableObject {
    
    @Published var possibleEnergyArray: [Int] = []
    @Published var energy: [Double] = []
    @Published var deltaEValues: [Double] = []
}
