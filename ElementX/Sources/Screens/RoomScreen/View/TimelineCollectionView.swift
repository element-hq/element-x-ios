//
//  TimelineListView.swift
//  UITimeline
//
//  Created by Doug on 23/11/2022.
//

import Combine
import SwiftUI

class TimelineItemSwiftUICell: UICollectionViewCell {
    #warning("Do more in here")
    var timelineItem: RoomTimelineViewProvider?
}

struct TimelineCollectionView: UIViewRepresentable {
    @EnvironmentObject private var viewModelContext: RoomScreenViewModel.Context
    @Environment(\.timelineStyle) private var timelineStyle
    
    #warning("Should this come via the context like loadPreviousPage???")
    let scrollToBottomPublisher: PassthroughSubject<Void, Never>
    @Binding var scrollToBottomButtonVisible: Bool
    
    func makeUIView(context: Context) -> UICollectionView {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: context.coordinator.makeLayout())
        collectionView.keyboardDismissMode = .onDrag
        context.coordinator.collectionView = collectionView
        context.coordinator.loadPreviousPagePublisher = viewModelContext.viewState.loadPreviousPagePublisher
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        if context.coordinator.timelineItems != viewModelContext.viewState.items {
            context.coordinator.timelineItems = viewModelContext.viewState.items
        }
        if context.coordinator.isBackPaginating != viewModelContext.viewState.isBackPaginating {
            context.coordinator.isBackPaginating = viewModelContext.viewState.isBackPaginating
        }
        if context.coordinator.timelineStyle != timelineStyle {
            context.coordinator.timelineStyle = timelineStyle
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModelContext: viewModelContext,
                    scrollToBottomPublisher: scrollToBottomPublisher,
                    scrollToBottomButtonVisible: $scrollToBottomButtonVisible)
    }
    
    // MARK: - Coordinator
    
    @MainActor
    class Coordinator: NSObject {
        let viewModelContext: RoomScreenViewModel.Context
        
        var collectionView: UICollectionView? {
            didSet {
                configureDataSource()
            }
        }
        
        var timelineStyle: TimelineStyle = .bubbles
        var timelineItems: [RoomTimelineViewProvider] = [] {
            didSet {
                applySnapshot()
            }
        }
        
        var isBackPaginating = false {
            didSet {
                // TODO: Paginate again if needed
            }
        }
        
        var loadPreviousPagePublisher = PassthroughSubject<Void, Never>()
        var cancellables: Set<AnyCancellable> = []
        @Binding var scrollToBottomButtonVisible: Bool
        
        private var dataSource: UICollectionViewDiffableDataSource<TimelineSection, RoomTimelineViewProvider>?
        
        init(viewModelContext: RoomScreenViewModel.Context,
             scrollToBottomPublisher: PassthroughSubject<Void, Never>,
             scrollToBottomButtonVisible: Binding<Bool>) {
            self.viewModelContext = viewModelContext
            _scrollToBottomButtonVisible = scrollToBottomButtonVisible
            super.init()
            
            scrollToBottomPublisher
                .sink { [weak self] _ in
                    self?.scrollToBottom(animated: true)
                }
                .store(in: &cancellables)
        }
        
        func makeLayout() -> UICollectionViewCompositionalLayout {
            var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
            configuration.showsSeparators = false
            return UICollectionViewCompositionalLayout.list(using: configuration)
        }
        
        private func configureDataSource() {
            guard let collectionView else { return }
            let cellRegistration = UICollectionView.CellRegistration<TimelineItemSwiftUICell, RoomTimelineViewProvider> { cell, indexPath, timelineItem in
                cell.timelineItem = timelineItem
            }
            
            dataSource = .init(collectionView: collectionView) { collectionView, indexPath, timelineItem in
                #warning("Do we need a weak self here???")
                let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: timelineItem)
                cell.contentConfiguration = UIHostingConfiguration {
                    timelineItem
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contextMenu {
                            self.viewModelContext.viewState.contextMenuBuilder?(timelineItem.id)
                        }
                        .opacity(self.opacityForItem(timelineItem))
                        .onAppear {
                            self.viewModelContext.send(viewAction: .itemAppeared(id: timelineItem.id))
                        }
                        .onDisappear {
                            self.viewModelContext.send(viewAction: .itemDisappeared(id: timelineItem.id))
                        }
                        .environment(\.openURL, OpenURLAction { url in
                            self.viewModelContext.send(viewAction: .linkClicked(url: url))
                            return .systemAction
                        })
                        .onTapGesture {
                            self.viewModelContext.send(viewAction: .itemTapped(id: timelineItem.id))
                        }
                }
                .margins(.all, self.timelineStyle.rowInsets)
                
                return cell
            }
            
            collectionView.delegate = self
        }
        
        func applySnapshot() {
            let previousLayout = layout()
            
            var snapshot = NSDiffableDataSourceSnapshot<TimelineSection, RoomTimelineViewProvider>()
            snapshot.appendSections([.main])
            snapshot.appendItems(timelineItems)
            dataSource?.apply(snapshot, animatingDifferences: false)
            
            guard snapshot.numberOfItems != previousLayout.numberOfItems else { return }
            
            if previousLayout.isBottomVisible || previousLayout.isEmpty {
                let animated = !previousLayout.isEmpty
                scrollToBottom(animated: false)
            } else if let pinnedItem = previousLayout.pinnedItem,
                      let collectionView,
                      let item = snapshot.itemIdentifiers.first(where: { $0.id == pinnedItem.id }),
                      let indexPath = dataSource?.indexPath(for: item) {
                collectionView.scrollToItem(at: indexPath, at: pinnedItem.position, animated: false)
            }
        }
        
        func layout() -> LayoutDescriptor {
            guard let collectionView, let dataSource else { return LayoutDescriptor() }
            
            let snapshot = dataSource.snapshot()
            var layout = LayoutDescriptor(numberOfItems: snapshot.numberOfItems, contentSize: collectionView.contentSize)
            
            guard !snapshot.itemIdentifiers.isEmpty else {
                layout.isEmpty = true
                return layout
            }
            
            if let firstVisibleIndexPath = collectionView.indexPathsForVisibleItems.first,
               let firstVisibleItem = dataSource.itemIdentifier(for: firstVisibleIndexPath) {
                layout.pinnedItem = PinnedItem(id: firstVisibleItem.id, position: .top)
            }
            
            if let lastItem = snapshot.itemIdentifiers.last,
               let lastIndexPath = dataSource.indexPath(for: lastItem) {
                layout.isBottomVisible = collectionView.indexPathsForVisibleItems.contains(lastIndexPath)
            }
            
            return layout
        }
        
        func scrollToBottom(animated: Bool) {
            guard let lastItem = timelineItems.last,
                  let lastIndexPath = dataSource?.indexPath(for: lastItem)
            else { return }
            
            collectionView?.scrollToItem(at: lastIndexPath, at: .bottom, animated: animated)
        }
        
        private func opacityForItem(_ item: RoomTimelineViewProvider) -> Double {
            guard case let .reply(selectedItemId, _) = viewModelContext.viewState.composerMode else {
                return 1.0
            }
            
            return selectedItemId == item.id ? 1.0 : 0.5
        }
        
        // TODO: Handle frame changes.
    }
    
    enum TimelineSection { case main }
    
    struct LayoutDescriptor {
        var numberOfItems = 0
        var pinnedItem: PinnedItem?
        var isBottomVisible = false
        var isEmpty = false
        var contentSize: CGSize = .zero
    }
    
    struct PinnedItem {
        let id: String
        let position: UICollectionView.ScrollPosition
    }
}

// MARK: - UICollectionViewDelegate

extension TimelineCollectionView.Coordinator: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let isAtBottom = isAtBottom(of: scrollView)
        
        if !scrollToBottomButtonVisible, isAtBottom {
            DispatchQueue.main.async { self.scrollToBottomButtonVisible = true }
        } else if scrollToBottomButtonVisible, !isAtBottom {
            DispatchQueue.main.async { self.scrollToBottomButtonVisible = false }
        }
        
        if scrollView.contentOffset.y < paginationThreshold(for: scrollView), !isBackPaginating {
            loadPreviousPagePublisher.send(())
        }
    }
    
    func isAtBottom(of scrollView: UIScrollView) -> Bool {
        scrollView.contentOffset.y < (scrollView.contentSize.height - scrollView.visibleSize.height - 15)
    }
    
    func paginationThreshold(for scrollView: UIScrollView) -> Double {
        scrollView.visibleSize.height * 2.0
    }
}


// MARK: - Previews

struct TimelineCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    static var body: some View {
        let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                            timelineViewFactory: RoomTimelineViewFactory(),
                                            mediaProvider: MockMediaProvider(),
                                            roomName: "Preview room")
        
        NavigationView {
            RoomScreen(context: viewModel.context)
        }
    }
}
