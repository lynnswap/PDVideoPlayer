//
//  ArcShape.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/04/14.
//

import SwiftUI
struct ArcShape: Shape {
    let isLeft: Bool  // 左側なら true, 右側なら false など
    let width:CGFloat
    let height:CGFloat
    
    init(isLeft: Bool, size: CGSize) {
        self.isLeft = isLeft
        self.width = size.width
        self.height = size.height
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        if isLeft {
            // 左弧のパスを描く
            path.move(to: .init(x: 0, y: 0))
            path.addLine(to: .init(x: 0.4 * width, y: 0))
            let controlPoint = CGPoint(x: 0.5 * width, y: height / 2)
            path.addQuadCurve(
                to: CGPoint(x: 0.4 * width, y: height),
                control: controlPoint
            )
            path.addLine(to: CGPoint(x: 0, y: height))
            path.closeSubpath()
        } else {
            // 右弧のパスを描く
            path.move(to: .init(x: width, y: 0))
            path.addLine(to: .init(x: 0.6 * width, y: 0))
            let controlPoint = CGPoint(x: 0.5 * width, y: height / 2)
            path.addQuadCurve(
                to: CGPoint(x: 0.6 * width, y: height),
                control: controlPoint
            )
            path.addLine(to: CGPoint(x: width, y: height))
            path.closeSubpath()
        }
        
        return path
    }
}
