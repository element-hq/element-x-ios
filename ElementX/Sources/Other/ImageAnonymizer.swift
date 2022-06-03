//
//  UIImage+.swift
//  ElementX
//
//  Created by Ismail on 20.05.2022.
//  Copyright © 2022 element.io. All rights reserved.
//

import Foundation
import Vision
import UIKit

enum ImageAnonymizerError: Error {
    case noCgImageBased
}

struct ImageAnonymizer {

    private static var allowedTextItems: [String] = [
        "#",
        "@",
        "%",
        "&",
        "+",
        "-",
        "_",
        "\"",
        "?",
        "*"
    ]

    static func anonymizedImage(from image: UIImage,
                                confidenceLevel: Float = 0.5,
                                fillColor: UIColor = .red) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw ImageAnonymizerError.noCgImageBased
        }

        //  create a handler with cgImage
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        var observations: [VNDetectedObjectObservation] = []

        //  create a text request
        let textRequest = VNRecognizeTextRequest { request, error in
            guard let results = request.results as? [VNRecognizedTextObservation],
                  error == nil else {
                return
            }
            observations.append(contentsOf: results)
        }
        textRequest.recognitionLevel = .accurate
        textRequest.revision = VNRecognizeTextRequestRevision2

        //  create a face request
        let faceRequest = VNDetectFaceRectanglesRequest { request, error in
            guard let results = request.results as? [VNFaceObservation],
                  error == nil else {
                return
            }
            observations.append(contentsOf: results)
        }
        // revision3 doesn't work!
        faceRequest.revision = VNDetectFaceRectanglesRequestRevision2

        //  perform requests
        try handler.perform([
            textRequest,
            faceRequest
        ])

        return render(image: image,
                      confidenceLevel: confidenceLevel,
                      fillColor: fillColor,
                      observations: observations)
    }

    private static func render(image: UIImage,
                               confidenceLevel: Float,
                               fillColor: UIColor,
                               observations: [VNDetectedObjectObservation]) -> UIImage {
        let size = image.size
        let result = UIGraphicsImageRenderer(size: size).image { rendererContext in
            //  first draw self
            image.draw(in: CGRect(origin: .zero, size: size))
            //  set fill color
            fillColor.setFill()
            for observation in observations {
                guard observation.confidence >= confidenceLevel else {
                    //  ensure observation's confidence level
                    continue
                }
                if let textObservation = observation as? VNRecognizedTextObservation,
                    let text = textObservation.topCandidates(1).first?.string {
                    if Double(text) != nil || Self.allowedTextItems.contains(text) {
                        continue
                    }
                }
                let box = observation.boundingBox
                //  boc is normalized (and in starts from the lower left corner)
                //  convert it to a rect in the image
                let rect = CGRect(x: box.minX * size.width,
                                  y: size.height - box.maxY * size.height,
                                  width: box.width * size.width,
                                  height: box.height * size.height)
                rendererContext.fill(rect)
            }
        }
        return result
    }

}
