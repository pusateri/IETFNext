//
//  Meeting+Extension.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/29/23.
//

import SwiftUI
import CoreData


extension Meeting {
    var month: String {
        if let start = date {
            let parts = start.split(separator: "-")
            return String(parts[1])
        }
        return "00"
    }
    var day: String {
        if let start = date {
            let parts = start.split(separator: "-")
            return String(parts[2])
        }
        return "00"
    }
}
