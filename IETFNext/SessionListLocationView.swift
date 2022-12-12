//
//  SessionListLocationView.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/12/22.
//

import SwiftUI

struct SessionListLocationView: View {
    @ObservedObject var location: Location
    var body: some View {
        Text("\(location.name!)")
    }
}
