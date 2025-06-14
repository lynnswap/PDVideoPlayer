//
//  VideoPlayerNavigationView.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/02/25.
//

import SwiftUI
#if os(macOS)
public struct VideoPlayerNavigationView: View {
    public init() {}

    @Environment(\.videoPlayerOnClose) private var onClose
    @Environment(\.videoPlayerIsMuted) private var isMutedBinding
    @Environment(\.videoPlayerForegroundColor) private var foregroundColor

    public var body: some View {
        HStack {
            Button { onClose?(0) } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(foregroundColor)
            }
            AirPlayRoutePicker()
                .frame(width:44,height:44)
            Spacer()
            MuteButton()
                .frame(width:44,height:44)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .frame(height: 44)
    }
}
#elseif canImport(UIKit) && !os(visionOS)
public struct VideoPlayerNavigationView:View{
    public init() {}

    @Environment(\.videoPlayerOnClose) private var onClose
    @Environment(\.videoPlayerIsMuted) private var isMutedBinding
    @Environment(PDPlayerModel.self) private var model
    @Environment(\.videoPlayerOnLongPress) private var onLongPress
    @Environment(\.videoPlayerForegroundColor) private var foregroundColor
    public var body:some View{
        VStack {
            HStack(spacing:4){
                if UIDevice.current.userInterfaceIdiom == .pad{
                    Button {
                        onClose?(0)
                    } label: {
                        ZStack{
                            Color.clear
                            Image(systemName:"xmark.circle.fill")
                                .foregroundStyle(foregroundColor)
                                .fontDesign(.rounded)
                                .opacity(0.8)
                        }
                        .contentShape(Rectangle())
                        
                    }
                    .frame(width:44,height:44)
                }
                AirPlayRoutePicker()
                    .frame(width:44,height:44)
                Spacer()
                MuteButton()
                    .frame(width:44,height:44)
            }
            .frame(height:44)
            .padding(.horizontal,12)
           
            if model.isLongpress{
                fastView
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration:0.12),value:model.isLongpress)
        .onChange(of: model.isLongpress) {
            onLongPress?(model.isLongpress)
        }
        
    }
    private var fastView: some View {
        HStack(spacing:4){
            Text("\(min(2.0, model.originalRate * 2.0), specifier: "%.1f")x")
            Image(systemName:"forward.fill")
                .imageScale(.small)
        }
        .fontDesign(.rounded)
        .fontWeight(.semibold)
        .font(.callout)
        .foregroundStyle(foregroundColor)
        .opacity(0.8)
        .padding(.vertical,4)
        .padding(.horizontal,12)
        .background{
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
            
        }
    }
    private var pipButton: some View{
        Button{
            PiPManager.shared.start()
        }label:{
            ZStack{
                Color.clear
                Image(systemName:"pip.enter")
                    .foregroundStyle(foregroundColor)
                    .fontDesign(.rounded)
                    .opacity(0.8)
            }
            .contentShape(Rectangle())
            
        }
    }
}
#endif
extension View {
    @ViewBuilder
    func adaptiveSymbolReplaceTransition() -> some View {
        if #available(iOS 18.0, *, visionOS 2.0, *, macOS 15.0, *) {
            self.contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.byLayer), options: .nonRepeating))
        }else{
            self.contentTransition(.symbolEffect(.replace))
        }
    }
}
