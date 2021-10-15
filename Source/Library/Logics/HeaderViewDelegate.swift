import UIKit

protocol HeaderViewDelegate: AnyObject {
    func didPressDeleteButton(deleteButton: UIButton)
    func didPressCloseButton(closeButton: UIButton)
}
