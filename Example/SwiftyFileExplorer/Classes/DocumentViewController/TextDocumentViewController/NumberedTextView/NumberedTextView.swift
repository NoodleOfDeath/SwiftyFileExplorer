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

// MARK: - NumberedTextView Class

/// A `UITextView` subclass capable of displaying line numbers.
open class NumberedTextView: UITextView, NSLayoutManagerDelegate, NSTextStorageDelegate {
    
    // MARK: - Static Properties
    
    public static let gutterNeedsExtensionNotification = Notification.Name("NumberedTextView.GutterNeedsExtension")
    
    /// Default width of the gutter, if line numbering is enabled.
    public static let defaultGutterWidth: CGFloat = 40.0
    
    /// Default margin between the gutter and the
    public static let defaultGutterMargin: CGFloat = 5.0
    
    // MARK: - Instance Properties
    
    override open var frame: CGRect {
        didSet { textContainer.size = contentSize }
    }
    
    fileprivate var _font: UIFont?
    
    /// Bypasses defsult `font` implementation so that changing the value of
    /// this property does not require a complete redraw of the text.
    override open var font: UIFont! {
        get { return _font }
        set {
            if _font == nil { super.font = newValue }
            _font = newValue
            updateFont()
        }
    }
    
    /// Composite getter/setter for font name.
    open var fontName: String {
        get { return font?.fontName ?? "System" }
        set { font =? UIFont(name: newValue, size: fontSize) }
    }
    
    /// Composite getter/setter for font size.
    open var fontSize: CGFloat {
        get { return font?.pointSize ?? 12.0 }
        set { font =? UIFont(name: fontName, size: newValue) }
    }
    
    /// Actual layout manager being used
    open var numberedLayoutManager: NumberedTextViewLayoutManager? {
        return layoutManager as? NumberedTextViewLayoutManager
    }
    
    /// Plain text style.
    open var plainTextStyle: [NSAttributedStringKey : Any] {
        guard let font = font else { return [:] }
        return [ NSAttributedStringKey.font : font ]
    }
    
    /// Composite getter/setter for label text style.
    open var labelTextStyle: [NSAttributedStringKey : Any] {
        get { return numberedLayoutManager?.labelTextStyle ?? [NSAttributedStringKey : Any]() }
        set { numberedLayoutManager?.labelTextStyle = newValue }
    }
    
    /// Composite getter/setter for whitespace text style.
    open var whitespaceTextStyle: [NSAttributedStringKey : Any] {
        get { return numberedLayoutManager?.whitespaceTextStyle ?? [NSAttributedStringKey : Any]() }
        set { numberedLayoutManager?.whitespaceTextStyle = newValue }
    }
    
    /// Composite getter/setter for whether or not to show
    /// line numbers. Default is `true` if `numberedLayoutManager` is not `nil`.
    /// `false` otherwise.
    open var lineNumbers: Bool {
        get { return numberedLayoutManager?.lineNumbers ?? false }
        set {
            gutterWidth = newValue ? NumberedTextView.defaultGutterWidth : 0.0
            numberedLayoutManager?.lineNumbers = newValue
            setNeedsDisplay()
            updateNumberLabel()
            invalidateCharacterDisplayAndLayout()
        }
    }
    
    /// Composite getter/setter for whether or not to show
    /// whitespace characters. Default is `false`.
    open var whitespaceCharacters: Bool {
        get { return numberedLayoutManager?.whitespaceCharacters ?? false }
        set {
            numberedLayoutManager?.whitespaceCharacters = newValue
            invalidateCharacterDisplayAndLayout()
        }
    }
    
    /// Whether or not to display the page guide. Default is `false`.
    open var pageGuide: Bool = false
        { didSet { setNeedsDisplay() } }
    
    /// The column at which to draw the page guide. Default is `80`.
    open var pageGuideColumn: Int = 80
        { didSet { setNeedsDisplay() } }
    
    /// The width of the gutter. Default is `40.0`.
    open var gutterWidth: CGFloat = 40.0 {
        didSet {
            numberedLayoutManager?.gutterWidth = gutterWidth
            if textContainer.exclusionPaths.count > 0 {
                textContainer.exclusionPaths.removeFirst()
            }
            textContainer.exclusionPaths.insert(UIBezierPath(rect: CGRect(x: 0.0, y: 0.0,
                                                                          width: gutterWidth,
                                                                          height: .greatestFiniteMagnitude)), at: 0)
            setNeedsDisplay()
        }
    }
    
    /// The width of the gutter border. Default is `0.5`.
    open var gutterBorderWidth: CGFloat = 0.5
        { didSet { setNeedsDisplay() } }
    
    /// The width of the gutter margin between the number label and the border.
    /// Default is `5.0`.
    open var gutterMargin: CGFloat = 5.0 {
        didSet {
            numberedLayoutManager?.gutterMargin = gutterMargin
            setNeedsDisplay()
        }
    }
    
    /// Background color of the gutter. Default is `.clear`.
    open var gutterColor: UIColor = .clear
        { didSet { setNeedsDisplay() } }
    
    /// Color of the gutter border. Default is `.darkGray`.
    open var gutterBorderColor: UIColor = .darkGray
        { didSet { setNeedsDisplay() } }
    
    /// Color of the page guide. Default is `.darkGray`.
    open var pageGuideColor: UIColor = .gray
    
    // MARK: - Private Properties
    
    // MARK: - UI Components
    
    /// The number label drawn if `text` has fewer than two lines.
    fileprivate lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.text = "1"
        label.font = self.labelTextStyle[NSAttributedStringKey.font] as? UIFont
        let size = "1".ns.size(withAttributes: self.labelTextStyle)
        label.frame = CGRect(x: self.gutterWidth - size.width - self.gutterBorderWidth - self.gutterMargin,
                             y: self.textContainerInset.top,
                             width: size.width, height: size.height)
        return label
    }()
    
    // MARK: - Constructor Methods
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// Constructs a new numbered text view with a given frame and text
    /// storage.
    /// - parameter frame: Frame to initialize the text view with.
    /// - parameter textStorage: Text storage object to use for the text view.
    required public init(frame: CGRect, textStorage: NSTextStorage = NSTextStorage()) {
        
        let layoutManager = NumberedTextViewLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                         height: CGFloat.greatestFiniteMagnitude))
        
        textContainer.widthTracksTextView = true
        textContainer.heightTracksTextView = true
        
        layoutManager.allowsNonContiguousLayout = true
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        super.init(frame: frame, textContainer: textContainer)
        
        allowsEditingTextAttributes = false
        textStorage.delegate = self
        layoutManager.delegate = self
        
        contentInset = UIEdgeInsets(top: 20.0, left: 0.0, bottom: 20.0, right: 0.0)
        textContainerInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 40.0, right: 0.0)
        
        labelTextStyle = [ NSAttributedStringKey.font : font,
                           NSAttributedStringKey.foregroundColor : UIColor.black ]
        
        whitespaceTextStyle = [ NSAttributedStringKey.font : font,
                                NSAttributedStringKey.foregroundColor : UIColor.blue * 0.1 ]
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(extendGutter(_:)),
            name: NumberedTextView.gutterNeedsExtensionNotification,
            object: nil)
        
    }
    
    convenience public init() {
        self.init(frame: CGRect.zero)
    }
    
    // MARK: - UIView Methods
    
    override open func draw(_ rect: CGRect) {
        
        super.draw(rect)
        
        // Sets exclusion paths if line numbers are enabled
        resetExlusionPaths()
        
        // Draw left gutter
        if let context = UIGraphicsGetCurrentContext() {
            
            // Draw left gutter if line numbers are enabled.
            if lineNumbers {
                
                updateNumberLabel()
                
                context.setFillColor(gutterColor.cgColor)
                context.fill(CGRect(x: bounds.x, y: bounds.y,
                                    width: gutterWidth, height: bounds.height))
                
                context.setStrokeColor(gutterBorderColor.cgColor)
                context.setLineWidth(gutterBorderWidth)
                context.stroke(CGRect(x: bounds.x + gutterWidth - gutterBorderWidth, y: bounds.y,
                                      width: gutterBorderWidth, height: bounds.height))
                
            }
            
            // Draw page guide if enabled.
            if pageGuide {
                
                context.setFillColor(pageGuideColor.cgColor)
                context.setLineWidth(0.5)
                
                // x coordinate of the page guide
                let x = (CGFloat(pageGuideColumn) * "A".width(with: plainTextStyle)) + gutterWidth
                context.stroke(CGRect(x: x, y: bounds.y,
                                      width: 0.5, height: bounds.height))
                
            }
            
        }
        
    }
    
    // MARK:  - NSCoding Methods
    
    override open func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
    }
    
    // MARK: - UIKeyInput Methods
    
    override open func insertText(_ text: String) {
        super.insertText(text)
        updateNumberLabel()
    }
    
    override open func deleteBackward() {
        super.deleteBackward()
        updateNumberLabel()
    }
    
    // MARK: - Private Methods
    
    // MARK: - NumberedTextView Methods
    
    /// If line numbers are enabled, sets the exclusion paths to a left margin
    /// of width `gutterWidth`. Otherwise sets exclusion paths to and empty
    /// array.
    fileprivate func resetExlusionPaths() {
        textContainer.exclusionPaths = lineNumbers ?
            [UIBezierPath(rect: CGRect(x: 0.0, y: 0.0,
                                       width: gutterWidth, height: .greatestFiniteMagnitude))] : []
    }
    
    /// Updates the font lazily without requiring a complete refresh of _all_
    /// text.
    fileprivate func updateFont() {
        
        guard
            let attributedText = attributedText,
            let font = font
            else { return }
        
        labelTextStyle[NSAttributedStringKey.font] = font
        whitespaceTextStyle[NSAttributedStringKey.font] = font
        
        allowsEditingTextAttributes = true
        
        let newAttributedText = NSMutableAttributedString(attributedString: attributedText)
        newAttributedText.addAttribute(NSAttributedStringKey.font, value: font, range: newAttributedText.range)
        
        self.attributedText = newAttributedText
        numberedLayoutManager?.resetNumbering()
        
        allowsEditingTextAttributes = false
        
    }
    
    /// Draws a number label if `text` is less than two lines
    fileprivate func updateNumberLabel() {
        if lineNumbers && text.lineCount < 2 {
            addSubview(numberLabel)
        } else {
            numberLabel.removeFromSuperview()
        }
    }
    
    // MARK: - Event Handling Methods
    
    @objc
    fileprivate func extendGutter(_ notification: Notification) {
        gutterWidth += 20.0
    }
    
}




