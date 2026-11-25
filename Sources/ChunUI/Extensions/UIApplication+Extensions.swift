
import SwiftUI
 

extension UIApplication {
    /// This computed property finds and returns the key window of the application
    /// 
    static var keyWindow: UIWindow? {
        // 1. Get the shared application instance and its connected scenes
        // 2. Convert the scenes to UIWindowScene objects
        // 3. Get all windows from these scenes
        // 4. Find the first window that is marked as the key window
        UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
