//
// Copyright 2023 New Vector Ltd
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

import CoreLocation
import Foundation

struct MapTilerGeoCodingService: MapTilerGeoCodingServiceProtocol {
    private let key: String
    private let session: URLSession
    private let geocodingURL: String

    init(session: URLSession = .shared, key: String, geocodingURL: String) {
        self.session = session
        self.key = key
        self.geocodingURL = geocodingURL
    }
    
    private struct GeocodedPlace: Decodable {
        struct FeatureCollection: Decodable {
            let placeName: String
        }
        
        let features: [FeatureCollection]
    }
    
    func reverseGeoCoding(for coordinate: CLLocationCoordinate2D) async -> Result<String, MapTilerGeocodingError> {
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        
        let path = String(format: geocodingURL, longitude, latitude)
        guard var url = URL(string: path) else { return .failure(.wrongGeocodingURL) }
        let authorization = MapTilerAuthorization(key: key)
        url = authorization.authorizeURL(url)
        url.append(queryItems: [.init(name: "limit", value: "1")])
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await session.dataWithRetry(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let errorDescription = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown"
                MXLog.error("Failed to get reverse geocoding: \(errorDescription)")
                MXLog.error("Response: \(response)")
                return .failure(.geocodingFailed)
            }
            
            // Parse the JSON data
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decodedResponse = try decoder.decode(GeocodedPlace.self, from: data)
            guard let placeName = decodedResponse.features.first?.placeName else { return .failure(.geocodingFailed) }
            return .success(placeName)
        } catch {
            return .failure(.geocodingFailed)
        }
    }
}
