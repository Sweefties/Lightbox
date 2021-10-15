//
//  LightboxControllerDismissalDelegate.swift
//  
//
//  Created by Wlad Dicario on 15/10/2021.
//

import Foundation

public protocol LightboxControllerDismissalDelegate: AnyObject {
    func lightboxControllerWillDismiss(_ controller: LightboxController)
}
