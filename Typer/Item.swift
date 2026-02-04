//
//  Item.swift
//  Typer
//
//  Created by Rannveer Singh on 4/2/2026.
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
