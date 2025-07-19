//
//  RippleEffectStore.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/04/14.
//

import SwiftUI
import Combine
import AVFoundation

// どの領域をタップしたかを示す列挙型
enum TapRegion {
    case left, middle, right
}

// 個々の波紋を表すデータ
struct RippleData: Identifiable,Equatable {
    let id = UUID()
    let center: CGPoint
    let region: TapRegion
    let startDate: Date
    let skipDuration:Int
}

/// 波紋描画に必要な情報を保持し、
/// 外部から「タップされた座標」を受け取ったら波紋を追加する役割を担う。
@MainActor
@Observable public class RippleEffectStore {
    // 最大５枚まで保持する
    private let maxRippleCount = 5
    
    var ripples: [RippleData] = []
    
    /// 最後のタップから「アニメーション＋フェードアウト時間」が経過するまで
    /// 全リップルを残すための終了時刻
    var globalEndTime: Date?

    var latestItem :RippleData?

    // 以下の3つは設定パラメータ
    public var rippleColor: Color = .white.opacity(0.22)
    public var animationDuration: Double = 0.6
    public var fadeOutDuration: Double = 0.3
    
    var viewSize: CGSize = .zero

    // 最後にリップル全削除を行うTaskを保持し、連続でタップされた場合はキャンセル→再スケジュール
    private var removeAllTask: Task<(), Never>?

    /// 外部 (例: handleDoubleTap) から呼び出すことで、波紋を追加
    func addRipple(at location: CGPoint, duration: Int) {
        // 中央タップはリップル発生させない
        let region = getTapRegion(for: location, in: viewSize)
        guard region != .middle else { return }

        let ripple = RippleData(
            center: location,
            region: region,
            startDate: Date(),
            skipDuration: duration
        )

        
        ripples.append(ripple)
        self.latestItem = ripple
        
        // 最後のタップから (アニメーション + フェードアウト) 後に全削除したいので globalEndTime を更新
        let totalDuration = animationDuration + fadeOutDuration
        globalEndTime = Date().addingTimeInterval(totalDuration)

        // 既存の全削除タスクがあればキャンセルして作り直す
        removeAllTask?.cancel()
        removeAllTask = Task {
            // globalEndTime まで待機
            try? await Task.sleep(for: .seconds(totalDuration))
            guard !Task.isCancelled else { return }
            clearAllRipples()
        }
    }

    /// 全リップルをまとめて削除してリセット
    func clearAllRipples() {
        ripples.removeAll()
        latestItem = nil
        globalEndTime = nil
    }

    private func getTapRegion(for location: CGPoint, in size: CGSize) -> TapRegion {
        guard size.width > 0 else { return .middle }
        let ratio = location.x / size.width
        if ratio < 0.4 {
            return .left
        } else if ratio > 0.6 {
            return .right
        } else {
            return .middle
        }
    }
}
