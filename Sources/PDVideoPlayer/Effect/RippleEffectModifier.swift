//
//  RippleEffectModifier.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/04/14.
//
import SwiftUI
#if canImport(UIKit)
struct RippleEffectModifier: ViewModifier {
    var model:PDPlayerModel
    @State private var store = RippleEffectStore()
    
    let configure: (inout RippleEffectStore) -> Void
    init(
        model:PDPlayerModel,
        configure: @escaping (inout RippleEffectStore) -> Void = { _ in }
    ) {
        self.model = model
        self.configure = configure
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear(){
                self.configure(&self.store)
            }
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.frame(in: .local).size
            } action: { newValue in
                if newValue.width <= .zero || newValue.height <= .zero{
                    return
                }
                store.viewSize = newValue
            }
            .overlay {
                ZStack {
                    ForEach(store.ripples) { ripple in
                        RippleCircle(
                            rippleColor: store.rippleColor,
                            center: ripple.center,
                            maxRadius: calcMaxRadius(
                                center: ripple.center,
                                region: ripple.region,
                                videoSize: store.viewSize
                            ),
                            animationDuration: store.animationDuration,
                            fadeOutDuration: store.fadeOutDuration,
                            startDate: ripple.startDate
                   
                        )
                        .clipShape(
                            ArcShape(
                                isLeft: (ripple.region == .left),
                                size: store.viewSize
                            )
                        )
                    }
                    if let item = store.latestItem {
                        // スキップ秒数表示などのUI
                        // （こちらも「最後のタップからまとめて消える」挙動に合わせるなら、
                        //  store.globalEndTime で一斉に消す実装に変更してもOK）
                        
                        let w = store.viewSize.width
                        let h = store.viewSize.height
                        
                        let isLeft: Bool = item.region == .left
                        let degrees: Double = isLeft ? 180 : 0
                        let xPos: CGFloat = isLeft ? w * 0.2 : w * 0.8
                        let yPos: CGFloat = h * 0.5
                        
                        VStack {
                            TriplePlayIconView(
                                model: model,
                                item: item,
                                totalRippleDuration: store.animationDuration + store.fadeOutDuration
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
                .animation(.smooth(duration: 0.12), value: store.latestItem == nil)
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
    /// RippleEffectModifierを簡単に呼ぶためのヘルパー
    public func rippleEffect(
        _ model:PDPlayerModel,
        configure: @escaping (inout RippleEffectStore) -> Void
    ) -> some View {
        modifier(
            RippleEffectModifier(model:model,configure: configure)
        )
    }
}
#endif
