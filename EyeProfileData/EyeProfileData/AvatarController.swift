//
//  ViewController.swift
//  iAvatar
//
//  Created by Sergio Santos on 1/12/18.
//  Copyright © 2018 Jakub Tlach. All rights reserved.
//

import UIKit
import AVFoundation


class AvatarController: UIViewController {
	
	
	@IBOutlet weak var avatarView: UIView!
	@IBOutlet weak var cameraView: UIView!
	
	@IBOutlet weak var counterLabel: UILabel!
	@IBOutlet weak var pickerView: UIPickerView!
	@IBOutlet weak var startSwitch: UISwitch!
	
	
	// Loads the counter everytime when we start the app
	var counters: [Int] = UserDefaults.standard.array(forKey: "counters") as? [Int] ?? [0, 0, 0]
	let eyeShapes: [UIImage] = [#imageLiteral(resourceName: "eye color 1"), #imageLiteral(resourceName: "eye line 2"), #imageLiteral(resourceName: "eye line 3")]
	let eyeStyles = ["一重 (Hitoe)", "二重 (Futae)", "奥二重 (Okubutae)"]
	
	
	// Check if the selectedRow in pickerView is between the real values
	var index: Int {
		return min(max(pickerView.selectedRow(inComponent: 0), 0), counters.count - 1)
	}
	
	
	
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
	let avatarLayer = CALayer()
	let cameraLayer = CALayer()
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
		
		// Turn off the switch
		startSwitch.isOn = false
		
		
		// Init Layers
		cameraView.alpha = 0
		cameraView.layer.addSublayer(cameraLayer)
		avatarView.layer.addSublayer(avatarLayer)
		UIView.animate(withDuration: 0.5) {
			self.cameraView.alpha = 1
		}

		
		
		// Update of the counterLabel
		update()
		
		
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
						if dimensions.width == 640 {
							device.activeFormat = format
						}
					}
					device.unlockForConfiguration()
					break
					
					
				} catch {
					ruPrint("ERROR: Can't use camera")
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
		avatarView.ruCornerRadius = avatarView.frame.width / 2
		cameraView.ruCornerRadius = cameraView.frame.width / 2
		pickerView.ruCornerRadius = 50.0
		
		
		// Layers
		avatarLayer.transform = CATransform3DIdentity
		avatarLayer.position = CGPoint(x: avatarView.bounds.width / 2, y: avatarView.bounds.height / 2)
		cameraLayer.transform = CATransform3DIdentity
		cameraLayer.frame = CGRect(x: 0, y: 0, width: captureWidth, height: captureHeight)
		cameraLayer.position = CGPoint(x: cameraView.frame.width / 2, y: cameraView.frame.height / 2)
	}
	
	
	
	// Update of the the counter and avatarView
	func update() {
		counterLabel.text = "x  \(counters[index])"
		
		// Update Avatar
		let avatarImage = eyeShapes[index].cgImage!
		avatarLayer.contents = avatarImage
		avatarLayer.frame = CGRect(x: 0, y: 0, width: avatarImage.width, height: avatarImage.height)
	}
	
	
	
	// Save the counters
	func save() {
		UserDefaults.standard.set(counters, forKey: "counters")
		UserDefaults.standard.synchronize()
	}
	

	
	// When the Switch is ON -> take the pictures of the eye
	func takePictures() {
		
		// Stop?
		if !startSwitch.isOn {
			return
		}
		
		
		// No Image?
		if cameraLayer.contents == nil {
			
			// Continue
			RUTools.runAfter (0.2) { self.takePictures() }
			return
		}
		

		
		// Prepare the image
		let image = self.cameraView.ruRenderedImage.ruAspectFillToSize(CGSize(width: 100, height: 100))
		
		
		// Folder
		let folder = RUTools.documentsURL.appendingPathComponent("\(self.eyeStyles[self.index])")
		if !FileManager.default.fileExists(atPath: folder.path) {
			try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
		}
		
		
		// Save the image
		let path = folder.appendingPathComponent("\(self.counters[self.index]).png")
		if let data = UIImagePNGRepresentation(image) {
			try? data.write(to: path)
		}
		
		
		// Increase the counter
		self.counters[self.index] += 1
		self.update()
		
		
		
		// Continue
		RUTools.runAfter(0.2) { self.takePictures() }
	}


	
	
	// When the Switch is On, take pictures of the CameraView
	@IBAction func switchStartStop(_ sender: Any) {
		if startSwitch.isOn {
			pickerView.isUserInteractionEnabled = false
		} else {
			pickerView.isUserInteractionEnabled = true
		}
		takePictures()
		self.save()
	}
}






/////////////////////////////////////////////////////////////////////////////////////////
// MARK: PickerView
/////////////////////////////////////////////////////////////////////////////////////////

extension AvatarController: UIPickerViewDataSource, UIPickerViewDelegate {
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return eyeStyles.count
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return eyeStyles[row]
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		update()
	}
	
	func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
		
		let pickerLabel = UILabel()
		pickerLabel.text = eyeStyles[row]
		pickerLabel.font = UIFont(name: pickerLabel.font.fontName, size: 70)
		pickerLabel.font = UIFont(name: "Arial-BoldMT", size: 35) // In this use your custom font
		pickerLabel.textAlignment = NSTextAlignment.center
		
		return pickerLabel
	}
	
	func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
		return 70.0
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
				self.cameraLayer.contents = nil
			}
			return
		}
		
		
		// No Eyes?
		if !face.hasLeftEyePosition || !face.hasRightEyePosition {
			
			// TODO: No EYES!!!
			RUTools.runOnMainThread {
				self.cameraLayer.contents = nil
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
				self.cameraLayer.contents = nil
			}
			return
		}
		
		
		
		
		// FPS
//		let delta = frameTime - lastTime
//		lastTime = frameTime
//		print("FPS = \(1.0 / delta)")
		
		
		
		RUTools.runOnMainThread {
			
			// Render Image
			self.cameraLayer.contents = cgImage

			// Zoom on Eye
			self.cameraLayer.anchorPoint = CGPoint(x: eyeX / self.captureWidth, y: (self.captureHeight - eyeY) / self.captureHeight)
			var transform = CATransform3DMakeRotation(-eyeAngle, 0, 0, 1)
			transform = CATransform3DScale(transform, -scale, scale, 1)
			self.cameraLayer.transform = transform
		}
	}
}












