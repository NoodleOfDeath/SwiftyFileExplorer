//
// The MIT License (MIT)
//
// Copyright © 2019 NoodleOfDeath. All rights reserved.
// NoodleOfDeath
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

import SnapKit

/// Base scrollable view controller class for viewing documents.
open class ZoomableDocumentViewController: DocumentViewController {
    
    /// Content size of `scrollView` and `viewForZooming` of this document
    /// view controller.
    open var contentSize: CGSize = .zero {
        didSet {
            
            viewForZooming?.frame.size = contentSize
            scrollView.contentSize = contentSize
            
            let widthExceedsBounds = contentSize.width > view.width
            let heightExceedsBounds = contentSize.height > view.height
            
            let minimumZoomScale =
                min(widthExceedsBounds ? UIScreen.main.bounds.width / contentSize.width : 0.5,
                    heightExceedsBounds ? UIScreen.main.bounds.height / contentSize.height : 0.5)
            
            scrollView.minimumZoomScale = minimumZoomScale
            scrollView.zoomScale = widthExceedsBounds || heightExceedsBounds ? minimumZoomScale : 1.0
            
        }
    }
    
    /// `true` if this document view controller is in the middle of zooming.
    open var isZooming: Bool = false
    
    /// Closest value to lock to.
    open var zoomStep: CGFloat = 0.05

    // MARK: - UI Components
    
    /// View that will be made zoomable in this document view controller.
    open var viewForZooming: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            guard let viewForZooming = viewForZooming else { return }
            scrollView.addSubview(viewForZooming)
            loadViewIfNeeded()
        }
    }
    
    /// Scroll view of this document view controller.
    open lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.clipsToBounds = true
        scrollView.maximumZoomScale = 4.0
        return scrollView
    }()
    
    /// Zoom label view of this document view controller.
    fileprivate lazy var zoomLabelView: UIView = {
        let view = UIView()
        view.addConstrainedSubview(zoomLabel)
        view.backgroundColor = .black * 0.75
        view.layer.cornerRadius = 5.0
        view.clipsToBounds = true
        return view
    }()
    
    /// Zoom label of this document view controller.
    fileprivate lazy var zoomLabel: UILabel =  {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Constructor Methods
    
    // MARK: - UIViewController Methods
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        constrainedView.addConstrainedSubview(scrollView)
    }
    
    override open func loadViewIfNeeded() {
        super.loadViewIfNeeded()
        contentSize = view.size
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: {  _ in
            self.contentSize = self.view.size
        })
    }
    
    /// This method should adjust the content of this view controller and
    /// is called whenever `document` is modified.
    override open func loadContents() {
        super.loadContents()
    }
    
}

extension ZoomableDocumentViewController: UIScrollViewDelegate {
    
    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return viewForZooming
    }
    
    open func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let zoomScale = scrollView.zoomScale
        zoomLabel.text = String(format: "%.0f%%", (zoomScale * 100.0).rounded())
        //let dw: CGFloat = zoomScale >= 1 ? 0.0 : abs(view.width - contentSize.width / zoomScale)/2.0 * zoomScale
        //scrollView.contentInset = UIEdgeInsets(top: 0, left: dw, bottom: 0, right: dw)
    }
    
    open func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        isZooming = true
        zoomLabelView.alpha = 1.0
        constrainedView.addSubview(zoomLabelView)
        zoomLabelView.snp.makeConstraints { (dims) in
            dims.center.equalTo(constrainedView)
            dims.width.equalTo(80.0)
            dims.height.equalTo(40.0)
        }
    }
    
    open func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        isZooming = false
        scrollView.zoomScale = round(scale * 20) / 20
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if self.isZooming { return }
            UIView.animate(withDuration: 0.5, animations: {
                self.zoomLabelView.alpha = 0.0
            }) { _ in
                self.zoomLabelView.removeFromSuperview()
            }
        }
    }
    
}
