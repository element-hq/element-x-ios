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

import Combine
import Foundation
import MatrixRustSDK
import UIKit

class MediaProxy: MediaProxyProtocol {
    private let client: ClientProtocol
    private let clientQueue: DispatchQueue

    init(client: ClientProtocol,
         clientQueue: DispatchQueue = .global()) {
        self.client = client
        self.clientQueue = clientQueue
    }

    func mediaSourceForURLString(_ urlString: String) -> MediaSourceProxy {
        .init(urlString: urlString)
    }

    func loadMediaContentForSource(_ source: MediaSourceProxy) async throws -> Data {
        try await Task.dispatch(on: clientQueue) {
            let bytes = try self.client.getMediaContent(source: source.underlyingSource)
            return Data(bytes: bytes, count: bytes.count)
        }
    }

    func loadMediaThumbnailForSource(_ source: MediaSourceProxy, width: UInt, height: UInt) async throws -> Data {
        try await Task.dispatch(on: clientQueue) {
            let bytes = try self.client.getMediaThumbnail(source: source.underlyingSource, width: UInt64(width), height: UInt64(height))
            return Data(bytes: bytes, count: bytes.count)
        }
    }
}
