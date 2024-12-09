//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Compound
import QuickLook
import SwiftUI

class TimelineMediaPreviewController: QLPreviewController, QLPreviewControllerDataSource {
    private let viewModel: TimelineMediaPreviewViewModel
    
    private var cancellables: Set<AnyCancellable> = []
    
    private let headerHostingController: UIHostingController<HeaderView>
    private let captionHostingController: UIHostingController<CaptionView>
    private let detailsHostingController: UIHostingController<TimelineMediaPreviewDetailsView>
    
    private var navigationBar: UINavigationBar? { view.subviews.first?.subviews.first(where: { $0 is UINavigationBar }) as? UINavigationBar }
    private var toolbar: UIToolbar? { view.subviews.first?.subviews.last(where: { $0 is UIToolbar }) as? UIToolbar }
    private var captionView: UIView { captionHostingController.view }
    
    init(viewModel: TimelineMediaPreviewViewModel) {
        self.viewModel = viewModel
        
        headerHostingController = UIHostingController(rootView: HeaderView(context: viewModel.context))
        headerHostingController.view.backgroundColor = .clear
        captionHostingController = UIHostingController(rootView: CaptionView(context: viewModel.context))
        captionHostingController.view.backgroundColor = .clear
        detailsHostingController = UIHostingController(rootView: TimelineMediaPreviewDetailsView(context: viewModel.context))
        detailsHostingController.view.backgroundColor = .compound.bgCanvasDefault
        
        // let materialView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
        // captionHostingController.view.insertMatchedSubview(materialView, at: 0)
        
        super.init(nibName: nil, bundle: nil)
        
        view.addSubview(captionView)
        
        // Observation of currentPreviewItem doesn't work, so use the index instead.
        publisher(for: \.currentPreviewItemIndex)
            .sink { [weak self] _ in
                guard let self, let currentPreviewItem = currentPreviewItem as? TimelineMediaPreviewItem else { return }
                Task { await self.viewModel.updateCurrentItem(currentPreviewItem) }
            }
            .store(in: &cancellables)
        
        viewModel.actions
            .sink { [weak self] action in
                switch action {
                case .loadedMediaFile:
                    self?.refreshCurrentPreviewItem()
                case .viewInTimeline:
                    self?.dismiss(animated: true) // Dismiss the details sheet.
                    // Errrr, hmmmmm, do something else here.
                }
            }
            .store(in: &cancellables)
        
        dataSource = self
    }
    
    @available(*, unavailable) required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        overrideUserInterfaceStyle = .dark
        
        if let toolbar {
            captionView.isHidden = toolbar.alpha == 0
            
            if captionView.constraints.isEmpty {
                captionView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    captionView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
                    captionView.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor),
                    captionView.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor)
                ])
            }
        }
        
        navigationBar?.topItem?.titleView = headerHostingController.view
        
        if navigationBar?.topItem?.rightBarButtonItems?.count == 1 {
            navigationBar?.topItem?.rightBarButtonItems?.append(UIBarButtonItem(image: UIImage(systemSymbol: .infoCircle), style: .plain, target: self, action: #selector(presentMediaDetails)))
        }
    }
    
    // MARK: QLPreviewControllerDataSource
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        viewModel.state.previewItems.count
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        viewModel.state.previewItems[index]
    }
    
    // MARK: Private
    
    @objc func presentMediaDetails() {
        detailsHostingController.overrideUserInterfaceStyle = .dark
        detailsHostingController.sheetPresentationController?.detents = [.medium()]
        detailsHostingController.sheetPresentationController?.prefersGrabberVisible = true
        
        present(detailsHostingController, animated: true)
    }
}

// MARK: - Subviews

private struct HeaderView: View {
    @ObservedObject var context: TimelineMediaPreviewViewModel.Context
    
    var body: some View {
        VStack(spacing: 0) {
            Text(context.viewState.currentItem?.sender.displayName ?? context.viewState.currentItem?.sender.id ?? L10n.commonLoading)
                .font(.compound.bodySMSemibold)
                .foregroundStyle(.compound.textPrimary)
            Text(context.viewState.currentItem?.timestamp.formatted(date: .abbreviated, time: .omitted) ?? "")
                .font(.compound.bodyXS)
                .foregroundStyle(.compound.textPrimary)
                .textCase(.uppercase)
        }
    }
}

private struct CaptionView: View {
    @ObservedObject var context: TimelineMediaPreviewViewModel.Context
    
    var body: some View {
        if let caption = context.viewState.currentItem?.caption {
            Text(caption)
                .font(.compound.bodyLG)
                .foregroundStyle(.compound.textPrimary)
                .lineLimit(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(16)
                .background(.ultraThinMaterial)
        }
    }
}
