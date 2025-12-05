import SwiftUI
import AVFoundation
import Photos
import Combine
//import SwiftUIViewRecorder

struct RecorderExampleView: View {
    @StateObject private var recorderVM = ViewRecordingSessionViewModel<URL>()
    @State private var session: ViewRecordingSession<URL>? = nil
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        VStack(spacing: 30) {
            // This view will be recorded
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(Color.purple)
                Text("Recording This View 🎬")
                    .font(.title).foregroundColor(.white)
            }
            .frame(width: 300, height: 180)
            
            // Start
            Button("Start Recording") {
                startRecording()
            }
            .buttonStyle(.borderedProminent)
            
            // Stop
            Button("Stop Recording") {
                session?.stopRecording()
            }
            .buttonStyle(.bordered)
            
            // Show result
            if let url = recorderVM.asset {
                Text("✅ Saved: \(url.lastPathComponent)")
            }
        }
        .padding()
    }
    
    private func startRecording() {
        let viewToRecord = ZStack {
            RoundedRectangle(cornerRadius: 16).fill(Color.purple)
            Text("Recording This View 🎬")
                .font(.title).foregroundColor(.white)
        }
            .frame(width: 300, height: 180)
        
        do {
            let renderer = MP4FramesRenderer(
                outputURL: FileManager.default.temporaryDirectory.appendingPathComponent("demo-\(UUID().uuidString).mp4")
            )
            
            let newSession = try ViewRecordingSession(
                view: viewToRecord,
                framesRenderer: renderer,
                useSnapshots: false,
                duration: nil,
                framesPerSecond: 30
            )
            
            recorderVM.handleRecording(session: newSession)
            
            // ✅ Automatically save when asset (URL) is ready
            recorderVM.$asset
                .compactMap { $0 }
                .sink { videoURL in
                    saveToPhotos(videoURL)
                }
                .store(in: &cancellables)
            
            session = newSession
            
        } catch {
            print("❌ Recording failed: \(error.localizedDescription)")
        }
    }
    
    // ✅ Save video to Photos Library
    private func saveToPhotos(_ url: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("❌ Photos permission denied")
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { success, error in
                DispatchQueue.main.async {
                    if success { print("✅ Saved to Photos!") }
                    else { print("❌ Error saving: \(error?.localizedDescription ?? "")") }
                }
            }
        }
    }
}

