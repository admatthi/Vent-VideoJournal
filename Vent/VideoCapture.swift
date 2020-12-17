//
//  VideoCapture.swift
//  Vent
//
//  Created by Tushali on 14/12/20.
//  Copyright © 2020 Alek Matthiessen. All rights reserved.
//


import UIKit
import AVFoundation
import RecordButton


// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}

class VideoCapture: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error == nil {
        UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
        }
    }
    
    
    @IBOutlet weak var videoView: UIView!

    @IBOutlet weak var TapView: UIView!
    
    @IBOutlet weak var recordButton: RecordButton!
    
    var movieFileOutput = AVCaptureMovieFileOutput()
    
    var captureSession = AVCaptureSession()
    
    var previewLayer = AVCaptureVideoPreviewLayer()
    
    var movieOutput = AVCaptureMovieFileOutput()
    
    var videoCaptureDevice : AVCaptureDevice?
    
    var frontCamera: AVCaptureDevice?
    
    var rearCamera: AVCaptureDevice?
    
    var rearCameraInput: AVCaptureDeviceInput?
    
    var frontCameraInput: AVCaptureDeviceInput?
    
    var currentCameraPosition = AVCaptureDevice.Position.back
    
    var audioInput: AVCaptureDevice?
    
    var progressTimer : Timer!
    
    var progress : CGFloat! = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.avCaptureVideoSetUp()
        
//        let longPressGesture = UILongPressGestureRecognizer.init(target: self, action: #selector(longPressView(_:)))
//        self.videoView.isUserInteractionEnabled = true
//        self.videoView.addGestureRecognizer(longPressGesture);
//
        self.videoView.bringSubviewToFront(self.TapView)
        //AVCaptureDeviceDiscoverySession
        
        recordButton.progressColor = .red
                recordButton.closeWhenFinished = false
                recordButton.addTarget(self, action: #selector(self.record), for: .touchDown)
        recordButton.addTarget(self, action: #selector(self.stop), for: UIControl.Event.touchUpInside)
        
    }
    
    
    override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let bounds: CGRect = videoView.layer.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    previewLayer.bounds = bounds
    previewLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
    }

    override func didReceiveMemoryWarning() {
          super.didReceiveMemoryWarning()
          // Dispose of any resources that can be recreated.
      }

      @objc func record() {
          self.progressTimer = Timer.scheduledTimer(timeInterval: 0.10, target: self, selector: #selector(self.updateProgress), userInfo: nil, repeats: true)
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL

        let filePath = documentsURL.appendingPathComponent("tempMovie.mp4")

        if FileManager.default.fileExists(atPath: filePath.absoluteString) {
            do {
                try FileManager.default.removeItem(at: filePath)
            }
            catch {
                // exception while deleting old cached file
                // ignore error if any
            }
        }
//
        self.movieFileOutput.startRecording(to: filePath, recordingDelegate: self)
    }
    
      
      @objc func updateProgress() {
          
          let maxDuration = CGFloat(10) // Max duration of the recordButton
          
          progress = progress + (CGFloat(0.10) / maxDuration)
          recordButton.setProgress(progress)
          
          if progress >= 1 {
              progressTimer.invalidate()
          }
        
      }
      
      @objc func stop() {
          self.progressTimer.invalidate()
        
        self.movieFileOutput.stopRecording()
            
      }
    
    
    @objc func longPressView(_ gestureRecognizer: UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == UIGestureRecognizer.State.began {
                    debugPrint("long press started")
                    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
                    let filePath = documentsURL.appendingPathComponent("tempMovie.mp4")
                    if FileManager.default.fileExists(atPath: filePath.absoluteString) {
                        do {
                            try FileManager.default.removeItem(at: filePath)
                        }
                        catch {
                            print("ERROR TO SAVE DATA")
                            // exception while deleting old cached file
                            // ignore error if any
                        }
                    }
            self.movieFileOutput.startRecording(to: filePath, recordingDelegate: self)
                }
        else if gestureRecognizer.state == UIGestureRecognizer.State.ended {
                    debugPrint("longpress ended")
            self.movieFileOutput.stopRecording()
                }
    }
    
    func avCaptureVideoSetUp(){
       
        let session = AVCaptureDevice.DiscoverySession.init(deviceTypes:[.builtInWideAngleCamera, .builtInMicrophone], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.back)
                
        let cameras = (session.devices.compactMap{$0})
                
        for camera in cameras {
            if camera.position == .front {
                self.frontCamera = camera
            }
            if camera.position == .back {
                self.rearCamera = camera
                try! camera.lockForConfiguration()
                camera.focusMode = .continuousAutoFocus
                camera.unlockForConfiguration()
            }
        }
        
        if let rearCamera = self.rearCamera {
            self.rearCameraInput = try? AVCaptureDeviceInput(device: rearCamera)
            if captureSession.canAddInput(self.rearCameraInput!) {
                captureSession.addInput(self.rearCameraInput!)
                self.currentCameraPosition = .back
            }
        }else if let frontCamera = self.frontCamera {
            self.frontCameraInput = try? AVCaptureDeviceInput(device: frontCamera)
            if captureSession.canAddInput(self.frontCameraInput!) {
                captureSession.addInput(self.frontCameraInput!)
                self.currentCameraPosition = .front
            }
        }
        
        
        // Add audio input
        
        self.audioInput = AVCaptureDevice.default(for: .audio)
        
        
//        try? self.captureSession.addInput(AVCaptureDeviceInput(device: self.audioInput!))
//
//        try! self.captureSession.addInput(AVCaptureDeviceInput(device: audioInput!))
//
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        
        self.videoView.layer.addSublayer(self.previewLayer)
        
        //Add File Output
        self.captureSession.addOutput(self.movieOutput)
        
        captureSession.startRunning()
        
    }

}


