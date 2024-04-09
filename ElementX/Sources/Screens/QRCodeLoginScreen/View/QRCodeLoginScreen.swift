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
    
    @State private var qrFrame = CGRect.zero
    private let dashRatio: CGFloat = 80.0 / 312.0
    private let emptyRatio: CGFloat = 232.0 / 312.0
    private let dashPhaseRatio: CGFloat = 40.0 / 312.0
    
    private var dashLenght: CGFloat {
        qrFrame.height * dashRatio
    }
    
    private var emptyLenght: CGFloat {
        qrFrame.height * emptyRatio
    }
    
    private var dashPhase: CGFloat {
        qrFrame.height * dashPhaseRatio
    }
    
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
        case .scan:
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
                    HeroImage(icon: \.takePhotoSolid, style: .subtle)
                    
                    Text(L10n.screenQrCodeLoginScanningStateTitle)
                        .foregroundColor(.compound.textPrimary)
                        .font(.compound.headingMDBold)
                        .multilineTextAlignment(.center)
                }
                
                qrScanner
            }
        } bottomContent: {
            qrScanFooter
        }
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private var qrScanFooter: some View {
        if case let .scan(scanState) = context.viewState.state {
            switch scanState {
            case .connecting:
                VStack(spacing: 4) {
                    ProgressView()
                    Text(L10n.screenQrCodeLoginConnectingSubtitle)
                }
            case .scanning:
                // Just here to keep the spacing consistent between states
                Button("") { }
                    .buttonStyle(.compound(.primary))
                    .hidden()
            case .invalid:
                VStack(spacing: 16) {
                    Button(L10n.screenQrCodeLoginInvalidScanStateRetryButton) {
                        // TODO: Implement try again
                    }
                    .buttonStyle(.compound(.primary))
                    
                    VStack(spacing: 0) {
                        HStack(spacing: 10) {
                            CompoundIcon(\.error, size: .medium, relativeTo: .compound.bodyMDSemibold)
                                .accessibilityLabel(L10n.commonSendingFailed)
                            
                            Text(L10n.screenQrCodeLoginInvalidScanStateSubtitle)
                        }
                    }
                    .font(.compound.bodyMDSemibold)
                    .foregroundColor(.compound.textCriticalPrimary)
                    
                    Text(L10n.screenQrCodeLoginInvalidScanStateDescription)
                        .foregroundColor(.compound.textSecondary)
                        .font(.compound.bodySM)
                }
            }
        }
    }

    private var qrScanner: some View {
        QRCodeScannerView()
            .aspectRatio(1.0, contentMode: .fill)
            .frame(maxWidth: 312)
            .readFrame($qrFrame)
            .background(.compound.bgCanvasDefault)
            .overlay(
                Rectangle()
                    .stroke(.compound.textPrimary, style: StrokeStyle(lineWidth: 4.0, lineCap: .square, dash: [dashLenght, emptyLenght], dashPhase: dashPhase))
            )
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
    
    static let scanningStateViewModel = QRCodeLoginScreenViewModel.mock(state: .scan(.scanning))
    
    static let connectingStateViewModel = QRCodeLoginScreenViewModel.mock(state: .scan(.connecting))
    
    static let invalidStateViewModel = QRCodeLoginScreenViewModel.mock(state: .scan(.invalid))
    
    static var previews: some View {
        QRCodeLoginScreen(context: initialStateViewModel.context)
            .previewDisplayName("Initial")
        
        QRCodeLoginScreen(context: scanningStateViewModel.context)
            .previewDisplayName("Scanning")
        
        QRCodeLoginScreen(context: connectingStateViewModel.context)
            .previewDisplayName("Connecting")
        
        QRCodeLoginScreen(context: invalidStateViewModel.context)
            .previewDisplayName("Invalid")
    }
}
