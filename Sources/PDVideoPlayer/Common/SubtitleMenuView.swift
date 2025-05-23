#if os(iOS) || os(macOS)
import SwiftUI
import AVFoundation

/// A menu that lets the user choose between available subtitle tracks.
public struct SubtitleMenuView: View {
    @Environment(PDPlayerModel.self) private var model
    
    public init() {}
    
    public var body: some View {
        Picker(selection: Bindable(model).selectedSubtitle) {
            Text(String(localized: "Off")).tag(Optional<AVMediaSelectionOption>.none)
            ForEach(model.subtitleOptions, id: \.self) { option in
                Text(option.displayName)
                    .tag(Optional(option))
            }
        } label: {
            Label(String(localized: "Subtitles"), systemImage: "captions.bubble")
                .symbolVariant(model.selectedSubtitle == nil ? .none : .fill)
        }
        .task{ await model.loadSubtitleOptions() }
    }
}
#endif
