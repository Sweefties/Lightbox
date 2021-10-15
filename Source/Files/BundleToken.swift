//
//  BundleToken.swift
//  
//
//  Created by Wlad Dicario on 15/10/2021.
//

import Foundation

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
