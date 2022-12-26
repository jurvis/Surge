//
//  PeersListViewModel.swift
//  Surge
//
//  Created by Jurvis on 9/11/22.
//

import Foundation
import Combine
import SwiftUI

class PeersListViewModel: ObservableObject {
    @Published var sheetToShow: Sheet?
    @Published var peersToShow: [Peer] = []
    @Published var activePeerNodeIds: [String] = []
    @Published private var focusedPeer: Peer?
    
    var showConfirmationDialog: Binding<Bool> {
        Binding {
            if let _ = self.focusedPeer {
                return true
            } else {
                return false
            }

        } set: { shouldShowConfirmationDialog in
            if !shouldShowConfirmationDialog {
                self.focusedPeer = nil
            }
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    var shouldShowEmptyState: Bool {
        peersToShow.count == 0
    }
    
    enum Sheet: Hashable, Identifiable {
        var id: Self { self }
        case addPeer
        case showPeer(Peer)
    }

    internal init(peers: [Peer] = []) {
        self.peersToShow = peers
        setup()
    }
    
    func isNodeActive(nodeId: String) -> Bool {
        return activePeerNodeIds.contains(nodeId)
    }
    
    func connectPeer(_ peer: Peer) async {
        do {
            try await LightningNodeService.shared.connectPeer(peer)
        } catch {
            print("Error connecting to peer")
        }
    }
    
    func focusPeer(peer: Peer) {
        focusedPeer = peer
    }
    
    func dismissFocusedPeer() {
        focusedPeer = nil
    }

    func connectFocusedPeer() async {
        guard let peer = focusedPeer else {
            return
        }
        
        do {
            try await LightningNodeService.shared.connectPeer(peer)
        } catch {
            print("Error connecting to peer")
        }
    }
    
    func deletePeer(at offsets: IndexSet) {
        let oldPeerCount = peersToShow.count
        
        peersToShow.remove(atOffsets: offsets)
                
        if oldPeerCount != peersToShow.count {
            saveCurrentListofPeersToDisk()
        }
    }
}

// MARK: Helper Methods
extension PeersListViewModel {
    private func saveCurrentListofPeersToDisk(completion: (() -> Void)? = nil) {
        PeerStore.save(peers: peersToShow) { result in
            switch result {
            case .success(let peerCount):
                print("Saved \(peerCount) peers to disk.")
                completion?()
            case .failure(_):
                // FIXME: Handle some saving error
                print("Error saving peer to disk")
            }
        }
    }
    
    private func setup() {
        // Grab list of peers and set `peersViewModels`
        PeerStore.load { [unowned self] result in
            switch result {
            case .success(let peers):
                self.peersToShow = Array(peers.values)
            case .failure:
                self.peersToShow = []
            }
        }
        
        LightningNodeService.shared.activePeersPublisher
            .assign(to: \.activePeerNodeIds, on: self)
            .store(in: &cancellables)
    }
}

// MARK: Navigation
extension PeersListViewModel {
    func showAddPeerScreen() {
        self.sheetToShow = .addPeer
    }
    
    func addPeerView() -> some View {
        let addPeerViewModel = AddPeerViewModel()
        addPeerViewModel.onSave = { [unowned self] peer in
            // Append peers to list
            peersToShow = peersToShow + [peer]
            saveCurrentListofPeersToDisk { [unowned self] in
                self.sheetToShow = nil
            }
        }
        
        return AddPeerView(viewModel: addPeerViewModel)
    }
    
    func showPeerScreen(peer: Peer) {
        DispatchQueue.main.async { [unowned self] in
            self.sheetToShow = .showPeer(peer)
        }
    }
    
    func showPeerView(peer: Peer) -> some View {
        return PeerView(viewModel: PeerViewModel(peer: peer))
    }
}
