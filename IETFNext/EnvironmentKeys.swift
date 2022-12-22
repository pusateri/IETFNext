//
//  EnvironmentKeys.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/22/22.
//

import SwiftUI

struct LoaderKey: EnvironmentKey {
  struct Value {
    weak var value: JSONLoader?
  }

  static let defaultValue: Value = .init(value: nil)
}

extension EnvironmentValues {
  var loader: JSONLoader? {
    get { return self[LoaderKey.self].value }
    set { self[LoaderKey.self] = .init(value: newValue) }
  }
}

