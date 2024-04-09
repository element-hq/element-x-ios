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
// WITHOUT WARRANTIES OR CONnDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Compound
import SwiftUI

struct QRCodeLoginScreen: View {
    @ObservedObject var context: QRCodeLoginScreenViewModel.Context
    
    var body: some View {
        NavigationStack {
            mainContent
                .toolbar { toolbar }
                .toolbar(.visible, for: .navigationBar)
                .background()
                .environment(\.backgroundStyle, AnyShapeStyle(Color.compound.bgSubtleSecondary))
                .interactiveDismissDisabled()
        }
    }
    
    @ViewBuilder
    var mainContent: some View {
        switch context.viewState.state {
        case .initial:
            initialContent
        case .scanning:
            qrScanContent
        case .error:
            // TODO: Handle states
            EmptyView()
        }
    }
    
    private var initialContent: some View {
        FullscreenDialog {
            VStack(alignment: .leading, spacing: 40) {
                VStack(spacing: 16) {
                    HeroImage(icon: \.computer, style: .subtle)
                    
                    Text(L10n.screenQrCodeLoginInitialStateTitle)
                        .foregroundColor(.compound.textPrimary)
                        .font(.compound.headingMDBold)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                
                SFNumberedListView(items: context.viewState.listItems)
            }
        } bottomContent: {
            Button(L10n.actionContinue) {
                context.send(viewAction: .startScan)
            }
            .buttonStyle(.compound(.primary))
        }
    }
    
    private var qrScanContent: some View {
        FullscreenDialog {
            VStack(spacing: 40) {
                VStack(spacing: 16) {
                    HeroImage(icon: \.switchCameraSolid, style: .subtle)
                    
                    Text("Scan the QR code")
                        .foregroundColor(.compound.textPrimary)
                        .font(.compound.headingMDBold)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                
                QRCodeScannerView()
                    .aspectRatio(1.0, contentMode: .fill)
            }
        } bottomContent: {
            EmptyView()
        }
    }
        
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(L10n.actionCancel) {
                context.send(viewAction: .cancel)
            }
        }
    }
}

// MARK: - Previews

struct QRCodeLoginScreen_Previews: PreviewProvider, TestablePreview {
    static let initialStateViewModel = QRCodeLoginScreenViewModel.mock(state: .initial)
    
    static let scanningStateViewModel = QRCodeLoginScreenViewModel.mock(state: .scanning)
    
    static var previews: some View {
        QRCodeLoginScreen(context: initialStateViewModel.context)
            .previewDisplayName("Initial")
        
        QRCodeLoginScreen(context: scanningStateViewModel.context)
            .previewDisplayName("Scanning")
    }
}
