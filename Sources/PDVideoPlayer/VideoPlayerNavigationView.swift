//
//  VideoPlayerNavigationView.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/02/25.
//

import SwiftUI
#if canImport(UIKit) && !os(visionOS)
public struct VideoPlayerNavigationView:View{
    public init() {}

    @Environment(\.videoPlayerCloseAction) private var closeAction
    @Environment(\.videoPlayerIsMuted) private var isMutedBinding
    @Environment(\.videoPlayerControlsVisible) private var controlsVisibleBinding
    @Environment(\.videoPlayerOriginalRate) private var originalRateBinding
    @Environment(PDPlayerModel.self) private var model
    @Environment(\.videoPlayerLongpressAction) private var longpressAction
    public var body:some View{
        VStack {
            ZStack{
                if controlsVisibleBinding?.wrappedValue ?? true{
                    HStack(spacing:4){
                        if UIDevice.current.userInterfaceIdiom == .pad{
                            Button {
                                closeAction?()
                            } label: {
                                ZStack{
                                    Color.clear
                                    Image(systemName:"xmark.circle.fill")
                                        .foregroundStyle(.white)
                                        .fontDesign(.rounded)
                                        .opacity(0.8)
                                }
                                .contentShape(Rectangle())
                                
                            }
                            .frame(width:44,height:44)
                        }
                        AirPlayRoutePicker()
                            .transition(.opacity)
                            .frame(width:44,height:44)
                        Spacer()
                        volumeButton
                            .frame(width:44,height:44)
                    }
                }
            }
            .frame(height:44)
            .padding(.horizontal,12)
           
            if model.isLongpress{
                fastView
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration:0.12),value:model.isLongpress)
        .animation(.smooth(duration:0.12),value:controlsVisibleBinding?.wrappedValue)
        .onChange(of: model.isLongpress) {
            longpressAction?(model.isLongpress)
        }
        
    }
    private var fastView: some View {
        HStack(spacing:4){
            Text("\(min(2.0,(originalRateBinding?.wrappedValue ?? 1.0) * 2.0), specifier: "%.1f")x")
            Image(systemName:"forward.fill")
                .imageScale(.small)
        }
        .fontDesign(.rounded)
        .fontWeight(.semibold)
        .font(.callout)
        .foregroundStyle(.white)
        .opacity(0.8)
        .padding(.vertical,4)
        .padding(.horizontal,12)
        .background{
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
            
        }
    }
    private var volumeButton: some View {
        Button{
            if let binding = isMutedBinding {
                binding.wrappedValue.toggle()
            }
        }label:{
            ZStack{
                Color.clear
                if #available(iOS 18.0, *,visionOS 2.0, *) {
                    Image(systemName:"speaker")
                        .symbolVariant((isMutedBinding?.wrappedValue ?? false) ? .slash.fill : .fill)
                        .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.byLayer), options: .nonRepeating))
                } else {
                    Image(systemName:"speaker")
                        .symbolVariant((isMutedBinding?.wrappedValue ?? false) ? .slash.fill : .fill)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .contentShape(Rectangle())
            .foregroundStyle(.white)
            .fontDesign(.rounded)
            .opacity(0.8)
        }
    }
    private var pipButton: some View{
        Button{
            PiPManager.shared.start()
        }label:{
            ZStack{
                Color.clear
                Image(systemName:"pip.enter")
                    .foregroundStyle(.white)
                    .fontDesign(.rounded)
                    .opacity(0.8)
            }
            .contentShape(Rectangle())
            
        }
    }
}
#endif
