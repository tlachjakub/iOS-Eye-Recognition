//
//  Avatar.swift
//  iAvatar
//
//  Created by Sergio Santos on 2018/01/10.
//  Copyright © 2018 Jakub Tlach. All rights reserved.
//

import UIKit

class Avatar: NSObject {

	struct Layer {
		var image: UIImage
		var y: CGFloat
	}
	
	
	// Layers
	static var shapeImages = [#imageLiteral(resourceName: "shape1"),#imageLiteral(resourceName: "shape2"),#imageLiteral(resourceName: "shape3"),#imageLiteral(resourceName: "shape4"),#imageLiteral(resourceName: "shape5"),#imageLiteral(resourceName: "shape6"),#imageLiteral(resourceName: "shape7")]
	static var lineImages = [#imageLiteral(resourceName: "line1"),#imageLiteral(resourceName: "line2")]
	static var irisImages = [#imageLiteral(resourceName: "iris1"),#imageLiteral(resourceName: "iris2"),#imageLiteral(resourceName: "iris3")]
	static var lineYs: [CGFloat] = [0.5, 0.4, 0.3, 0.2, 0.1]
	static var irisYs: [CGFloat] = [0.3, 0.4, 0.5, 0.6, 0.7]

	static var shapeLayers: [Avatar.Layer] = []
	static var lineLayers: [Avatar.Layer] = []
	static var irisLayers: [Avatar.Layer] = []

	
	static func initLayers() {
		
		// Shapes
		for image in Avatar.shapeImages {
			Avatar.shapeLayers.append(Layer(image: image, y: 0.5))
		}
		
		// Lines
		for image in Avatar.lineImages {
			for y in Avatar.lineYs {
				Avatar.lineLayers.append(Layer(image: image, y: y))
			}
		}
		
		// Iris
		for image in Avatar.irisImages {
			for y in Avatar.irisYs {
				Avatar.irisLayers.append(Layer(image: image, y: y))
			}
		}
	}
	
	
	

	let id: String  // Ex:  "002-006-008"  "SHAPE-LINE-IRIS"
	
	
	init(id: String) {
		self.id = id
		super.init()
	}
	
	
	
	var image: UIImage? {
		
		let indexes = id.components(separatedBy: "-")
		if indexes.count != 3 {
			return nil
		}
		
		// Shape
		let shapeIndex = indexes[0].ruIntValue
		let shapeLayer = Avatar.shapeLayers[min(max(shapeIndex, 0), Avatar.shapeLayers.count)]
		var newImage = shapeLayer.image
		
		// Line
		let lineIndex = indexes[1].ruIntValue
		let lineLayer = Avatar.lineLayers[min(max(lineIndex, 0), Avatar.lineLayers.count)]
		newImage = newImage.ruOverlay(image: lineLayer.image, y: lineLayer.y)
		
		// Iris
		let irisIndex = indexes[2].ruIntValue
		let irisLayer = Avatar.irisLayers[min(max(irisIndex, 0), Avatar.irisLayers.count)]
		newImage = newImage.ruUnderlay(image: irisLayer.image, y: irisLayer.y)

		return newImage
	}
}











