//
//  ThinLine.swift
//  YUI
//
//  Created by 赵翔宇 on 2025/2/24.
//

import SwiftUI

 
 

public var thinLine: some View {
    Rectangle().frame(height: 1.2).foregroundStyle(Color.cc.border)
}

public struct ThinLine: View {
    let color: Color
    public init(color: Color = Color.cc.border) {
        self.color = color
    }
    public var body: some View {
        thinLine
    }

    var thinLine: some View {
        Rectangle().frame(height: 1.2).foregroundStyle(color)
    }
}

#Preview {
    ThinLine()
}
