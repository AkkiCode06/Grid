import SwiftUI
import CoreText

enum GilroyWeight: String, CaseIterable {
    case light = "Gilroy-Light"
    case regular = "Gilroy-Regular"
    case medium = "Gilroy-Medium"
    case semiBold = "Gilroy-SemiBold"
    case bold = "Gilroy-Bold"
    case extraBold = "Gilroy-ExtraBold"
    case heavy = "Gilroy-Heavy"
    case black = "Gilroy-Black"
}

extension Font {
    static func gilroy(_ size: CGFloat, _ weight: GilroyWeight = .semiBold) -> Font {
        .custom(weight.rawValue, size: size)
    }
}

/// Registers the bundled Gilroy family at launch — avoids Info.plist
/// UIAppFonts plumbing with the generated plist.
enum FontLoader {
    static func registerAll() {
        for weight in GilroyWeight.allCases {
            guard let url = Bundle.main.url(forResource: weight.rawValue, withExtension: "ttf") else {
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
