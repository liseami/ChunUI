
import SwiftUI
 

extension CGSize {
    /// Scales up a point-size CGSize into its pixel representation.
    /// 
    var pixelSize: CGSize {
        let scale = UIScreen.cc_active.scale
        return CGSize(width: self.width * scale, height: self.height * scale)
    }
}
