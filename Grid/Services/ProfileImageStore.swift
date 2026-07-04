import UIKit

/// Persists the driver's profile picture as a downscaled JPEG in the app's
/// documents directory. Kept small (max 512px) so loading it is cheap.
enum ProfileImageStore {
    private static var url: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile.jpg")
    }

    static func load() -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    @discardableResult
    static func save(_ image: UIImage) -> UIImage? {
        let scaled = image.downscaled(maxDimension: 512)
        guard let data = scaled.jpegData(compressionQuality: 0.8) else { return nil }
        try? data.write(to: url, options: .atomic)
        return scaled
    }

    static func clear() {
        try? FileManager.default.removeItem(at: url)
    }
}

private extension UIImage {
    func downscaled(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
