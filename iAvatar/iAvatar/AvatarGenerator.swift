//
//  AvatarGenerator.swift
//  iAvatar
//
//  Created by Sergio Santos on 2018/01/10.
//  Copyright © 2018 Jakub Tlach. All rights reserved.
//

import UIKit

class AvatarGenerator: NSObject {

	static func generate(image: CGImage, avatarID: @escaping (String)->()) {
		
		let cameraPixels = image.pixelRGBValues(initialValue: 255)

		
		print("w = \(image.width)  h = \(image.height)   row = \(image.bytesPerRow)   layers = \(image.bytesPerRow / image.width)")
		print("----------------------------------------------------------------------------------")
		print("pixels = \(cameraPixels.count)   =   \(image.width * image.height)")
		
		//print("pixels = \(pixels)")

		
		// DEBUG
//		print("----------------------------------------------------------------------------------")
//		for y in 0 ..< image.height {
//			var line = ""
//			for x in 0 ..< image.width {
//				let index = (x + y * image.width) * 4
//				line += "\(cameraPixels[index]) "
//			}
//			print(line)
//		}
//		print("----------------------------------------------------------------------------------")


		// Shape
		var maxShape = 0
		var maxShapeIndex = -1
		var index = 0
		for layerImage in Avatar.shapeImages {
			
			
			let scaledLayer = layerImage.cgImage!.resized(CGSize(width: image.width, height: image.height))
			let layerPixels = scaledLayer.pixelRGBValues(initialValue: 255)

			// Check Size
			if layerPixels.count != cameraPixels.count {
				continue
			}
			
			
			// DEBUG
			print("----------------------------------------------------------------------------------")
			for y in 0 ..< image.height {
				var line = ""
				for x in 0 ..< image.width {
					let index = (x + y * image.width) * 4
					let color = layerPixels[index]
					let alpha = layerPixels[index + 3]
					line += "\(alpha) "
					
					
//					if alpha > 200 {
//						line += "\(color) "
//					} else {
//						line += "255 "
//					}
				}
				//print(line)
			}
			print("----------------------------------------------------------------------------------")

			
			
			// Test Pixels
//			for y in 0 ..< image.height {
//				for x in 0 ..< image.width {
//					let index = (x + y * image.width) * 4
//					let cameraPixel = cameraPixels[index]
//					let layerPixel = layerPixels[index]
//
//
//
//				}
//			}

			
			
			index += 1
		}
		
		
		
		
		
		RUTools.runAfter(1) {
			avatarID("2-4-3")
		}
	}
	
	
}









