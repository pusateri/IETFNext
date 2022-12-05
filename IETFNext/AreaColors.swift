//
//  AreaColors.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/3/22.
//

import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

public let areaColors: [String: UInt] = [
    "app": 0x99ccff,    // blue
    "art": 0x99ccff,    // blue
    "gen": 0x99ffcc,    // teal
    "int": 0xcccccc,    // grey
    "ietf": 0xffff99,   // yellow
    "irtf": 0x99FFFF,   // cyan
    "ops": 0xff99ff,    // magenta
    "rai": 0xffcc99,    // orange
    "rtg": 0xcc99ff,    // purple
    "sec": 0xff9999,    // red
    "tsv": 0xccff99,    // green
]
