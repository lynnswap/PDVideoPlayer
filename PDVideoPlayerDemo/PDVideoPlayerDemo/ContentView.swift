import SwiftUI
import PDVideoPlayer

struct ContentView: View {
    var body: some View {
        if let url = Bundle.main.url(forResource: "preview", withExtension: "mov") {
            PDVideoPlayerSampleView(sampleURL: url)
        } else {
            ContentUnavailableView(
                "Missing preview.mov",
                systemImage: "film",
                description: Text("Add preview.mov to the app bundle.")
            )
        }
    }
}

#Preview {
    ContentView()
}
