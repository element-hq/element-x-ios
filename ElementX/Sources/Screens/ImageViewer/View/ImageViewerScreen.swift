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

import SwiftUI

struct ImageViewerScreen: View {
    // MARK: Private

    private enum Constants {
        static let minScale: CGFloat = 1.0
        static let maxScale: CGFloat = 2.0
    }

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var displayUIControls = true
    @State private var scrollDisabled = true

    // MARK: Public
    
    @ObservedObject var context: ImageViewerViewModel.Context
    
    // MARK: Views

    var body: some View {
        GeometryReader { proxy in
            ScrollView([.horizontal, .vertical]) {
                let imageSize = imageSize(with: proxy)
                Image(uiImage: context.viewState.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageSize.width, height: imageSize.height, alignment: .center)
                    .gesture(magnification.exclusively(before: doubleTap.exclusively(before: singleTap)))
            }
            .scrollDisabled(scrollDisabled)
        }
        .background(Color.black)
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar { toolbar }
        .onSwipeGesture(minimumDistance: 3.0, down: {
            if scrollDisabled, context.viewState.isModallyPresented {
                context.send(viewAction: .cancel)
            }
        }, right: {
            if scrollDisabled, !context.viewState.isModallyPresented {
                context.send(viewAction: .cancel)
            }
        })
    }

    var magnification: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                scale *= delta
                lastScale = value
                scrollDisabled = true
            }
            .onEnded { _ in
                lastScale = 1.0
                let limitedScale = max(min(scale, Constants.maxScale), Constants.minScale)
                scrollDisabled = limitedScale == Constants.minScale
                withAnimation {
                    scale = limitedScale
                }
            }
    }

    var singleTap: some Gesture {
        TapGesture()
            .onEnded { _ in
                displayUIControls.toggle()
            }
    }

    var doubleTap: some Gesture {
        SpatialTapGesture(count: 2, coordinateSpace: .local)
            .onEnded { _ in
                withAnimation(.easeInOut(duration: 0.1)) {
                    if scale <= Constants.minScale {
                        scale = Constants.maxScale
                        scrollDisabled = false
                    } else {
                        scale = Constants.minScale
                        scrollDisabled = true
                    }
                }
            }
    }

    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        if displayUIControls {
            ToolbarItem(placement: .cancellationAction) {
                Button { context.send(viewAction: .cancel) } label: {
                    Image(systemName: context.viewState.isModallyPresented ? "xmark" : "chevron.backward")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
                .accessibilityIdentifier("dismissButton")
            }
            ToolbarItem(placement: .primaryAction) {
                Button { context.send(viewAction: .share) } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
                .accessibilityIdentifier("shareButton")
            }
        }
    }

    private func imageSize(with proxy: GeometryProxy) -> CGSize {
        let imageSize = context.viewState.image.size
        let proxySize = proxy.size
        let aspectRatio = imageSize.width / imageSize.height
        let rawValue: CGSize
        if proxy.size.width < proxySize.height {
            // align to horizontal axis
            rawValue = CGSize(width: proxySize.width, height: proxySize.width / aspectRatio)
        } else {
            // align to vertical axis
            rawValue = CGSize(width: proxySize.height * aspectRatio, height: proxySize.height)
        }
        return rawValue.applying(.init(scaleX: scale, y: scale))
    }
}

// MARK: - Previews

struct ImageViewer_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let viewModel = ImageViewerViewModel(image: Asset.Images.appLogo.image,
                                                 isModallyPresented: true)
            ImageViewerScreen(context: viewModel.context)
        }
        .tint(.element.accent)
    }
}
