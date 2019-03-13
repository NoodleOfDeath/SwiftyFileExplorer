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

import SwiftyTextStyles

extension DocumentViewController {

    open class ColorScheme: Codable {
        
        public enum CodingKeys: String, CodingKey {
            case baseTextStyle
            case baseDocumentTextStyle
            case textStyles
        }
        
        // MARK: - Instance Properties
        
        /// Base text style of this color scheme.
        open var baseTextStyle: TextStyle
        
        /// Base document text style of this color scheme.
        open var baseDocumentTextStyle: TextStyle
        
        /// Style map of this color scheme.
        open var textStyles: [String: TextStyle]
        
        // MARK: - Constructor Methods
        
        ///
        public init(baseTextStyle: TextStyle? = nil, baseDocumentTextStyle: TextStyle? = nil, textStyles: [String: TextStyle]? = nil) {
            self.baseTextStyle = baseTextStyle ?? TextStyle()
            self.baseDocumentTextStyle = baseDocumentTextStyle ?? TextStyle()
            self.textStyles = textStyles ?? [String: TextStyle]()
        }
        
        ///
        public convenience init?(fileURL: URL) {
            guard let dict = NSDictionary(contentsOf: fileURL) as? [String: Any] else { return nil }
            let baseTextStyle = dict[CodingKeys.baseTextStyle.stringValue] as? TextStyle
            let baseDocumentTextStyle = dict[CodingKeys.baseDocumentTextStyle.stringValue] as? TextStyle
            let textStyles = dict[CodingKeys.textStyles.stringValue] as? [String: TextStyle]
            self.init(baseTextStyle: baseTextStyle,
                      baseDocumentTextStyle: baseDocumentTextStyle,
                      textStyles: textStyles)
        }
        
        // MARK: - Decodable Constructor Methods
        
        public required init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            guard let baseTextStyle = (try JSONSerialization.jsonObject(with: values.decode(Data.self, forKey: .baseTextStyle), options: []) as? TextStyle),
            let baseDocumentTextStyle = (try JSONSerialization.jsonObject(with: values.decode(Data.self, forKey: .baseDocumentTextStyle), options: []) as? TextStyle),
                let textStyles = (try JSONSerialization.jsonObject(with: values.decode(Data.self, forKey: .textStyles), options: []) as? [String: TextStyle]) else { throw TextStyleInitializationError() }
            self.baseTextStyle = baseTextStyle.synthesized()
            self.baseDocumentTextStyle = baseDocumentTextStyle.synthesized()
            self.textStyles = textStyles.mapValues { $0.synthesized() }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(JSONSerialization.data(withJSONObject: baseTextStyle.jsonObject, options: []), forKey: .baseTextStyle)
            try container.encode(JSONSerialization.data(withJSONObject: baseDocumentTextStyle.jsonObject, options: []), forKey: .baseDocumentTextStyle)
            try container.encode(JSONSerialization.data(withJSONObject: textStyles.mapValues { $0.jsonObject }, options: []), forKey: .textStyles)
        }
        
        // MARK: - Instance Methods
        
        ///
        ///
        /// - Parameters:
        ///     - id:
        ///     - fallback:
        /// - Returns:
        open func textStyle(for id: String?, fallback: Bool = false) -> TextStyle {
            guard let id = id else { return fallback ? baseDocumentTextStyle : TextStyle() }
            return textStyles[id] ?? (fallback ? baseDocumentTextStyle : TextStyle())
        }
        
        ///
        ///
        /// - Parameters:
        ///     - id:
        ///     - fallback:
        /// - Returns:
        open func textStyle<RawRepresentabelType: RawRepresentable>(for id: RawRepresentabelType?, fallback: Bool = false) -> TextStyle where RawRepresentabelType.RawValue == String {
            guard let id = id else { return fallback ? baseDocumentTextStyle : TextStyle() }
            return textStyles[id.rawValue] ?? (fallback ? baseDocumentTextStyle : TextStyle())
        }
        
    }

}
