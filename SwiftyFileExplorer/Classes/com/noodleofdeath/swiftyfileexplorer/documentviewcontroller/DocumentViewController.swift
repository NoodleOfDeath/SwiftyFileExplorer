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

import SwiftyFileSystem

@objc
public protocol DocumentViewControllerDelegate: class {
    
    @objc optional
    func documentViewController(_ documentViewController: DocumentViewController, didLoadContentsOf document: Document?)
    
    @objc optional
    func documentViewController(_ documentViewController: DocumentViewController, didRelease document: Document?)
    
    @objc optional
    func documentViewController(_ documentViewController: DocumentViewController, didFocus focusFrame: CGRect)
    
}

/// Base view controller class for viewing documents.
open class DocumentViewController: UIViewController {
    
    override open var prefersStatusBarHidden: Bool {
        return navigationController?.hidesBarsOnTap == true
    }
    
    override open var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    open weak var delegate: DocumentViewControllerDelegate?
    
    /// Document of this document view controller.
    open var document: Document? {
        didSet {
            loadContents()
            loadViewIfNeeded()
            contentsDidLoad()
        }
    }
    
    open var colorScheme: ColorScheme?
    
    ///
    open var focusFrame: CGRect? {
        didSet {
            guard let focusFrame = focusFrame else { return }
            delegate?.documentViewController?(self, didFocus: focusFrame)
        }
    }
    
    /// `true` if this document view controller should display its using
    /// fullscreen
    open var isFullscreen: Bool { return false }
    
    // MARK: - UI Components
    
    /// Main contrained view of this document view controller.
    /// Views added to this subview will be auto constrained when the
    /// keyboard appears and disappears.
    open lazy var constrainedView: UIView = {
        let view = UIView()
        return view
    }()
    
    // MARK: - Constructor Methods
    
    convenience public init(document: Document) {
        self.init(nibName: nil, bundle: nil)
        self.document = document
        loadContents()
        loadViewIfNeeded()
        contentsDidLoad()
    }
    
    // MARK: - UIViewController Methods
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = []
        navigationController?.hidesBarsOnTap = isFullscreen
        view.backgroundColor = .black
        view.addConstrainedSubview(constrainedView)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: NSNotification.Name.UIKeyboardWillChangeFrame,
            object: nil)
    }
    
    override open func loadViewIfNeeded() {
        super.loadViewIfNeeded()
        view.setNeedsDisplay()
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        document?.close()
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name.UIKeyboardWillChangeFrame,
            object: nil)
        delegate?.documentViewController?(self, didRelease: document)
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        loadViewIfNeeded()
    }
    
    /// This method should adjust the content of this view controller and
    /// is called whenever `document` is modified.
    open func loadContents() {
        
    }
    
    /// Always called after `loadContents` and `loadViewIfNeeded` are called.
    open func contentsDidLoad() {
        delegate?.documentViewController?(self, didLoadContentsOf: document)
    }
    
}

// MARK: - Event Handler Methods
extension DocumentViewController {
    
    @objc
    open func keyboardWillChangeFrame(_ notification: Notification) {
        guard let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let offset = keyboardFrame.origin.y < UIScreen.main.bounds.height ? -(UIScreen.main.bounds.height - keyboardFrame.origin.y - 75) : 0.0
        print(keyboardFrame)
        constrainedView.snp.updateConstraints { (dims) in
            dims.bottom.equalTo(view).offset(offset)
        }
        UIView.animate(withDuration: TimeInterval(UINavigationControllerHideShowBarDuration)) {
            self.view.layoutIfNeeded()
        }
    }
    
}
