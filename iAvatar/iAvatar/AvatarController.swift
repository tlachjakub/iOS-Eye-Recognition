//
//  ViewController.swift
//  iAvatar
//
//  Created by Jakub Tlach on 1/9/18.
//  Copyright © 2018 Jakub Tlach. All rights reserved.
//

import UIKit
import AVFoundation


class AvatarController: UIViewController {
	
	
	@IBOutlet weak var collectionView: AvatarCollectionView!
	@IBOutlet weak var avatarView: UIView!
	@IBOutlet weak var cameraView: UIView!
	
	
	// Configuration
	let zoom: CGFloat = 220 // 190
	let rotationRate: CGFloat = 1.5
	let generateInterval = 1.0		// In Seconds
	
	
	// Capture
	var captureSession: AVCaptureSession!
	var captureDevice: AVCaptureDevice!
	var captureOutput: AVCaptureVideoDataOutput!
	var previewLayer: AVCaptureVideoPreviewLayer!
	let sessionQueue = DispatchQueue(label: "LensSim.SessionQueue", attributes: [])
	let outputQueue = DispatchQueue(label: "LensSim.OutputQueue", attributes: [])
	var captureWidth: CGFloat = 0
	var captureHeight: CGFloat = 0
	
	
	let imageLayer = CALayer()
	var lastTime = Double.timeStamp
	var lastGeneratedTime = Double.timeStamp

	
	// Face Detector
	var ciDetector: CIDetector!
	let ciOptions = [CIDetectorImageOrientation: "1"]
	var context = CIContext()
	
	
	// Test Avatar Layer
	let testLayer = CALayer()

	
	// Skin Filter
	let skinFilter = YUCIHighPassSkinSmoothing()

	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		collectionView.addAvatar("001-001-001")
		collectionView.addAvatar("0-0-2")
		collectionView.addAvatar("2-4-1")
		collectionView.addAvatar("3-3-5")
		collectionView.addAvatar("2-2-2")
		collectionView.addAvatar("4-8-3")

		
		
		cameraView.alpha = 0
		cameraView.layer.addSublayer(imageLayer)
		
		
		
		// Init Session
		captureSession = AVCaptureSession()
		captureSession.sessionPreset = AVCaptureSession.Preset.inputPriority
		
		
		
		
		// Input
		guard let videoCaptureDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front).devices.first else {
			RUTools.runAfter { RUAlert.show(title: "No front camera found") }
			return
		}
		captureDevice = videoCaptureDevice
		do {
			let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
			if (captureSession.canAddInput(videoInput)) {
				captureSession.addInput(videoInput)
			} else {
				RUTools.runAfter { RUAlert.show(title: "No front video support") }
				return
			}
			
			
			// Set Maximum Resolution
			//			var maxWidth: Int32 = 0
			//			try captureDevice.lockForConfiguration()
			//			for item in captureDevice.formats {
			//				if let format = item as? AVCaptureDeviceFormat {
			//					let desc = format.formatDescription as CMVideoFormatDescription
			//					let dimensions = CMVideoFormatDescriptionGetDimensions(desc)
			//					if dimensions.width + dimensions.height > maxWidth { //640 {
			//						maxWidth = dimensions.width
			//
			//						print("maxWidth = \(maxWidth)   \(desc)")
			//
			//						captureDevice.activeFormat = format
			//						//break
			//					}
			//				}
			//			}
			
			
			
			// Choose Image Quality
			try captureDevice.lockForConfiguration()
			for item in captureDevice.formats {
				let format = item as AVCaptureDevice.Format
				let desc = format.formatDescription as CMVideoFormatDescription
				let dimensions = CMVideoFormatDescriptionGetDimensions(desc)
				//					if dimensions.width == 1280 {
				if dimensions.width == 640 {
					captureDevice.activeFormat = format
				}
				
				// print("dimensions.width = \(dimensions.width)   \(desc)")
			}
			captureDevice.unlockForConfiguration()
			
			
		} catch {
			RUTools.runAfter { RUAlert.show(title: "No video capture") }
			return
		}
		
		
		
		
		
		
		
		
		// Output
		captureOutput = AVCaptureVideoDataOutput()
		let available = captureOutput.availableVideoPixelFormatTypes    //.availableVideoCVPixelFormatTypes
		if available.isEmpty {
			RUTools.runAfter {RUAlert.show(title: "No PixelFormatType found")}
			return
		}
		//		captureOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: Int(kCMPixelFormat_32BGRA)]
		//captureOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: formatType.intValue]
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
		//		previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		//		previewLayer.frame = cameraView.layer.bounds
		//		previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
		//		cameraView.layer.addSublayer(previewLayer)
		
		
		
		
		
		
		
		
		
		
		// Init CGContext
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		guard let cgContext = CGContext(data: nil, width: Int(captureWidth), height: Int(captureHeight),
										bitsPerComponent: 5,
										bytesPerRow: Int(captureWidth) * 8,
										space: colorSpace,
										bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
											print("ERRO: Cant create CGContext")
											return
		}
		cgContext.setAllowsAntialiasing(true)
		cgContext.setShouldAntialias(true)
		context = CIContext(cgContext: cgContext, options: [
			kCIContextWorkingColorSpace: colorSpace,
			kCIContextOutputColorSpace: colorSpace,
			kCIContextUseSoftwareRenderer: false
			])
		
		
		// Init Detector
		let options = [CIDetectorAccuracy: CIDetectorAccuracyLow, CIDetectorTracking: true] as [String : Any]
		ciDetector = CIDetector(ofType: CIDetectorTypeFace, context: context, options: options)!

		
		
		
		// Test Layer
		let testImage = #imageLiteral(resourceName: "shape1").cgImage!
		testLayer.contents = testImage
		testLayer.frame = CGRect(x: 0, y: 0, width: testImage.width, height: testImage.height)
		avatarView.layer.addSublayer(testLayer)
		
		
		
		
		// Start Session
		RUTools.runAfter {
			self.sessionQueue.async {
				self.captureSession.startRunning()
			}
		}
	}
	
	
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		
		// Make round
		avatarView.ruCornerRadius = avatarView.frame.width / 2
		cameraView.ruCornerRadius = cameraView.frame.width / 2
		
		
		// Test
		testLayer.position = CGPoint(x: avatarView.bounds.width / 2, y: avatarView.bounds.height / 2)
		
		
		imageLayer.frame = CGRect(x: 0, y: 0, width: captureWidth, height: captureHeight)
		imageLayer.position = CGPoint(x: cameraView.frame.width / 2, y: cameraView.frame.height / 2)

		
		// Show CameraView
		UIView.animate(withDuration: 0.5) {
			self.cameraView.alpha = 1
		}
	}
}











/////////////////////////////////////////////////////////////
// MARK: Capture Output
/////////////////////////////////////////////////////////////

extension AvatarController : AVCaptureVideoDataOutputSampleBufferDelegate {
	
	func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		
		
		// Get CIImage
		guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
			print("bad sampleBuffer!")
			return
		}
		var inImage = CIImage(cvPixelBuffer: pixelBuffer)
		
		
		
		
		// Get Faces
		let faces = ciDetector.features(in: inImage, options: ciOptions)
		guard let face = faces.first as? CIFaceFeature else {

			// TODO: No FACE!!!
			RUTools.runOnMainThread {
				
				// Render Image
				self.imageLayer.contents = nil
				
			}
			return
		}
		
		
		// No Eyes?
		if !face.hasLeftEyePosition || !face.hasRightEyePosition {
			
			// TODO: No EYES!!!
			RUTools.runOnMainThread {
				
				// Render Image
				self.imageLayer.contents = nil

			}
			return
		}
		
		
		// Get Eyes
		let leftEyePos = face.leftEyePosition
		let rightEyePos = face.rightEyePosition
		let eyeDiscance = leftEyePos.distanceToPoint(rightEyePos)
		let eyeAngle = leftEyePos.angleRadToPoint(rightEyePos) * rotationRate
		let scale: CGFloat = zoom / eyeDiscance
		let eyeX = leftEyePos.x
		let eyeY = leftEyePos.y
		
		
		
		
		// Skin Filter
		skinFilter.inputImage = inImage
		skinFilter.inputAmount = 0.7.number				// Default = 0.75
		skinFilter.inputRadius = 10.number				// Default = 8
		skinFilter.inputSharpnessFactor = 0.0.number	// Default = 0.6
		inImage = skinFilter.outputImage!


		// B&W Filter
		// CIComicEffect
		// CIPhotoEffectNoir
		// CIPhotoEffectTonal
		var filter = CIFilter(name: "CIPhotoEffectNoir")!
		filter.setValue(inImage, forKey: kCIInputImageKey)
		inImage = filter.outputImage ?? inImage

		
		// Contrast Filter
		filter = CIFilter(name: "CIColorControls")!
		filter.setValue(inImage, forKey: kCIInputImageKey)
		filter.setValue(2.number, forKey: kCIInputContrastKey)
		filter.setValue(0.2.number, forKey: kCIInputBrightnessKey)
		inImage = filter.outputImage ?? inImage

		
		// Convert to CGImage
		guard let cgImage = self.context.createCGImage(inImage, from: inImage.extent) else {
			return
		}

		


		// FPS
//		let delta = frameTime - lastTime
//		lastTime = frameTime
//		print("FPS = \(1.0 / delta)")

		
		
		RUTools.runOnMainThread {

			// Render Image
			self.imageLayer.contents = cgImage
			
			// No Animation
//			CATransaction.begin()
//			CATransaction.setDisableActions(true)
			
			self.imageLayer.anchorPoint = CGPoint(x: eyeX / self.captureWidth, y: (self.captureHeight - eyeY) / self.captureHeight)
			var transform = CATransform3DMakeRotation(-eyeAngle, 0, 0, 1)
			transform = CATransform3DScale(transform, -scale, scale, 1)
			self.imageLayer.transform = transform

			
			
			// Generator
			let frameTime = Double.timeStamp
			let generatedDelta = frameTime - self.lastGeneratedTime
			if generatedDelta > self.generateInterval {
				self.lastGeneratedTime = frameTime
//				if let image = self.cameraView.ruRenderedImage.cgImage { //ruRenderedCGImage {
				if let image = self.cameraView.ruRenderedCGImage {
					
					
					// Test Avatar
					self.avatarView.layer.contents = image

					
					
					AvatarGenerator.generate(image: image, avatarID: { (id) in
						self.collectionView.addAvatar(id)
					})
				}
			}
			
			
			
			
			
			
			
//			CATransaction.commit()
		}
	}
}












