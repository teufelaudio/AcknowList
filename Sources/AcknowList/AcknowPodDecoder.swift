//
// AcknowPodDecoder.swift
//
// Copyright (c) 2015-2025 Vincent Tourraine (https://www.vtourraine.net)
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

/// An object that decodes acknowledgements from CocoaPods acknowledgements plist file objects.
open class AcknowPodDecoder: AcknowDecoder {

    public init() {}

    /**
     Returns acknowledgements decoded from a CocoaPods acknowledgements plist file object.
     - Parameter data: The CocoaPods acknowledgements plist file object to decode.
     - Returns: A `AcknowList` value, if the decoder can parse the data.
     */
    public func decode(from data: Data) throws -> AcknowList {
        let rootDictionary = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: AnyObject]
        let preferenceSpecifiers = rootDictionary?["PreferenceSpecifiers"] as? [AnyObject]
        let headerItem = preferenceSpecifiers?.first as? [String: String]
        let footerItem = preferenceSpecifiers?.last as? [String: String]
        let headerText = headerItem?["FooterText"]
        let footerText = footerItem?["FooterText"]

        // Remove the header and footer
        let ackPreferenceSpecifiers = preferenceSpecifiers?.filter { item in
            guard let headerItem = headerItem, let footerItem = footerItem else {
                return false
            }

            return !item.isEqual(to: headerItem) && !item.isEqual(to: footerItem)
        } ?? []

        let acknowledgements: [Acknow] = ackPreferenceSpecifiers.compactMap { preferenceSpecifier in
            guard let title = preferenceSpecifier["Title"] as! String?,
                  let text = preferenceSpecifier["FooterText"] as! String? else {
                return nil
            }

            let textWithoutNewlines = AcknowParser.filterOutPrematureLineBreaks(text: text)
            return Acknow(title: title, text: textWithoutNewlines, license: preferenceSpecifier["License"] as? String)
        }

        return AcknowList(headerText: headerText, acknowledgements: acknowledgements, footerText: footerText)
    }

    internal struct K {
        static let DefaultHeaderText = "This application makes use of the following third party libraries:"
        static let DefaultFooterText = "Generated by CocoaPods - https://cocoapods.org"
    }
}
