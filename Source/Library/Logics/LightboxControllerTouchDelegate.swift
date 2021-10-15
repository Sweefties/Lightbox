//
//  LightboxControllerTouchDelegate.swift
//  
//
//  Created by Wlad Dicario on 15/10/2021.
//

import UIKit

public protocol LightboxControllerTouchDelegate: AnyObject {
    func lightboxController(_ controller: LightboxController, didTouch image: LightboxImage, at index: Int)
}
