import SwiftUI
import UIKit

/// Resolution layer between circuit data and bundled art. Real paddock
/// backdrops (9:16 images in the asset catalog) and flyby clips (bundled
/// .mp4) get dropped in later under the names declared on each Circuit;
/// every view resolves through here, so swapping placeholders for real
/// assets requires no view changes.
enum AssetResolver {
    static func backdropImage(for circuit: Circuit) -> Image? {
        guard let uiImage = UIImage(named: circuit.paddockBackdropAsset) else { return nil }
        return Image(uiImage: uiImage)
    }

    static func flybyClipURLs(for circuit: Circuit) -> [URL] {
        circuit.flybyClips.compactMap {
            Bundle.main.url(forResource: $0, withExtension: "mp4")
        }
    }
}
