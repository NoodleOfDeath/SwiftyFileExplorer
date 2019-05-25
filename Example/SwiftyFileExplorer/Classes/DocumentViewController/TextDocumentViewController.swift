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
import SwiftyFileSystem
import SwiftyFileExplorer

/// Document view controller for viewing text files.
open class TextDocumentViewController: ZoomableDocumentViewController {
    
    /// Text view of this text document view controller.
    fileprivate lazy var textView: UITextView = {
        let textView = UITextView()
        textView.delegate = self
        textView.font = UIFont(name: "Courier New", size: 12.0)
        return textView
    }()
    
    /// Dismiss keyboard button of this text document vew controller.
    fileprivate lazy var dismissKeyboardButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .red
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 1.0
        button.layer.cornerRadius = 5.0
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(didPress(dismissKeyboardButton:)), for: .touchUpInside)
        return button
    }()
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = []
        viewForZooming = textView
    }

    override open func loadContents() {
        super.loadContents()
        guard let document = document else { return }
        document.open { _ in
            self.textView.text = document.textContents
        }
    }
    
    override open func setNeedsDisplay() {
        super.setNeedsDisplay()
    }

}

// MARK: - UITextViewDelegate Methods
extension TextDocumentViewController: UITextViewDelegate {
    
    open func textViewDidChange(_ textView: UITextView) {
        document?.textContents = textView.text
    }
    
    open func textViewDidBeginEditing(_ textView: UITextView) {
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.setToolbarHidden(true, animated: true)
        constrainedView.addSubview(dismissKeyboardButton)
        dismissKeyboardButton.snp.makeConstraints { (dims) in
            dims.width.equalTo(40.0)
            dims.height.equalTo(40.0)
            dims.bottom.equalTo(constrainedView).offset(-10.0)
            dims.right.equalTo(constrainedView).offset(-10.0)
        }
    }
    
    open func textViewDidEndEditing(_ textView: UITextView) {
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.setToolbarHidden(false, animated: true)
        dismissKeyboardButton.removeFromSuperview()
    }
    
}

// MARK: - Event Handler Methods
extension TextDocumentViewController {
    
    @objc
    open func didPress(dismissKeyboardButton: UIButton) {
        UIApplication.shared.keyWindow?.endEditing(true)
    }
    
}
