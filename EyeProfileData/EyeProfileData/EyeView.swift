//
//  EyeView.swift
//  Morecon
//
//  Created by Sergio Santos on 2018/01/31.
//  Copyright © 2018 RiseUP. All rights reserved.
//

import UIKit
import AVFoundation


class EyeView: UIView {

	
	// Configuration
	let zoom: CGFloat = 140
	let rotationRate: CGFloat = 1.5

	
	
	// Face Detector
	var ciDetector: CIDetector!
	let ciOptions = [CIDetectorImageOrientation: "1"]
	var context = CIContext()
	let cameraLayer = CALayer()
	var scale: CGFloat = 1


	
	var captureWidth: CGFloat = 0
	var captureHeight: CGFloat = 0

	
	
	func initialize(width: CGFloat, height: CGFloat) {
		
		// Size
		captureWidth = width
		captureHeight = height

		
		// Init Detector
		let options = [CIDetectorAccuracy: CIDetectorAccuracyLow, CIDetectorTracking: true] as [String : Any]
		ciDetector = CIDetector(ofType: CIDetectorTypeFace, context: context, options: options)!

		
		// Init Layer
		cameraLayer.frame = CGRect(x: 0, y: 0, width: captureWidth, height: captureHeight)
		cameraLayer.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
		layer.addSublayer(cameraLayer)
		ruCornerRadius = frame.width / 2
		
		
		// Init CGContext
		context = CGImage.ruCreateContext(width: captureWidth, height: captureHeight)
	}
	
	
	func updateImage(_ image: CIImage) {
		
		// Get Faces
		let faces = ciDetector.features(in: image, options: ciOptions)
		guard let face = faces.first as? CIFaceFeature else {
			return
		}
		
		
		// No Eyes?
		if !face.hasLeftEyePosition || !face.hasRightEyePosition {
			return
		}
		
		
		// Get Eyes
		let leftEyePos = face.leftEyePosition
		let rightEyePos = face.rightEyePosition
		let eyeDiscance = leftEyePos.ruDistanceToPoint(rightEyePos)
		let eyeAngle = leftEyePos.ruAngleRadToPoint(rightEyePos) * rotationRate
		let scale: CGFloat = zoom / eyeDiscance
		let eyeX = leftEyePos.x
		let eyeY = leftEyePos.y


		// Convert to CGImage
		guard let cgImage = self.context.createCGImage(image, from: image.extent) else {
			return
		}
		
		
		// Render Image
		RUTools.runOnMainThread {
			self.cameraLayer.contents = cgImage
			self.cameraLayer.anchorPoint = CGPoint(x: eyeX / self.captureWidth, y: (self.captureHeight - eyeY) / self.captureHeight)
			var transform = CATransform3DMakeRotation(-eyeAngle, 0, 0, 1)
			transform = CATransform3DScale(transform, -scale, scale, 1)
			self.cameraLayer.transform = transform
		}
	}
}














