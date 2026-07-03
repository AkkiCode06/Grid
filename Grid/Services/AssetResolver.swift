import SwiftUI
import UIKit

/// Resolution layer between circuit/seat data and bundled art. Real backdrops
/// (9:16 images in the asset catalog) and flyby clips (bundled .mp4) get
/// dropped in later under the names already declared on each Seat; every view
/// resolves through here, so swapping placeholders for real assets requires
/// no view changes.
enum AssetResolver {
    static func backdropImage(for seat: Seat) -> Image? {
        guard let uiImage = UIImage(named: seat.backdropAsset) else { return nil }
        return Image(uiImage: uiImage)
    }

    static func flybyClipURLs(for seat: Seat) -> [URL] {
        seat.flybyClips.compactMap {
            Bundle.main.url(forResource: $0, withExtension: "mp4")
        }
    }
}
