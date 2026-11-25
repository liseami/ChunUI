// An even more obfuscated version of https://github.com/kylebshr/ScreenCorners

import SwiftUI

 

extension UIScreen {
    private static let cornerRadiusKey: String = {
        let base64Components = [
            "UmFkaXVz",      // "Radius"
            "Q29ybmVy",      // "Corner"
            "ZGlzcGxheQ==",  // "display"
            "Xw=="           // "_"
        ]
        
        return base64Components
            .compactMap { Data(base64Encoded: $0) }
            .compactMap { String(data: $0, encoding: .utf8) }
            .reversed()
            .joined()
    }()
    
    public var displayCornerRadius: CGFloat {
        let key = Data(Self.cornerRadiusKey.utf8)
            .base64EncodedString()
            .data(using: .utf8)
            .flatMap { Data(base64Encoded: $0) }
            .flatMap { String(data: $0, encoding: .utf8) } ?? Self.cornerRadiusKey
        
        guard let cornerRadius = self.value(forKey: key) as? CGFloat else {
            assertionFailure("Failed to detect screen corner radius")
            return 0
        }
        
        return cornerRadius
    }
}
