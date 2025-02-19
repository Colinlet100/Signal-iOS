//
//  Copyright (c) 2022 Open Whisper Systems. All rights reserved.
//

import Foundation
import SignalServiceKit

class StoriesViewController: OWSViewController {
    let tableView = UITableView()
    private var models = [IncomingStoryViewModel]()

    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("STORIES_TITLE", comment: "Title for the stories view.")

        let cameraButton = UIBarButtonItem(image: Theme.iconImage(.cameraButton), style: .plain, target: self, action: #selector(showCameraView))
        cameraButton.accessibilityLabel = NSLocalizedString("CAMERA_BUTTON_LABEL", comment: "Accessibility label for camera button.")
        cameraButton.accessibilityHint = NSLocalizedString("CAMERA_BUTTON_HINT", comment: "Accessibility hint describing what you can do with the camera button")

        navigationItem.rightBarButtonItems = [cameraButton]

        databaseStorage.appendDatabaseChangeDelegate(self)

        tableView.register(StoryCell.self, forCellReuseIdentifier: StoryCell.reuseIdentifier)
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 116

        reloadStories()
    }

    private var timestampUpdateTimer: Timer?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        timestampUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            AssertIsOnMainThread()

            for indexPath in self.tableView.indexPathsForVisibleRows ?? [] {
                guard let cell = self.tableView.cellForRow(at: indexPath) as? StoryCell else { continue }
                guard let model = self.models[safe: indexPath.row] else { continue }
                cell.configureTimestamp(with: model)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Whether or not the theme has changed, always ensure
        // the right theme is applied. The initial collapsed
        // state of the split view controller is determined between
        // `viewWillAppear` and `viewDidAppear`, so this is the soonest
        // we can know the right thing to display.
        applyTheme()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // We could be changing between collapsed and expanded
        // split view state, so we must re-apply the theme.
        coordinator.animate { _ in
            self.applyTheme()
        } completion: { _ in
            self.applyTheme()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        timestampUpdateTimer?.invalidate()
        timestampUpdateTimer = nil
    }

    override func applyTheme() {
        super.applyTheme()

        for indexPath in self.tableView.indexPathsForVisibleRows ?? [] {
            guard let cell = self.tableView.cellForRow(at: indexPath) as? StoryCell else { continue }
            guard let model = self.models[safe: indexPath.row] else { continue }
            cell.configure(with: model)
        }

        if splitViewController?.isCollapsed == true {
            view.backgroundColor = Theme.backgroundColor
            tableView.backgroundColor = Theme.backgroundColor
        } else {
            view.backgroundColor = Theme.secondaryBackgroundColor
            tableView.backgroundColor = Theme.secondaryBackgroundColor
        }
    }

    @objc
    func showCameraView() {
        // Dismiss any message actions if they're presented
        conversationSplitViewController?.selectedConversationViewController?.dismissMessageContextMenu(animated: true)

        ows_askForCameraPermissions { cameraGranted in
            guard cameraGranted else {
                return Logger.warn("camera permission denied.")
            }
            self.ows_askForMicrophonePermissions { micGranted in
                if !micGranted {
                    // We can still continue without mic permissions, but any captured video will
                    // be silent.
                    Logger.warn("proceeding, though mic permission denied.")
                }

                let modal = CameraFirstCaptureNavigationController.cameraFirstModal()
                modal.cameraFirstCaptureSendFlow.delegate = self
                self.presentFullScreen(modal, animated: true)
            }
        }
    }

    private static let loadingQueue = DispatchQueue(label: "StoriesViewController.loadingQueue", qos: .userInitiated)
    private func reloadStories() {
        Self.loadingQueue.async {
            let incomingMessages = Self.databaseStorage.read { StoryFinder.incomingStories(transaction: $0) }
            let groupedMessages = Dictionary(grouping: incomingMessages) { $0.context }
            let newModels = Self.databaseStorage.read { transaction in
                groupedMessages.compactMap { try? IncomingStoryViewModel(messages: $1, transaction: transaction) }
            }.sorted { $0.latestMessageTimestamp > $1.latestMessageTimestamp }
            DispatchQueue.main.async {
                self.models = newModels
                self.tableView.reloadData()
            }
        }
    }

    private func updateStories(forRowIds rowIds: Set<Int64>) {
        guard !rowIds.isEmpty else { return }
        Self.loadingQueue.async {
            let updatedMessages = Self.databaseStorage.read {
                StoryFinder.incomingStoriesWithRowIds(Array(rowIds), transaction: $0)
            }
            var deletedRowIds = rowIds.subtracting(updatedMessages.map { $0.id! })
            var groupedMessages = Dictionary(grouping: updatedMessages) { $0.context }

            let oldContexts = self.models.map { $0.context }
            var changedContexts = [StoryContext]()

            let newModels: [IncomingStoryViewModel]
            do {
                newModels = try Self.databaseStorage.read { transaction in
                    try self.models.compactMap { model in
                        guard let latestMessage = model.messages.first else { return model }

                        let modelDeletedRowIds: [Int64] = model.messages.lazy.compactMap { $0.id }.filter { deletedRowIds.contains($0) }
                        deletedRowIds.subtract(modelDeletedRowIds)

                        let modelUpdatedMessages = groupedMessages.removeValue(forKey: latestMessage.context) ?? []

                        guard !modelUpdatedMessages.isEmpty || !modelDeletedRowIds.isEmpty else { return model }

                        changedContexts.append(model.context)

                        return try model.copy(
                            updatedMessages: modelUpdatedMessages,
                            deletedMessageRowIds: modelDeletedRowIds,
                            transaction: transaction
                        )
                    } + groupedMessages.map { try IncomingStoryViewModel(messages: $1, transaction: transaction) }
                }.sorted { $0.latestMessageTimestamp > $1.latestMessageTimestamp }
            } catch {
                owsFailDebug("Failed to build new models, hard reloading \(error)")
                DispatchQueue.main.async { self.reloadStories() }
                return
            }

            let batchUpdateItems: [BatchUpdate<StoryContext>.Item]
            do {
                batchUpdateItems = try BatchUpdate.build(
                    viewType: .uiTableView,
                    oldValues: oldContexts,
                    newValues: newModels.map { $0.context },
                    changedValues: changedContexts
                )
            } catch {
                owsFailDebug("Failed to calculate batch updates, hard reloading \(error)")
                DispatchQueue.main.async { self.reloadStories() }
                return
            }

            DispatchQueue.main.async {
                self.models = newModels
                self.tableView.beginUpdates()
                for update in batchUpdateItems {
                    switch update.updateType {
                    case .delete(let oldIndex):
                        self.tableView.deleteRows(at: [IndexPath(row: oldIndex, section: 0)], with: .automatic)
                    case .insert(let newIndex):
                        self.tableView.insertRows(at: [IndexPath(row: newIndex, section: 0)], with: .automatic)
                    case .move(let oldIndex, let newIndex):
                        self.tableView.deleteRows(at: [IndexPath(row: oldIndex, section: 0)], with: .automatic)
                        self.tableView.insertRows(at: [IndexPath(row: newIndex, section: 0)], with: .automatic)
                    case .update(_, let newIndex):
                        // If the cell is visible, reconfigure it directly without reloading.
                        let path = IndexPath(row: newIndex, section: 0)
                        if (self.tableView.indexPathsForVisibleRows ?? []).contains(path),
                            let visibleCell = self.tableView.cellForRow(at: path) as? StoryCell {
                            guard let model = self.models[safe: newIndex] else {
                                return owsFailDebug("Missing model for story")
                            }
                            visibleCell.configure(with: model)
                        } else {
                            self.tableView.reloadRows(at: [path], with: .none)
                        }
                    }
                }
                self.tableView.endUpdates()
            }
        }
    }
}

extension StoriesViewController: CameraFirstCaptureDelegate {
    func cameraFirstCaptureSendFlowDidComplete(_ cameraFirstCaptureSendFlow: CameraFirstCaptureSendFlow) {
        dismiss(animated: true)
    }

    func cameraFirstCaptureSendFlowDidCancel(_ cameraFirstCaptureSendFlow: CameraFirstCaptureSendFlow) {
        dismiss(animated: true)
    }
}

extension StoriesViewController: DatabaseChangeDelegate {
    func databaseChangesDidUpdate(databaseChanges: DatabaseChanges) {
        updateStories(forRowIds: databaseChanges.storyMessageRowIds)
    }

    func databaseChangesDidUpdateExternally() {
        reloadStories()
    }

    func databaseChangesDidReset() {
        reloadStories()
    }
}

extension StoriesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let model = models[safe: indexPath.row] else {
            owsFailDebug("Missing model for story")
            return
        }
        let vc = StoryPageViewController(context: model.context)
        vc.contextDataSource = self
        presentFullScreen(vc, animated: true)
    }
}

extension StoriesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: StoryCell.reuseIdentifier) as! StoryCell
        guard let model = models[safe: indexPath.row] else {
            owsFailDebug("Missing model for story")
            return cell
        }
        cell.configure(with: model)
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
}

extension StoriesViewController: StoryPageViewControllerDataSource {
    func storyPageViewController(_ storyPageViewController: StoryPageViewController, storyContextBefore storyContext: StoryContext) -> StoryContext? {
        guard let contextIndex = models.firstIndex(where: { $0.context == storyContext }),
              let contextBefore = models[safe: contextIndex.advanced(by: -1)]?.context else {
                  return nil
              }
        return contextBefore
    }

    func storyPageViewController(_ storyPageViewController: StoryPageViewController, storyContextAfter storyContext: StoryContext) -> StoryContext? {
        guard let contextIndex = models.firstIndex(where: { $0.context == storyContext }),
              let contextAfter = models[safe: contextIndex.advanced(by: 1)]?.context else {
                  return nil
              }
        return contextAfter
    }
}
