//
//  LightboxControllerPageDelegate
//  
//
//  Created by Wlad Dicario on 15/10/2021.
//

import Foundation

public protocol LightboxControllerPageDelegate: AnyObject {
    func lightboxController(_ controller: LightboxController, didMoveToPage page: Int)
}
