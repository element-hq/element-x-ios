//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import UIKit
import Vision

enum ImageAnonymizerError: Error {
    case noCgImageBased
}

enum ImageAnonymizer {
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
        
        #if targetEnvironment(simulator)
        // Avoid `Could not create inference context` errors on Apple Silicon
        // https://www.caseyliss.com/2022/6/20/feedback-is-broken-stop-trying-to-make-radar-happen
        faceRequest.usesCPUOnly = true
        #endif

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
