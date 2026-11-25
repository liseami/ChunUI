//
//  RainbowLineView.swift
//  YUI
//
//  Created by 赵翔宇 on 2025/3/1.
//

import SwiftUI

 

public struct RainbowLineView: View {
    @State private var time: Float = 0 // 用于动画

    let now = Date.now

    public init() {}

    public var body: some View {
        TimelineView(.animation) { timeline in
            let elapsedTime = now.distance(to: timeline.date)
            Rectangle()
                .visualEffect { content, proxy in
                    content
                        .colorEffect(
                            CCShaders.sinebow(
                                .float2(proxy.size),
                                .float(elapsedTime * 1.4)
                            )
                        )
                }
        }
        .frame(height: 320)
    }
}

#Preview {
    RainbowLineView()
}
