/**
 * [INPUT]: Foundation、CoreGraphics 与 UIKit 几何类型；闭包由调用者同步提供
 * [OUTPUT]: 线程中立的 Then 协议与 with/do/then 链式配置，保留 NSObject、集合及几何类型遵循
 * [POS]: Extensions 的通用配置工具；显式 nonisolated 隔开包默认 MainActor，对象访问仍遵循调用者隔离
 * [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
 */
// swiftlint:disable all
// MIT 许可证 (MIT)
//
// 版权所有 (c) 2015 Suyeol Jeon (xoul.kr)
//
// 特此免费授予任何获得本软件副本和相关文档文件（"软件"）的人不受限制地
// 处理本软件的权利，包括不受限制地使用、复制、修改、合并、发布、分发、
// 再许可和/或出售软件副本，以及允许向其提供软件的人这样做，但须符合以下条件：
//
// 上述版权声明和本许可声明应包含在本软件的所有副本或主要部分中。
//
// 本软件按"原样"提供，不提供任何形式的明示或暗示的保证，包括但不限于
// 对适销性、特定用途的适用性和非侵权性的保证。在任何情况下，作者或版权
// 持有人均不对任何索赔、损害或其他责任负责，无论是在合同诉讼、侵权行为
// 或其他方面，由软件或软件的使用或其他交易引起、产生或与之相关。

import Foundation
#if !os(Linux)
  import CoreGraphics
#endif
#if os(iOS) || os(tvOS)
  import UIKit.UIGeometry
#endif

nonisolated public protocol Then {}

nonisolated extension Then where Self: Any {

  /// 使其可以在初始化和复制值类型后立即使用闭包设置属性。
  ///
  ///     let frame = CGRect().with {
  ///       $0.origin.x = 10
  ///       $0.size.width = 100
  ///     }
  @inlinable
  nonisolated public func with(_ block: (inout Self) throws -> Void) rethrows -> Self {
    var copy = self
    try block(&copy)
    return copy
  }

  /// 使其可以使用闭包执行某些操作。
  ///
  ///     UserDefaults.standard.do {
  ///       $0.set("devxoul", forKey: "username")
  ///       $0.set("devxoul@gmail.com", forKey: "email")
  ///       $0.synchronize()
  ///     }
  @inlinable
  nonisolated public func `do`(_ block: (Self) throws -> Void) rethrows {
    try block(self)
  }

}

nonisolated extension Then where Self: AnyObject {

  /// 使其可以在初始化后立即使用闭包设置属性。
  ///
  ///     let label = UILabel().then {
  ///       $0.textAlignment = .center
  ///       $0.textColor = UIColor.black
  ///       $0.text = "Hello, World!"
  ///     }
  @inlinable
  nonisolated public func then(_ block: (Self) throws -> Void) rethrows -> Self {
    try block(self)
    return self
  }

}

extension NSObject: Then {}

#if !os(Linux)
  extension CGPoint: Then {}
  extension CGRect: Then {}
  extension CGSize: Then {}
  extension CGVector: Then {}
#endif

extension Array: Then {}
extension Dictionary: Then {}
extension Set: Then {}

#if os(iOS) || os(tvOS)
  extension UIEdgeInsets: Then {}
  extension UIOffset: Then {}
  extension UIRectEdge: Then {}
#endif
// swiftlint:enable all
