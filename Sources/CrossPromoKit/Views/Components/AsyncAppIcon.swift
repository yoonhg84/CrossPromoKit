import SwiftUI

/// Async image component for loading app icons with placeholder.
public struct AsyncAppIcon: View {
    private let url: URL
    private let size: CGFloat

    public init(url: URL, size: CGFloat = WarmEmbraceTokens.appIconSize) {
        self.url = url
        self.size = size
    }

    public var body: some View {
        Group {
            if url.scheme == "sf-symbol" {
                // SF Symbol: extract symbol name from host
                Image(systemName: url.host ?? "app.fill")
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(WarmEmbraceTokens.warmCoral)
                    .frame(width: size, height: size)
                    .background(WarmEmbraceTokens.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: WarmEmbraceTokens.cornerRadiusS))
            } else {
                // Network URL: use AsyncImage
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: WarmEmbraceTokens.cornerRadiusS))
            }
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: WarmEmbraceTokens.cornerRadiusS)
            .fill(WarmEmbraceTokens.secondaryBackground)
            .overlay {
                Image(systemName: "app.fill")
                    .font(.system(size: WarmEmbraceTokens.placeholderIconSize))
                    .foregroundStyle(WarmEmbraceTokens.secondaryText)
            }
    }
}
