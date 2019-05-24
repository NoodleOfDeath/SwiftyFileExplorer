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

extension URLFileResourceType: Codable {}

extension FileExplorer {

    /// Specifications for a file explorer theme.
    open class Theme: Bundle {
        
        ///
        public enum CodingKeys: String, CodingKey {
            case baseTextStyle = "BaseTextStyle"
            case componentTextStyle = "ComponentTextStyle"
            case resourceTypeTextStyle = "ResourceTypeTextStyle"
            case uttypeTextStyle = "UTTypeTextStyle"
        }
        
        ///
        public enum UIComponent: String {
            case navigationHeaderTitle = "NavigationHeaderTitle"
            case pathToolBar = "PathToolBar"
            case navigationToolbar = "NavigationToolbar"
            case sectionHeader = "SectionHeader"
            case statusBar = "StatusBar"
        }
        
        // MARK: - Static Properties

        /// Default fallback theme singleton instance.
        open class var `default`: Theme? {
            guard
                let bundlePath = Bundle(for: FileExplorer.self).path(forResource: "SwiftyFileExplorer", ofType: "bundle"),
                let bundle = Bundle(path: bundlePath),
                let path = bundle.path(forResource: "default", ofType: "fexptheme"),
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
        
        // MARK: - TextStyles
        
        /// Base textStyle of this theme.
        open var baseTextStyle: TextStyle?
        
        /// UIComponent textStyle map of this theme.
        open var componentTextStyleMap = [UIComponent: TextStyle]()
        
        /// Resource type map of this theme.
        open var resourceTypeTextStyleMap = [URLFileResourceType: TextStyle]()
        
        /// UTType textStyle of this theme.
        open var uttypeTextStyleMap = [UTType: TextStyle]()
        
        // MARK: - Thumbnails
        
        /// Default thumbnail used for any file.
        open var defaultThumbnail: UIImage? {
            return UIImage(named: "public.content", in: self, compatibleWith: nil)
        }
        
        // MARK: - Constructor Methods
        
        override public init?(path: String) {
            super.init(path: path)
            baseTextStyle = (infoDictionary?[CodingKeys.baseTextStyle] as? TextStyle)?.decoded()
            if let keyValues = infoDictionary?[CodingKeys.componentTextStyle] as? [String: TextStyle] {
                for (name, value) in keyValues {
                    guard let component = UIComponent(rawValue: name) else { continue }
                    componentTextStyleMap[component] = (baseTextStyle + value ?? value).decoded()
                }
            }
            if let keyValues = infoDictionary?[CodingKeys.resourceTypeTextStyle] as? [URLFileResourceType: TextStyle] {
                for (resourceType, value) in keyValues {
                    resourceTypeTextStyleMap[resourceType] = (baseTextStyle + value ?? value).decoded()
                }
            }
            if let keyValues = infoDictionary?[CodingKeys.uttypeTextStyle] as? [String: TextStyle] {
                for (key, value) in keyValues {
                    let uttype = UTType(key)
                    guard uttype != .Unknown else { continue }
                    uttypeTextStyleMap[uttype] = (baseTextStyle + value ?? value).decoded()
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
        open func textStyle(for component: UIComponent) -> TextStyle? {
            return componentTextStyleMap[component] ?? baseTextStyle
        }
        
        ///
        open func textStyle(for resourceType: URLFileResourceType) -> TextStyle? {
            return resourceTypeTextStyleMap[resourceType] ?? baseTextStyle
        }
        
        ///
        open func textStyle(for uttype: UTType) -> TextStyle? {
            return uttypeTextStyleMap[uttype] ?? baseTextStyle
        }
        
        ///
        open func textStyle(for document: Document?) -> TextStyle? {
            guard let document = document else { return nil }
            return uttypeTextStyleMap[document.uttype] ?? baseTextStyle
        }

    }

}
