//
//  PDPlayerControllerModel.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/02/25.
//

import SwiftUI
@MainActor
@Observable public class PDPlayerControllerModel {
    public var isMuted: Bool
    public var isLongpress = false
    public var controlsVisible:Bool = true
    public var originalRate: Float = 1.0
    
    public var closeAction:UUID = UUID()
    
    public init(
        isMuted:Bool
    ) {
        self.isMuted = isMuted
    }
    
    func close(){
        self.closeAction = UUID()
    }
}


