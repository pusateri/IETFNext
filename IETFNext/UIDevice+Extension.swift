//
//  UIDevice+Extension.swift
//  IETFNext
//
//  Created by Tom Pusateri on 1/24/23.
//

import SwiftUI

#if !os(macOS)
extension UIDevice {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}
#endif
