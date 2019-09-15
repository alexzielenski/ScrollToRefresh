
import AppKit

class EQSTRClipView: NSClipView {
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var proposedNewBounds = proposedBounds
        let constrained = super.constrainBoundsRect(proposedNewBounds)
        let scrollValue = proposedNewBounds.origin.y
        let over = scrollValue <= self.minimumScroll
        if self.isRefreshing && scrollValue <= 0 {
            if let headerView = self.headerView, over {
                proposedNewBounds.origin.y = 0 - headerView.frame.size.height
            }
            return NSMakeRect(constrained.origin.x, proposedNewBounds.origin.y, constrained.width, constrained.height)
        }
        return constrained
    }
    override var isFlipped: Bool {
        return true
    }
    override var documentRect: NSRect {
        var sup = super.documentRect
        if self.isRefreshing, let headerView = self.headerView {
            sup.size.height += headerView.frame.size.height
            sup.origin.y -= headerView.frame.size.height
        }
        return sup
    }
    private var isRefreshing: Bool {
        return (self.superview as? EQSTRScrollView)?.isRefreshing ?? false
    }
    private var headerView: NSView? {
        return (self.superview as? EQSTRScrollView)?.refreshHeader ?? nil
    }
    private var minimumScroll: CGFloat {
        return (self.superview as? EQSTRScrollView)?.minimumScroll ?? 0
    }
}

class EQSTRScrollView: MacScrollView {
    private(set) var isRefreshing: Bool = false
    private(set) var refreshHeader: NSView?
    private var refreshSpinner: NSProgressIndicator?
    private var refreshArrow: NSView?
    private var arrowLayer: CALayer?

    public var refreshBlock: (() ->())?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        self.refreshBlock = nil
        self.arrowLayer = nil
    }
    override func viewDidMoveToWindow() {
        self.createHeaderView()
    }
    private func createHeaderView() {
        if let refreshHeader = self.refreshHeader {
            refreshHeader.removeFromSuperview()
            self.refreshHeader = nil
        }
        self.verticalScrollElasticity = .allowed
        _ = self.contentView
        self.contentView.postsFrameChangedNotifications = true
        self.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(viewBoundsChanged), name: NSView.boundsDidChangeNotification, object: self.contentView)
        let contentRect = self.contentView.documentView?.frame ?? NSRect.zero
        self.refreshHeader = NSView(frame: NSRect(x: 0, y: 0 - 60, width: contentRect.size.width, height: 60))
        let arrowImage = NSImage(named: "arrow")
        let arrowX = floor((self.refreshHeader?.bounds.midX ?? 0) - (arrowImage?.size.width ?? 0) / 2)
        let arrowY = floor(self.refreshHeader?.bounds.minY ?? 0)
        self.refreshArrow = NSView(frame: NSRect(x: arrowX, y: arrowY, width: (arrowImage?.size.width ?? 0), height: (arrowImage?.size.height ?? 0)))
        self.refreshArrow?.wantsLayer = true
        self.arrowLayer = CALayer()
        self.arrowLayer?.contents = arrowImage?.cgImage(forProposedRect: nil, context: nil, hints: nil)
        self.arrowLayer?.frame = NSRectToCGRect(self.refreshArrow?.bounds ?? NSRect.zero)
        self.refreshArrow?.layer?.frame = NSRectToCGRect(self.refreshArrow?.bounds ?? NSRect.zero)
        if let arrowLayer = self.arrowLayer {
            self.refreshArrow?.layer?.addSublayer(arrowLayer)
        }
        self.refreshSpinner = NSProgressIndicator(frame: NSRect(x: floor((self.refreshHeader?.bounds.midX ?? 0) - 30), y: floor((self.refreshHeader?.bounds.midY ?? 0) - 20), width: 60, height: 40))
        self.refreshSpinner?.style = NSProgressIndicator.Style.spinning
        self.refreshSpinner?.isDisplayedWhenStopped = false
        self.refreshSpinner?.usesThreadedAnimation = true
        self.refreshSpinner?.isIndeterminate = true
        self.refreshSpinner?.isBezeled = false
        self.refreshSpinner?.sizeToFit()
        let refreshOriginX = floor((self.refreshHeader?.bounds.midX ?? 0) - (self.refreshSpinner?.frame.size.width ?? 0) / 2)
        let refreshOriginY = floor(self.refreshHeader?.bounds.minY ?? 0)
        self.refreshSpinner?.setFrameOrigin(NSPoint(x: refreshOriginX, y: refreshOriginY))
        self.refreshSpinner?.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        self.refreshArrow?.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        self.refreshHeader?.autoresizingMask = [.width, .minXMargin, .maxXMargin]
        if let refreshArrow = self.refreshArrow {
            self.refreshHeader?.addSubview(refreshArrow)
        }
        if let refreshSpinner = self.refreshSpinner {
            self.refreshHeader?.addSubview(refreshSpinner)
        }
        if let refreshHeader = self.refreshHeader {
            self.contentView.addSubview(refreshHeader)
        }
        self.contentView.scroll(to: NSPoint(x: contentRect.origin.x, y: 0))
        self.reflectScrolledClipView(self.contentView)
    }
    override func scrollWheel(with event: NSEvent) {
        if event.phase == .ended, self.overRefreshView && !self.isRefreshing {
            self.startLoading()
        }
        super.scrollWheel(with: event)
    }
    @objc func viewBoundsChanged(note: NSNotification? = nil) {
        if self.isRefreshing {
            return
        }
        if self.overRefreshView {
            self.arrowLayer?.transform = CATransform3DMakeRotation(CGFloat.pi, 0, 0, 1)
        } else {
            self.arrowLayer?.transform = CATransform3DMakeRotation(CGFloat.pi * 2, 0, 0, 1)
        }
    }
    private var overRefreshView: Bool {
        let clipView = self.contentView
        let bounds = clipView.bounds
        let scrollValue = bounds.origin.y
        let minimumScroll = self.minimumScroll
        return scrollValue <= minimumScroll
    }
    var minimumScroll: CGFloat {
        return 0 - (self.refreshHeader?.frame.size.height ?? 0)
    }
    public func startLoading() {
        self.isRefreshing = true
        self.refreshArrow?.isHidden = true
        self.refreshSpinner?.startAnimation(self)
        self.refreshBlock?()
    }
    public func stopLoading() {
        self.refreshArrow?.isHidden = false
        self.refreshSpinner?.stopAnimation(self)
        self.isRefreshing = false
        if let event = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 2, wheel1: 1, wheel2: 0, wheel3: 0),
            let nsevent = NSEvent(cgEvent: event) {
                self.scrollWheel(with: nsevent)
        }
    }
}
