import UIKit

final class LoadingIndicator: UIView {

    private var indicator: UIActivityIndicatorView!

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        
        backgroundColor = UIColor.darkGray
        layer.cornerRadius = bounds.size.width / 2
        clipsToBounds = true
        alpha = 0
        
        indicator = UIActivityIndicatorView()
        indicator.style = .medium
        indicator.startAnimating()
        
        addSubview(indicator)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        indicator.center = CGPoint(x: bounds.size.width/2, y: bounds.size.height/2)
    }
}
