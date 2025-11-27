//
//  MoodNote.swift
//  CatMood
//

import Foundation
import SwiftData

@Model
final class MoodNote {
    var id: UUID
    var moodIndex: Int?
    var text: String
    var date: Date
    
    init(moodIndex: Int? = nil, text: String, date: Date = Date()) {
        self.id = UUID()
        self.moodIndex = moodIndex
        self.text = text
        self.date = date
    }
}