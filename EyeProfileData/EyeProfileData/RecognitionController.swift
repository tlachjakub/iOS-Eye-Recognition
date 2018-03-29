//
//  RecognitionController.swift
//  EyeProfileData
//
//  Created by Jakub Tlach on 1/23/18.
//  Copyright © 2018 Jakub Tlach. All rights reserved.
//

import UIKit
import AVFoundation

@available(iOS 11.0, *)
class RecognitionController: UIViewController {
	
	@IBOutlet weak var eyeView: UIView!
	@IBOutlet weak var photoView: UIView!
	@IBOutlet weak var resultLabel: UILabel!
	@IBOutlet weak var recognizeButton: UIButton!
	
	
	// Load the CoreML model
	let model = kerasEyesModel()
	
	
	let eyeShapes: [UIImage] = [#imageLiteral(resourceName: "hitoe"), #imageLiteral(resourceName: "futae"), #imageLiteral(resourceName: "okubutae")]
	let eyeStyles = ["一重 (Hitoe)", "二重 (Futae)", "奥二重 (Okubutae)"]
	var index = 0
	
	
	// Configuration
	var zoom: CGFloat = 250 // 190
	let rotationRate: CGFloat = 1.5
	let generateInterval = 0.2		// In Seconds
	
	
	// Capture
	var captureSession: AVCaptureSession!
	var captureDevice: AVCaptureDevice!
	var captureOutput: AVCaptureVideoDataOutput!
	var previewLayer: AVCaptureVideoPreviewLayer!
	let sessionQueue = DispatchQueue(label: "LensSim.SessionQueue", attributes: [])
	let outputQueue = DispatchQueue(label: "LensSim.OutputQueue", attributes: [])
	var captureWidth: CGFloat = 0
	var captureHeight: CGFloat = 0
	
	
	// Layers
	let eyeLayer = CALayer()
	let photoLayer = CALayer()
	var lastTime = Double.timeStamp
	var lastGeneratedTime = Double.timeStamp
	
	
	// Face Detector
	var ciDetector: CIDetector!
	let ciOptions = [CIDetectorImageOrientation: "1"]
	var context = CIContext()
	
	
	// Skin Filter
	let skinFilter = YUCIHighPassSkinSmoothing()
	
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		resultLabel.text = ""
		
		// Init Layers
		photoView.alpha = 0
		photoView.layer.addSublayer(photoLayer)
		eyeView.layer.addSublayer(eyeLayer)
		UIView.animate(withDuration: 0.5) {
			self.photoView.alpha = 1
		}
		
	
		
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
		eyeView.ruCornerRadius = eyeView.frame.width / 2
		photoView.ruCornerRadius = photoView.frame.width / 2
		
		
		// Layers
		eyeLayer.transform = CATransform3DIdentity
		eyeLayer.position = CGPoint(x: eyeView.bounds.width / 2, y: eyeView.bounds.height / 2)
		photoLayer.transform = CATransform3DIdentity
		photoLayer.frame = CGRect(x: 0, y: 0, width: captureWidth, height: captureHeight)
		photoLayer.position = CGPoint(x: photoView.frame.width / 2, y: photoView.frame.height / 2)
	}
	
	
	
	
	// When the Switch is ON -> take the pictures of the eye
	func takePicture() {
		
		
		// No Image?
		if photoLayer.contents == nil {
			return
		}
		
		
		// Prepare the image
		let image = self.photoView.ruRenderedImage.ruAspectFillToSize(CGSize(width: 100, height: 100))
		let pixelBuffer = image.pixelBuffer()
		
		
		// Predict the eye
		guard let output = try? model.prediction(image: pixelBuffer!) else { return }
		
		if output.classLabel == "Hitoe" {
			resultLabel.text = eyeStyles[0]
			index = 0
		}
		if output.classLabel == "Futae" {
			resultLabel.text = eyeStyles[1]
			index = 1
		}
		if output.classLabel == "Okubutae" {
			resultLabel.text = eyeStyles[2]
			index = 2
		}
		
		// Update Avatar
		let eyeImage = eyeShapes[index].cgImage!
		eyeLayer.contents = eyeImage
		eyeLayer.frame = CGRect(x: 0, y: 0, width: eyeImage.width, height: eyeImage.height)

	}
	
	
	
	
	// When button i pushed, take a picture of the photoView
	@IBAction func recognize(_ sender: UIButton) {
		takePicture()
	}
}





/////////////////////////////////////////////////////////////
// MARK: Capture Output
/////////////////////////////////////////////////////////////

@available(iOS 11.0, *)
extension RecognitionController : AVCaptureVideoDataOutputSampleBufferDelegate {
	
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
				self.photoLayer.contents = nil
			}
			return
		}
		
		
		// No Eyes?
		if !face.hasLeftEyePosition || !face.hasRightEyePosition {
			
			// TODO: No EYES!!!
			RUTools.runOnMainThread {
				self.photoLayer.contents = nil
			}
			return
		}
		
		
		// Get Eyes
		let leftEyePos = face.leftEyePosition
		let rightEyePos = face.rightEyePosition
		let eyeDistance = leftEyePos.ruDistanceToPoint(rightEyePos)
		let eyeAngle = leftEyePos.ruAngleRadToPoint(rightEyePos) * rotationRate
		let scale: CGFloat = zoom / eyeDistance
		let eyeX = leftEyePos.x
		let eyeY = leftEyePos.y
		
		
		// Debug Values
		//		print("Eye Distance: \(eyeDistance)")
		//		print("Scale: \(scale)")
		//		print("Left Eye: \(leftEyePos)")
		//		print("Right Eye: \(rightEyePos)")
		//		print("----------------------------")
		
		
		
		// Skin Filter
		skinFilter.inputImage = inImage
		skinFilter.inputAmount = 0.7.number				// Default = 0.75
		skinFilter.inputRadius = 10.number				// Default = 8
		skinFilter.inputSharpnessFactor = 0.0.number	// Default = 0.6
		inImage = skinFilter.outputImage!
		
		
		// Contrast Filter
		//		let filter = CIFilter(name: "CIColorControls")!
		//		filter.setValue(inImage, forKey: kCIInputImageKey)
		//		filter.setValue(2.number, forKey: kCIInputContrastKey)
		//		filter.setValue(0.5.number, forKey: kCIInputBrightnessKey)
		//		inImage = filter.outputImage ?? inImage
		
		
		// Convert to CGImage
		guard let cgImage = self.context.createCGImage(inImage, from: inImage.extent) else {
			RUTools.runOnMainThread {
				self.photoLayer.contents = nil
			}
			return
		}
		
		
		
		
		// FPS
		//		let delta = frameTime - lastTime
		//		lastTime = frameTime
		//		print("FPS = \(1.0 / delta)")
		
		
		
		RUTools.runOnMainThread {
			
			// Render Image
			self.photoLayer.contents = cgImage
			
			// Zoom on Eye
			self.photoLayer.anchorPoint = CGPoint(x: eyeX / self.captureWidth, y: (self.captureHeight - eyeY) / self.captureHeight)
			var transform = CATransform3DMakeRotation(-eyeAngle, 0, 0, 1)
			transform = CATransform3DScale(transform, -scale, scale, 1)
			self.photoLayer.transform = transform
		}
	}
}




//////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: UIImage extension
//////////////////////////////////////////////////////////////////////////////////////////////////////

extension UIImage {
	func pixelBuffer() -> CVPixelBuffer? {
		let width = self.size.width
		let height = self.size.height
		let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
					 kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
		var pixelBuffer: CVPixelBuffer?
		let status = CVPixelBufferCreate(kCFAllocatorDefault,
										 Int(width),
										 Int(height),
										 // If it's gray image
										 //kCVPixelFormatType_OneComponent8,
										 kCVPixelFormatType_32ARGB,
										 attrs,
										 &pixelBuffer)
		
		guard let resultPixelBuffer = pixelBuffer, status == kCVReturnSuccess else {
			return nil
		}
		
		CVPixelBufferLockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
		let pixelData = CVPixelBufferGetBaseAddress(resultPixelBuffer)
		
		//let grayColorSpace = CGColorSpaceCreateDeviceGray()
		let RGBColorSpace = CGColorSpaceCreateDeviceRGB()
		guard let context = CGContext(data: pixelData,
									  width: Int(width),
									  height: Int(height),
									  // bitsPerComponent: 8,
									  bitsPerComponent: 8,
									  bytesPerRow: CVPixelBufferGetBytesPerRow(resultPixelBuffer),
									  space: RGBColorSpace,
									  bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
									  )
			else { return nil }
		
		context.translateBy(x: 0, y: height)
		context.scaleBy(x: 1.0, y: -1.0)
		
		UIGraphicsPushContext(context)
		self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
		UIGraphicsPopContext()
		CVPixelBufferUnlockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
		
		return resultPixelBuffer
	}
}
