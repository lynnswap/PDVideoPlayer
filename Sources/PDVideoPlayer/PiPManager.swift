//
//  PiPManager.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/02/25.
//
import SwiftUI
import AVKit

@MainActor
final class PiPManager {
    static let shared = PiPManager()
    private var pipController: AVPictureInPictureController?
    func setup(_ layer: AVPlayerLayer) {
        if let pipController = self.pipController{
            pipController.contentSource = .init(playerLayer: layer)
        }else{
            pipController = AVPictureInPictureController(playerLayer: layer)
        }
      
    }
    func start(){
        if let controller = self.pipController{
            controller.startPictureInPicture()
        }
    }
    func stop(){
        self.pipController?.stopPictureInPicture()
    }
}
//
//extension PiPManager: AVPictureInPictureControllerDelegate {
//    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController) async -> Bool{
//        return true
//    }
//    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController){
//        print(#function)
//    }
//    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController){
//        print(#function)
//    }
//    func pictureInPictureController(
//        _ pictureInPictureController: AVPictureInPictureController,
//        failedToStartPictureInPictureWithError error: any Error
//    ){
//        print(#function)
//    }
//    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController){
//        print(#function)
//    }
//    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController){
//        print(#function)
//    }
//}
