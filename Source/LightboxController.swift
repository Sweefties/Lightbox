import UIKit

open class LightboxController: UIViewController {
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var bottomStackView: UIStackView!
    @IBOutlet weak var bottomGradientView: UIView! {
        didSet {
            bottomGradientView.backgroundColor = .clear
            _ = bottomGradientView.addGradientLayer(gradientColors)
        }
    }
    @IBOutlet weak var bottomEmbeddedStackView: UIStackView! {
        didSet {
            bottomEmbeddedStackView.addArrangedSubview(infoLabel)
            bottomEmbeddedStackView.addArrangedSubview(separatorView)
            bottomEmbeddedStackView.addArrangedSubview(pageLabel)
            separatorView.widthAnchor.constraint(equalTo: bottomEmbeddedStackView.widthAnchor, constant: 0).isActive = true
        }
    }

    @IBOutlet private weak var deleteButton: UIButton! {
        didSet {
            deleteButton.setTitle(nil, for: UIControl.State())
            deleteButton.addTarget(self, action: #selector(didDelete), for: .touchUpInside)
            let title = NSAttributedString(string: LightboxConfig.DeleteButton.text,
                                           attributes: LightboxConfig.DeleteButton.textAttributes)
            deleteButton.setAttributedTitle(title, for: .normal)

            if let size = LightboxConfig.DeleteButton.size {
                deleteButton.frame.size = size
            } else {
                deleteButton.sizeToFit()
            }

            if let image = LightboxConfig.DeleteButton.image {
                deleteButton.setImage(image, for: UIControl.State())
            }
            deleteButton.isHidden = !LightboxConfig.DeleteButton.enabled
        }
    }
    @IBOutlet private weak var closeButton: UIButton! {
        didSet {
            closeButton.setTitle(nil, for: UIControl.State())
            closeButton.addTarget(self, action: #selector(didDismissScene), for: .touchUpInside)
            let title = NSAttributedString(string: LightboxConfig.CloseButton.text,
                                           attributes: LightboxConfig.CloseButton.textAttributes)
            closeButton.setAttributedTitle(title, for: UIControl.State())
            if let size = LightboxConfig.CloseButton.size {
                closeButton.frame.size = size
            } else {
                closeButton.sizeToFit()
            }
            if let image = LightboxConfig.CloseButton.image {
                closeButton.setImage(image, for: UIControl.State())
            }
            closeButton.isHidden = !LightboxConfig.CloseButton.enabled
        }
    }
    
    @objc
    private func didDismissScene() {
        didPressCloseButton(closeButton: closeButton)
    }

    @objc
    private func didDelete() {
        didPressDeleteButton(deleteButton: deleteButton)
    }

    // MARK: - Internal views
    
    lazy var scrollView: UIScrollView = { [unowned self] in
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = false
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.decelerationRate = UIScrollView.DecelerationRate.fast
        
        return scrollView
    }()
    
    lazy var overlayTapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(overlayViewDidTap(_:)))
        
        return gesture
    }()
    
    lazy var effectView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: effect)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        return view
    }()
    
    lazy var backgroundView: UIImageView = {
        let view = UIImageView()
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        return view
    }()
    
    // MARK: - Public views

    open fileprivate(set) lazy var infoLabel: InfoLabel = { [unowned self] in
        let label = InfoLabel(text: "")
        label.isHidden = !LightboxConfig.InfoLabel.enabled
        label.textColor = LightboxConfig.InfoLabel.textColor
        label.isUserInteractionEnabled = true
        label.delegate = self
        
        return label
    }()

    open fileprivate(set) lazy var pageLabel: UILabel = { [unowned self] in
        let label = UILabel(frame: .zero)
        label.isHidden = !LightboxConfig.PageIndicator.enabled
        label.numberOfLines = 1

        label.attributedText = NSAttributedString(string: label.text ?? "",
                                                  attributes: LightboxConfig.PageIndicator.textAttributes)
        label.sizeToFit()
        return label
    }()
    
    open fileprivate(set) lazy var separatorView: UIView = { [unowned self] in
        let view = UIView(frame: .zero)
        view.isHidden = !LightboxConfig.PageIndicator.enabled
        view.backgroundColor = LightboxConfig.PageIndicator.separatorColor
        view.frame = CGRect(x: 0, y: 0, width: bottomEmbeddedStackView.bounds.width, height: 1)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 1.0).isActive = true

        return view
    }()
    
    open fileprivate(set) lazy var overlayView: UIView = { [unowned self] in
        let view = UIView(frame: CGRect.zero)
        let gradient = CAGradientLayer()
        let colors = [UIColor(hex: "090909").withAlphaComponent(0), UIColor(hex: "040404")]
        
        view.addGradientLayer(colors)
        view.alpha = 0
        
        return view
    }()
    
    // MARK: - Properties

    open fileprivate(set) var currentPage = 0 {
        didSet {
            currentPage = min(numberOfPages - 1, max(0, currentPage))
            updatePage(currentPage + 1, numberOfPages)
            updateText(pageViews[currentPage].image.text)
            
            if currentPage == numberOfPages - 1 {
                seen = true
            }
            
            reconfigurePagesForPreload()
            
            pageDelegate?.lightboxController(self, didMoveToPage: currentPage)
            
            if let image = pageViews[currentPage].imageView.image, dynamicBackground {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.125) { [weak self] in
                    self?.loadDynamicBackground(image)
                }
            }
        }
    }
    
    open var numberOfPages: Int {
        return pageViews.count
    }
    
    open var dynamicBackground: Bool = false {
        didSet {
            if dynamicBackground == true {
                effectView.frame = view.frame
                backgroundView.frame = effectView.frame
                view.insertSubview(effectView, at: 0)
                view.insertSubview(backgroundView, at: 0)
            } else {
                effectView.removeFromSuperview()
                backgroundView.removeFromSuperview()
            }
        }
    }
    
    open var spacing: CGFloat = 20 {
        didSet {
            configureLayout(view.bounds.size)
        }
    }
    
    open var images: [LightboxImage] {
        get {
            return pageViews.map { $0.image }
        }
        set(value) {
            initialImages = value
            configurePages(value)
        }
    }
    
    open weak var pageDelegate: LightboxControllerPageDelegate?
    open weak var dismissalDelegate: LightboxControllerDismissalDelegate?
    open weak var imageTouchDelegate: LightboxControllerTouchDelegate?
    open internal(set) var presented = false
    open fileprivate(set) var seen = false
    
    lazy var transitionManager: LightboxTransition = LightboxTransition()
    var pageViews = [PageView]()
    var statusBarHidden = false
    private let gradientColors = [UIColor(hex: "040404").withAlphaComponent(0.1), UIColor(hex: "040404")]
    
    private var initialImages: [LightboxImage] = []
    private var initialPage: Int = 0

    public static func initialize(initialImages: [LightboxImage] = [],
                                  initialPage: Int = 0) -> LightboxController {
        let vc = LightBox.controller()
        vc.modalPresentationStyle = .fullScreen
        vc.initialImages = initialImages
        vc.initialPage = initialPage
        return vc
    }

    // MARK: - View lifecycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        // 9 July 2020: @3lvis
        // Lightbox hasn't been optimized to be used in presentation styles other than fullscreen.
        modalPresentationStyle = .fullScreen

        statusBarHidden = prefersStatusBarHidden

        view.backgroundColor = UIColor.black
        transitionManager.lightboxController = self
        transitionManager.scrollView = scrollView
        transitioningDelegate = transitionManager

        [scrollView, overlayView].forEach { view.addSubview($0) }
        view.bringSubviewToFront(stackView)
        view.bringSubviewToFront(bottomGradientView)
        view.bringSubviewToFront(bottomStackView)

        overlayView.addGestureRecognizer(overlayTapGestureRecognizer)

        configurePages(initialImages)

        goTo(initialPage, animated: false)
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bottomGradientView.resizeGradientLayer()
        // self.view.invalidateIntrinsicContentSize()
        scrollView.frame = view.bounds
        // relayout()
        if !presented {
            presented = true
            configureLayout(view.bounds.size)
        }
    }

    private func relayout() {
        do {
            let bottomPadding: CGFloat
            if #available(iOS 11, *) {
                bottomPadding = bottomEmbeddedStackView.safeAreaInsets.bottom
            } else {
                bottomPadding = 0
            }
            
            pageLabel.frame.origin = CGPoint(
                x: (bottomEmbeddedStackView.frame.width - pageLabel.frame.width) / 2,
                y: bottomEmbeddedStackView.frame.height - pageLabel.frame.height - 2 - bottomPadding
            )
        }
        separatorView.frame = CGRect(
            x: 0,
            y: pageLabel.frame.minY - 2.5,
            width: bottomStackView.frame.width,
            height: 0.5
        )
        
        infoLabel.frame.origin.y = separatorView.frame.minY - infoLabel.frame.height - 15
    }

    open override var prefersStatusBarHidden: Bool {
        return LightboxConfig.hideStatusBar
    }
    
    // MARK: - Rotation
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            self.configureLayout(size)
        }, completion: nil)
    }
    
    // MARK: - Configuration
    
    func configurePages(_ images: [LightboxImage]) {
        pageViews.forEach { $0.removeFromSuperview() }
        pageViews = []
        
        let preloadIndicies = calculatePreloadIndicies()
        
        for i in 0..<images.count {
            let pageView = PageView(image: preloadIndicies.contains(i) ? images[i] : LightboxImageStub())
            pageView.pageViewDelegate = self
            
            scrollView.addSubview(pageView)
            pageViews.append(pageView)
        }
        
        configureLayout(view.bounds.size)
    }
    
    func reconfigurePagesForPreload() {
        let preloadIndicies = calculatePreloadIndicies()
        
        for i in 0..<initialImages.count {
            let pageView = pageViews[i]
            if preloadIndicies.contains(i) {
                if type(of: pageView.image) == LightboxImageStub.self {
                    pageView.update(with: initialImages[i])
                }
            } else {
                if type(of: pageView.image) != LightboxImageStub.self {
                    pageView.update(with: LightboxImageStub())
                }
            }
        }
    }
    
    // MARK: - Pagination
    
    open func goTo(_ page: Int, animated: Bool = true) {
        guard page >= 0 && page < numberOfPages else {
            return
        }
        
        currentPage = page
        
        var offset = scrollView.contentOffset
        offset.x = CGFloat(page) * (scrollView.frame.width + spacing)
        
        let shouldAnimated = view.window != nil ? animated : false
        
        scrollView.setContentOffset(offset, animated: shouldAnimated)
    }
    
    open func next(_ animated: Bool = true) {
        goTo(currentPage + 1, animated: animated)
    }
    
    open func previous(_ animated: Bool = true) {
        goTo(currentPage - 1, animated: animated)
    }
    
    // MARK: - Actions
    
    @objc func overlayViewDidTap(_ tapGestureRecognizer: UITapGestureRecognizer) {
        expand(false)
    }
    
    // MARK: - Layout
    
    open func configureLayout(_ size: CGSize) {
        scrollView.frame.size = size
        scrollView.contentSize = CGSize(
            width: size.width * CGFloat(numberOfPages) + spacing * CGFloat(numberOfPages - 1),
            height: size.height)
        scrollView.contentOffset = CGPoint(x: CGFloat(currentPage) * (size.width + spacing), y: 0)
        
        for (index, pageView) in pageViews.enumerated() {
            var frame = scrollView.bounds
            frame.origin.x = (frame.width + spacing) * CGFloat(index)
            pageView.frame = frame
            pageView.configureLayout()
            if index != numberOfPages - 1 {
                pageView.frame.size.width += spacing
            }
        }
        
        configureLayout()
        overlayView.frame = scrollView.frame
        overlayView.resizeGradientLayer()
    }
    
    fileprivate func loadDynamicBackground(_ image: UIImage) {
        backgroundView.image = image
        backgroundView.layer.add(CATransition(), forKey: "fade")
    }
    
    func toggleControls(pageView: PageView?, visible: Bool, duration: TimeInterval = 0.1, delay: TimeInterval = 0) {
        let alpha: CGFloat = visible ? 1.0 : 0.0
        
        pageView?.playButton.isHidden = !visible
        
        UIView.animate(withDuration: duration, delay: delay, options: [], animations: {
            self.stackView.alpha = alpha
            self.bottomEmbeddedStackView.alpha = alpha
            pageView?.playButton.alpha = alpha
        }, completion: nil)
    }
    
    // MARK: - Helper functions
    func calculatePreloadIndicies () -> [Int] {
        var preloadIndicies: [Int] = []
        let preload = LightboxConfig.preload
        if preload > 0 {
            let lb = max(0, currentPage - preload)
            let rb = min(initialImages.count, currentPage + preload)
            for i in lb..<rb {
                preloadIndicies.append(i)
            }
        } else {
            preloadIndicies = [Int](0..<initialImages.count)
        }
        return preloadIndicies
    }
}

// MARK: - UIScrollViewDelegate

extension LightboxController: UIScrollViewDelegate {

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                          withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        var speed: CGFloat = velocity.x < 0 ? -2 : 2
        
        if velocity.x == 0 {
            speed = 0
        }
        
        let pageWidth = scrollView.bounds.width + spacing
        var x = scrollView.contentOffset.x + speed * 60.0
        
        if speed > 0 {
            x = ceil(x / pageWidth) * pageWidth
        } else if speed < -0 {
            x = floor(x / pageWidth) * pageWidth
        } else {
            x = round(x / pageWidth) * pageWidth
        }
        
        targetContentOffset.pointee.x = x
        currentPage = Int(x / pageWidth)
    }
}

// MARK: - PageViewDelegate

extension LightboxController: PageViewDelegate {
    
    func remoteImageDidLoad(_ image: UIImage?, imageView: UIImageView) {
        guard let image = image, dynamicBackground else {
            return
        }
        
        let imageViewFrame = imageView.convert(imageView.frame, to: view)
        guard view.frame.intersects(imageViewFrame) else {
            return
        }
        
        loadDynamicBackground(image)
    }
    
    func pageViewDidZoom(_ pageView: PageView) {
        let duration = pageView.hasZoomed ? 0.1 : 0.5
        toggleControls(pageView: pageView, visible: !pageView.hasZoomed, duration: duration, delay: 0.5)
    }
    
    func pageView(_ pageView: PageView, didTouchPlayButton videoURL: URL) {
        LightboxConfig.handleVideo(self, videoURL)
    }
    
    func pageViewDidTouch(_ pageView: PageView) {
        guard !pageView.hasZoomed else { return }
        
        imageTouchDelegate?.lightboxController(self, didTouch: images[currentPage], at: currentPage)
        
        let visible = (stackView.alpha == 1.0)
        toggleControls(pageView: pageView, visible: !visible)
    }
}

// MARK: - HeaderViewDelegate

extension LightboxController: HeaderViewDelegate {

    func didPressDeleteButton(deleteButton: UIButton) {
        deleteButton.isEnabled = false
        
        guard numberOfPages != 1 else {
            pageViews.removeAll()
            didPressCloseButton(closeButton: closeButton)
            return
        }
        
        let prevIndex = currentPage
        
        if currentPage == numberOfPages - 1 {
            previous()
        } else {
            next()
            currentPage -= 1
        }
        
        self.initialImages.remove(at: prevIndex)
        self.pageViews.remove(at: prevIndex).removeFromSuperview()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) { [weak self] in
            guard let self = self else {
                return
            }
            self.configureLayout(self.view.bounds.size)
            self.currentPage = Int(self.scrollView.contentOffset.x / self.view.bounds.width)
            deleteButton.isEnabled = true
        }
    }

    func didPressCloseButton(closeButton: UIButton) {
        closeButton.isEnabled = false
        presented = false
        dismissalDelegate?.lightboxControllerWillDismiss(self)
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - InfoLabelDelegate
extension LightboxController: InfoLabelDelegate {
    
    public func infoLabel(_ infoLabel: InfoLabel, didExpand expanded: Bool) {
        // update gradient layer
        _ = (expanded || infoLabel.fullText.isEmpty) ?
        bottomGradientView.removeGradientLayer() :
        bottomGradientView.addGradientLayer(gradientColors)
        // update expand
        footerView(didExpand: expanded)
    }

    private func footerView(didExpand expanded: Bool) {
        UIView.animate(withDuration: 0.25, animations: {
            self.overlayView.alpha = expanded ? 1.0 : 0.0
            self.deleteButton.alpha = expanded ? 0.0 : 1.0
        })
    }
}

// MARK: - Helpers
extension LightboxController {

    private func expand(_ expand: Bool) {
        expand ? infoLabel.expand() : infoLabel.collapse()
    }

    private func updatePage(_ page: Int, _ numberOfPages: Int) {
        let text = "\(page)/\(numberOfPages)"

        pageLabel.attributedText = NSAttributedString(string: text,
                                                      attributes: LightboxConfig.PageIndicator.textAttributes)
        pageLabel.sizeToFit()
    }

    private func updateText(_ text: String) {
        infoLabel.fullText = text

        if text.isEmpty {
            _ = bottomGradientView.removeGradientLayer()
        } else if !infoLabel.expanded {
            _ = bottomGradientView.addGradientLayer(gradientColors)
        }
    }
}

// MARK: - LayoutConfigurable
extension LightboxController: LayoutConfigurable {

    func configureLayout() {
        infoLabel.frame = CGRect(x: 0, y: 0, width: bottomEmbeddedStackView.frame.width - 17 * 2, height: 35)
        infoLabel.configureLayout()
    }
}
