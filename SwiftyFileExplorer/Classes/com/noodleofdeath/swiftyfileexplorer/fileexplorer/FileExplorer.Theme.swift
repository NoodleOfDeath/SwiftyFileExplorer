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

import Foundation

import SwiftyUTType
import SwiftyFileSystem
import SwiftyTextStyles

extension FileExplorer {

    /// Specifications for a file explorer theme.
    open class Theme: Bundle {
        
        ///
        public enum CodingKeys: String, CodingKey {
            case basePresentation = "BasePresentation"
            case componentPresentation = "ComponentPresentation"
            case resourceTypePresentation = "ResourceTypePresentation"
            case uttypePresentation = "UTTypePresentation"
        }
        
        ///
        public enum UIComponent: String {
            case NavigationHeaderTitle
            case PathToolBar
            case NavigationToolbar
            case SectionHeader
            case StatusBar
        }
        
        /// Enumerated type representing the different componentPresentationMap of a file explorer
        /// theme.
        public class Presentation {
            
            public let font: UIFont?
            public let paragraphStyle: NSParagraphStyle?
            open   var textAlignment: NSTextAlignment? { return paragraphStyle?.alignment }
            open   var lineBreakMode: NSLineBreakMode? { return paragraphStyle?.lineBreakMode }
            public let foregroundColor: UIColor?
            open   var textColor: UIColor? { return foregroundColor }
            public let backgroundColor: UIColor?
            public let ligature: Int?
            public let kern: CGFloat?
            public let strikethroughStyle: Int?
            public let underlineStyle: Int?
            public let strokeColor: UIColor?
            public let strokeWidth: Int?
            public let shadow: NSShadow?
            public let textEffect: String?
            public let attachment: NSTextAttachment?
            public let link: URL?
            public let baselineOffset: CGFloat?
            public let underlineColor: UIColor?
            public let strikethroughColor: UIColor?
            public let obliqueness: CGFloat?
            public let expansion: CGFloat?
            public let writingDirection: [Int]?
            public let verticalGlyphForm: Int?
            public let tintColor: UIColor?
            public let iconTintColor: UIColor?
            public let iconAlpha: CGFloat
            public let iconShadow: NSShadow?
            
            var asDict: TextStyle {
                var dict = TextStyle()
                dict[.font] = font
                dict[.paragraphStyle] = paragraphStyle
                dict[.foregroundColor] = foregroundColor
                dict[.backgroundColor] = backgroundColor
                dict[.ligature] = ligature
                dict[.kern] = kern
                dict[.strikethroughStyle] = strikethroughStyle
                dict[.underlineStyle] = underlineStyle
                dict[.strokeColor] = strokeColor
                dict[.strokeWidth] = strokeWidth
                dict[.shadow] = shadow
                dict[.textEffect] = textEffect
                dict[.attachment] = attachment
                dict[.link] = link
                dict[.baselineOffset] = baselineOffset
                dict[.underlineColor] = underlineColor
                dict[.strikethroughColor] = strikethroughColor
                dict[.obliqueness] = obliqueness
                dict[.expansion] = expansion
                dict[.writingDirection] = writingDirection
                dict[.verticalGlyphForm] = verticalGlyphForm
                dict[.tintColor] = tintColor
                dict[.iconTintColor] = iconTintColor
                dict[.iconAlpha] = iconAlpha
                dict[.iconShadow] = iconShadow
                return dict
            }
            
            public init?(dict: TextStyle?) {
                guard let dict = dict else { return nil }
                font = dict[.font] as? UIFont
                paragraphStyle = dict[.paragraphStyle] as? NSParagraphStyle
                foregroundColor = dict[.foregroundColor] as? UIColor ?? UIColor(dict: dict[.foregroundColor] as? TextStyle)
                backgroundColor = dict[.backgroundColor] as? UIColor ?? UIColor(dict: dict[.backgroundColor] as? TextStyle)
                ligature = dict[.ligature] as? Int
                kern = dict[.kern] as? CGFloat
                strikethroughStyle = dict[.strikethroughStyle] as? Int
                underlineStyle = dict[.underlineStyle] as? Int
                strokeColor = dict[.strokeColor] as? UIColor ?? UIColor(dict: dict[.strokeColor] as? TextStyle)
                strokeWidth = dict[.strokeWidth] as? Int
                shadow = dict[.shadow] as? NSShadow ?? NSShadow(dict: dict[.shadow] as? TextStyle)
                textEffect = dict[.textEffect] as? String
                attachment = dict[.attachment] as? NSTextAttachment
                link = dict[.link] as? URL
                baselineOffset = dict[.baselineOffset] as? CGFloat
                underlineColor = dict[.underlineColor] as? UIColor ?? UIColor(dict: dict[.underlineColor] as? TextStyle)
                strikethroughColor = dict[.underlineColor] as? UIColor ?? UIColor(dict: dict[.strikethroughColor] as? TextStyle)
                obliqueness = dict[.obliqueness] as? CGFloat
                expansion = dict[.expansion] as? CGFloat
                writingDirection = dict[.writingDirection] as? [Int]
                verticalGlyphForm = dict[.verticalGlyphForm] as? Int
                tintColor = dict[.tintColor] as? UIColor ?? UIColor(dict: dict[.tintColor] as? TextStyle)
                iconTintColor = dict[.iconTintColor] as? UIColor ?? UIColor(dict: dict[.iconTintColor] as? TextStyle)
                iconAlpha = dict[.iconAlpha] as? CGFloat ?? 1.0
                iconShadow = dict[.iconShadow] as? NSShadow ?? NSShadow(dict: dict[.iconShadow] as? TextStyle)
            }
            
            public func merged(with presentation: Presentation?) -> Presentation? {
                return merged(with: presentation?.asDict)
            }
            
            public func merged(with otherDict: TextStyle?) -> Presentation? {
                var dict = asDict
                if let otherDict = otherDict {
                    for (key, value) in otherDict {
                        dict[key] = value
                    }
                }
                return Presentation(dict: dict)
            }
            
        }
        
        // MARK: - Static Properties

        /// Default fallback theme singleton instance.
        open class var `default`: Theme? {
            guard
                let bundlePath = Bundle(for: FileExplorer.self).path(forResource: "SwiftyFileExplorer", ofType: "bundle"),
                let bundle = Bundle(path: bundlePath),
                let path = bundle.path(forResource: "default", ofType: "theme"),
                let theme = Theme(path: path) else { return nil }
            return theme
        }
        
        // MARK: - Instance Properties
        
        /// Mapping of `URLFileResourceType` to image names.
        open var resourceTypeMap: [URLFileResourceType: String] {
            var map = [URLFileResourceType: String]()
            map[.regular] = "public.content"
            map[.directory] = "public.directory"
            return map
        }
        
        // MARK: - Presentations
        
        /// Base presentation of this theme.
        open var basePresentation: Presentation?
        
        /// UIComponent presentation map of this theme.
        open var componentPresentationMap = [UIComponent: Presentation]()
        
        /// Resource type map of this theme.
        open var resourceTypePresentationMap = [URLFileResourceType: Presentation]()
        
        /// UTType presentation of this theme.
        open var uttypePresentationMap = [UTType: Presentation]()
        
        // MARK: - Thumbnails
        
        /// Default thumbnail used for any file.
        open var defaultThumbnail: UIImage? {
            return UIImage(named: "public.content", in: self, compatibleWith: nil)
        }
        
        // MARK: - Constructor Methods
        
        override public init?(path: String) {
            super.init(path: path)
            if let keyValues = infoDictionary?[CodingKeys.basePresentation] as? TextStyle {
                basePresentation = Presentation(dict: keyValues)
            }
            if let keyValues = infoDictionary?[CodingKeys.componentPresentation] as? [String: TextStyle] {
                for (name, value) in keyValues {
                    guard let component = UIComponent(rawValue: name) else { continue }
                    componentPresentationMap[component] = basePresentation?.merged(with: value) ?? Presentation(dict: value)
                }
            }
            if let keyValues = infoDictionary?[CodingKeys.resourceTypePresentation] as? [URLFileResourceType: TextStyle] {
                for (resourceType, value) in keyValues {
                    resourceTypePresentationMap[resourceType] = basePresentation?.merged(with: value) ?? Presentation(dict: value)
                }
            }
            if let keyValues = infoDictionary?[CodingKeys.uttypePresentation] as? [String: TextStyle] {
                for (key, value) in keyValues {
                    let uttype = UTType(key)
                    guard uttype != .Unknown else { continue }
                    uttypePresentationMap[uttype] = basePresentation?.merged(with: value) ?? Presentation(dict: value)
                }
            }
        }
        
        // MARK: - Instance Methods

        open func image(named name: String, compatibleWith: UITraitCollection? = nil) -> UIImage? {
            return UIImage(named: name, in: self, compatibleWith: nil)
        }
        
        /// Thumbnail used for a specific resource type.
        ///
        /// - Parameters:
        ///     - resourceType: to provide a thumbnail for.
        /// - Returns: thumbnail associated with `resourceType`, or `nil` if
        /// no such association exists.
        open func thumbnail(for resourceType: URLFileResourceType) -> UIImage? {
            guard let name = resourceTypeMap[resourceType] else { return nil }
            return image(named: name) ?? defaultThumbnail
        }

        /// Thumbnail used for a specific document.
        ///
        /// - Parameters:
        ///     - document: to provide a thumbnail for.
        /// - Returns: thumbnail associated with `document`, or `nil` if
        /// no such association exists.
        open func thumbnail(for document: Document?) -> UIImage? {
            guard let document = document else { return nil }
            return image(named: document.uttype.rawValue) ?? defaultThumbnail
        }
        
        ///
        open func presentation(for component: UIComponent) -> Presentation? {
            return componentPresentationMap[component] ?? basePresentation
        }
        
        ///
        open func presentation(for resourceType: URLFileResourceType) -> Presentation? {
            return resourceTypePresentationMap[resourceType] ?? basePresentation
        }
        
        ///
        open func presentation(for uttype: UTType) -> Presentation? {
            return uttypePresentationMap[uttype] ?? basePresentation
        }
        
        ///
        open func presentation(for document: Document?) -> Presentation? {
            guard let document = document else { return nil }
            return uttypePresentationMap[document.uttype] ?? basePresentation
        }

    }

}
