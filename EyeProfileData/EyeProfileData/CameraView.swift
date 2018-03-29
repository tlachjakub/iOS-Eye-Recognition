//
//  CameraView.swift
//  Morecon
//
//  Created by Mouna Balghouthi on 2018/01/31.
//  Copyright © 2018 RiseUP. All rights reserved.
//

import UIKit
import AVFoundation


class CameraView: UIView {

	// Configuration
	let zoom: CGFloat = 1.7
	let predictionInterval = 1.0 // In Seconds
	let useSkinFilter = true

	var retryTimer: RUTimer? = nil
	var lastPredictionTime = Double.timeStamp


	@IBOutlet weak var eyeView: EyeView!
	
	
	
	// Capture
	var captureSession: AVCaptureSession! = nil
	var captureOutput: AVCaptureVideoDataOutput! = nil
	var previewLayer: AVCaptureVideoPreviewLayer! = nil
	var cameraLayer: CALayer! = nil
	let sessionQueue = DispatchQueue(label: "LensSim.SessionQueue", attributes: [])
	let outputQueue = DispatchQueue(label: "LensSim.OutputQueue", attributes: [])
	var captureWidth: CGFloat = 0
	var captureHeight: CGFloat = 0

	
	// Skin Filter
	var skinFilter: YUCIHighPassSkinSmoothing! = nil
	var context: CIContext! = nil

	
	
	override func awakeFromNib() {
		
		// Init Layer
		backgroundColor = UIColor.black
		clipsToBounds = true
		alpha = 0
		

		
		// Check Authorization
		let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
		if status != .authorized && status != .notDetermined {
			RUAlert.show(title: "Please allow access to the Camera.".ruLocalized) {
				RUTools.openURL(UIApplicationOpenSettingsURLString)
				
				// Timer
				self.retryTimer = RUTimer(interval: 0.5, repeats: true) { [weak self] in
					self?.initSession()
				}
			}
			return
		}

	
		RUTools.runAfter(0.1) {
			self.initSession()
		}
	}

	
	func initSession() {
		
		retryTimer = nil
		
		
		// Init Session
		captureSession = AVCaptureSession()
		captureSession.sessionPreset = AVCaptureSession.Preset.inputPriority
		
		
		// Input
		for device in AVCaptureDevice.devices() {
			if device.hasMediaType(AVMediaType.video) && device.position == AVCaptureDevice.Position.front {
				do {
					let deviceInput = try AVCaptureDeviceInput(device: device)
					if captureSession.canAddInput(deviceInput) {
						captureSession.addInput(deviceInput)
					}
					
					
					// Choose Image Quality
					try device.lockForConfiguration()
					for item in device.formats {
						let format = item as AVCaptureDevice.Format
						let desc = format.formatDescription as CMVideoFormatDescription
						let dimensions = CMVideoFormatDescriptionGetDimensions(desc)
						if dimensions.width == 1280 {
							device.activeFormat = format
							break
						}
					}
					device.unlockForConfiguration()
					
					
				} catch {
					ruPrint("ERROR: Can't use camera")
					RUTools.runAfter(2) { [weak self] in
						self?.initSession()
					}
					return
				}
			}
		}
		
		
		
		
		// Output
		captureOutput = AVCaptureVideoDataOutput()
		let available = captureOutput.availableVideoPixelFormatTypes    //.availableVideoCVPixelFormatTypes
		if available.isEmpty {
			RUTools.runAfter {RUAlert.show(title: "No PixelFormatType found")}
			return
		}
		captureOutput.alwaysDiscardsLateVideoFrames = true
		captureOutput.setSampleBufferDelegate(self, queue: outputQueue)
		if !captureSession.canAddOutput(captureOutput) {
			RUTools.runAfter {RUAlert.show(title: "No video output")}
			return
		}
		captureSession.addOutput(captureOutput)
		
		
		
		// Get Capture image Size (in Portrait)
		if let videoSettings = captureOutput.videoSettings {
			captureHeight = CGFloat(videoSettings["Width"] as! Int)
			captureWidth = CGFloat(videoSettings["Height"] as! Int)
			print("captureWidth = \(captureWidth)   captureHeight = \(captureHeight)")
		}
		
		
		
		// Set Video Orientation
		guard let connection = captureOutput.connection(with: AVMediaType.video) else {
			RUTools.runAfter {RUAlert.show(title: "Video Orientation Error")}
			return
		}
		connection.videoOrientation = AVCaptureVideoOrientation.portrait
		
		
		
		
		// Preview
		let previewHeight = layer.bounds.height * zoom
		if useSkinFilter {
			context = CGImage.ruCreateContext(width: captureWidth, height: captureHeight)
			skinFilter = YUCIHighPassSkinSmoothing()
			cameraLayer = CALayer()
			cameraLayer.frame = CGRect(x: 0, y: layer.bounds.height - previewHeight, width: layer.bounds.width, height: previewHeight)
			cameraLayer.contentsGravity = kCAGravityResizeAspectFill
			layer.addSublayer(cameraLayer)
		} else {
			previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
			previewLayer.frame = CGRect(x: 0, y: layer.bounds.height - previewHeight, width: layer.bounds.width, height: previewHeight)
			previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
			layer.addSublayer(previewLayer)
		}

		// Init Eye
		eyeView.initialize(width: captureWidth, height: captureHeight)
		
		
		// Start Session
		RUTools.runAfter {
			self.sessionQueue.async {
				self.captureSession.startRunning()
			}
			
			
			// Show Camera Image
			UIView.animate(withDuration: 0.5) {
				self.alpha = 1
			}
		}
	}
}















/////////////////////////////////////////////////////////////
// MARK: Capture Output
/////////////////////////////////////////////////////////////

extension CameraView : AVCaptureVideoDataOutputSampleBufferDelegate {
	
	func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		
		// Get CIImage
		guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
			ruPrint("ERROR: bad sampleBuffer!")
			return
		}
		let inImage = CIImage(cvPixelBuffer: pixelBuffer)
		
		
		
		
		// Skin Filter
		if useSkinFilter {
			skinFilter.inputImage = inImage
			skinFilter.inputAmount = 0.7.number				// Default = 0.75
			skinFilter.inputRadius = 10.number				// Default = 8
			skinFilter.inputSharpnessFactor = 0.0.number	// Default = 0.6
			guard let cgImage = self.context.createCGImage(skinFilter.outputImage!, from: inImage.extent) else {
				RUTools.runOnMainThread {
					self.cameraLayer.contents = nil
				}
				return
			}
			RUTools.runOnMainThread {
				self.cameraLayer.contents = cgImage
				self.cameraLayer.transform = CATransform3DMakeScale(-1, 1, 1)
			}
		}

		
		
		
		// Update Eye
		eyeView.updateImage(inImage)
	}
}













