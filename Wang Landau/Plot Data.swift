//
//  Plot Data.swift
//  Wang Landau
//
//  Created by IIT PHYS 440 on 5/18/23.
//

import Foundation

struct DensityOfStatesHistogram: Identifiable {
    
    var id: Int { energies }
    var energies: Int
    var densityOfStates: Double
    var histogram: Double
    
}
