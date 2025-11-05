//
//  Item.swift
//  CatMood
//
//  Created by Анастасия Савенко on 06.11.2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
