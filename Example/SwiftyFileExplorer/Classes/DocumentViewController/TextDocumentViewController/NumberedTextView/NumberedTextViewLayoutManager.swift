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

/// A custom layout manager that draws line number labels in the left
/// margin of this text view.
open class NumberedTextViewLayoutManager: NSLayoutManager {
    
    // MARK: - Instance Properties
    
    /// The `text` contained in the `textStorage` object.
    open var text: String { return textStorage?.string ?? "" }
    
    /// Whether or not to draw line numbers. Default is `true`.
    open var lineNumbers = true
    
    /// Whether or not to draw whitespace characgers. Default is `false`.
    open var whitespaceCharacters = false
    
    ///
    open lazy var labelTextStyle = [NSAttributedStringKey : Any]()
    
    ///
    open lazy var whitespaceTextStyle = [NSAttributedStringKey : Any]()
    
    
    ///
    open lazy var gutterWidth: CGFloat = NumberedTextView.defaultGutterWidth
    
    ///
    open lazy var gutterMargin: CGFloat = NumberedTextView.defaultGutterMargin
    
    // MARK: - Private Properties
    
    /// An ordered array of the `y` coordinates of each line fragment
    fileprivate var lineFragments = SortedArray<CGFloat>(surjective: true)
    
    // MARK: - NSLayoutManager Methods
    
    override open func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
        
        guard lineNumbers == true else { return }
        
        var gutterRect = CGRect.zero
        var index = -1
        
        /// Draws the number label, relative to the `origin`, for
        /// the given `rect` parameter.
        /// - parameter rect: The rect of a line fragment. The `y`
        /// coordinate of `rect.origin` should be contained in
        /// `lineFragments`, otherwise the number `0` will be drawn.
        /// - parameter indexOffset: The value to add to the `index` of
        /// the line fragment since array indexing begins `0` while
        /// line numbering begins at 1.
        func drawLineNumberForRect(_ rect: CGRect, indexOffset: Int = 1) {
            
            // Get the index of the line fragment from its `y` coordinate
            index = indexOfParagraphForOffset(rect.y)
            
            // Adjust the `rect` position to be relative to `origin`
            let rect = rect.offsetBy(dx: origin.x, dy: origin.y)
            
            // Establish the dimensions of the label
            gutterRect = CGRect(x: 0.0,
                                y: rect.y + (CGFloat(indexOffset - 1) * rect.height),
                                width: gutterWidth,
                                height: rect.height)
            
            let ln = NSString(format: "%ld", index + indexOffset)
            let size = ln.size(withAttributes: labelTextStyle)
            
            // Notify the system to readjust the gutter width if the width
            // of the number label exceeds
            // `gutterWidth - (gutterMargin * 2.0)`
            if size.width > gutterWidth - (gutterMargin * 2.0)  {
                NotificationCenter.default.post(
                    name: NumberedTextView.gutterNeedsExtensionNotification,
                    object: self)
            }
            
            // Draw the number label
            ln.draw(
                in: gutterRect.offsetBy(dx: gutterRect.width - gutterMargin - size.width,
                                        dy: (gutterRect.height - size.height) / 2.0),
                withAttributes: labelTextStyle)
            
        }
        
        // Enumerate through each glyph range and draw number labels.
        enumerateLineFragments(forGlyphRange: glyphsToShow)
        { (rect: CGRect, usedRect: CGRect, textContainer: NSTextContainer, glyphRange: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            
            let characterRange = self.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
            let paragraphRange = self.text.ns.paragraphRange(for: characterRange)
            
            // Draw the line number label of each line fragment if it
            // occurs at the start of a new line. Otherwise, remove the
            // value from the cache, if it exists in the cache.
            if characterRange.location == paragraphRange.location {
                drawLineNumberForRect(rect)
            } else {
                self.lineFragments.remove(rect.y)
            }
            
            // Draw the line number label for the last line of text if
            // it only contains a new line character.
            if characterRange.max > self.text.length ||
                (characterRange.max >= self.text.length && self.text.lastLetter == "\n") {
                drawLineNumberForRect(rect, indexOffset: 2)
            }
            
        }
        
    }
    
    override open func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        
        // If line numbers are not enabled skip execution.
        guard lineNumbers == true else { return }
        
        // Since the `NSLayoutManager` does not necessarily begin glyph
        // generation at the `0` index, we must force it to if the line
        // fragment cache is `empty`, otherwise initial numbering will
        // be unpredictable and often incorrect.
        let glyphsToShow = lineFragments.count > 0 ? glyphsToShow : NSMakeRange(0, glyphsToShow.max)
        
        // Enumerate each glyph range and cache/remove the `y` coordinates
        // of each line fragment encountered.
        enumerateLineFragments(forGlyphRange: glyphsToShow)
        { (rect: CGRect, usedRect: CGRect, textContainer: NSTextContainer, glyphRange: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            
            let characterRange = self.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
            let paragraphRange = self.text.ns.paragraphRange(for: characterRange)
            
            // Cache the `y` coordinate of each line fragment if it
            // occurs at the start of a new line. Otherwise, remove the
            // value from the cache, if it exists in the cache.
            if characterRange.location == paragraphRange.location {
                _ = self.lineFragments.add(rect.y)
            } else {
                self.lineFragments.remove(rect.y)
            }
            
        }
        
    }
    
    // MARK: - Internal Methods
    
    // MARK: - Leaf
    
    /// Returns the index of t he `y` coordinate of a line fragment
    /// - returns: An index greater than or equal to zero if a line
    /// fragment exists with a `y` coordinate equal to `offset`,
    /// `-1` otherwise.
    open func indexOfParagraphForOffset(_ offset: CGFloat) -> Int {
        return lineFragments.indexOf(offset) ?? -1
    }
    
    /// Reset line number cache. This should be called after the `font`
    /// or `fontFace` of the text view has been changed.
    open func resetNumbering() {
        lineFragments.removeAll()
    }
    
}

