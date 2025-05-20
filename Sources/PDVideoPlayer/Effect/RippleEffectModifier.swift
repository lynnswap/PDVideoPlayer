//
//  RippleEffectModifier.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/04/14.
//
import SwiftUI
#if canImport(UIKit)
struct RippleEffectModifier: ViewModifier {
    @Environment(PDPlayerModel.self) private var model
    
    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.frame(in: .local).size
            } action: { newValue in
                if newValue.width <= .zero || newValue.height <= .zero{
                    return
                }
                model.rippleStore.viewSize = newValue
            }
            .overlay {
                ZStack {
                    ForEach(model.rippleStore.ripples) { ripple in
                        RippleCircle(
                            rippleColor: model.rippleStore.rippleColor,
                            center: ripple.center,
                            maxRadius: calcMaxRadius(
                                center: ripple.center,
                                region: ripple.region,
                                videoSize: model.rippleStore.viewSize
                            ),
                            animationDuration: model.rippleStore.animationDuration,
                            fadeOutDuration: model.rippleStore.fadeOutDuration,
                            startDate: ripple.startDate
                   
                        )
                        .clipShape(
                            ArcShape(
                                isLeft: (ripple.region == .left),
                                size: model.rippleStore.viewSize
                            )
                        )
                    }
                    if let item = model.rippleStore.latestItem {
                        // スキップ秒数表示などのUI
                        // （こちらも「最後のタップからまとめて消える」挙動に合わせるなら、
                        //  model.rippleStore.globalEndTime で一斉に消す実装に変更してもOK）
                        
                        let w = model.rippleStore.viewSize.width
                        let h = model.rippleStore.viewSize.height
                        
                        let isLeft: Bool = item.region == .left
                        let degrees: Double = isLeft ? 180 : 0
                        let xPos: CGFloat = isLeft ? w * 0.2 : w * 0.8
                        let yPos: CGFloat = h * 0.5
                        
                        VStack {
                            TriplePlayIconView(
                                model: model,
                                item: item,
                                totalRippleDuration: model.rippleStore.animationDuration + model.rippleStore.fadeOutDuration
                            )
                            .rotation3DEffect(
                                .degrees(degrees),
                                axis: (x: 0, y: 1, z: 0)
                            )
                            
                            if item.skipDuration > .zero {
                                HStack(spacing: 4) {
                                    Text("\(item.skipDuration)")
                                        .contentTransition(.numericText())
                                        .animation(.default, value: item.skipDuration)
                                    Text(String(localized: "seconds"))
                                }
                            }
                        }
                        .transition(.opacity)
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .opacity(0.8)
                        .position(x: xPos, y: yPos)
                    }
                }
                .animation(.smooth(duration: 0.12), value: model.rippleStore.latestItem == nil)
                .allowsHitTesting(false)
            }
    }
    private func calcMaxRadius(center: CGPoint,
                               region: TapRegion,
                               videoSize: CGSize) -> CGFloat {
        let w = videoSize.width
        let h = videoSize.height
        let leftMaxX = w * 0.4
        let rightMinX = w * 0.6
        
        let boundingRect: CGRect
        switch region {
        case .left:
            boundingRect = CGRect(x: 0, y: 0, width: leftMaxX, height: h)
        case .right:
            boundingRect = CGRect(x: rightMinX, y: 0, width: w - rightMinX, height: h)
        case .middle:
            boundingRect = .zero
        }
        
        let corners = [
            CGPoint(x: boundingRect.minX, y: boundingRect.minY),
            CGPoint(x: boundingRect.maxX, y: boundingRect.minY),
            CGPoint(x: boundingRect.minX, y: boundingRect.maxY),
            CGPoint(x: boundingRect.maxX, y: boundingRect.maxY)
        ]
        
        let maxDist = corners
            .map { hypot($0.x - center.x, $0.y - center.y) }
            .max() ?? 0
        
        return maxDist
    }
}

extension View {
    public func rippleEffect() -> some View {
        modifier(RippleEffectModifier())
    }
}
#endif
