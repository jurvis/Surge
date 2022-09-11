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
    
    var shouldShowEmptyState: Bool {
        peersToShow.count == 0
    }
    
    enum Sheet: Identifiable {
        var id: Self { self }
        case addPeer
    }

    internal init(peersViewModels: [PeerCellViewModel] = []) {
        setup()
    }

    
    private func setup() {
        // Grab list of peers and set `peersViewModels`
        PeerStore.load { [unowned self] result in
            switch result {
            case .success(let peers):
                self.peersToShow = peers
            case .failure:
                self.peersToShow = []
            }
        }
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
            
            PeerStore.save(peers: peersToShow) { result in
                switch result {
                case .success(let peerCount):
                    print("Saved \(peerCount) peers to disk.")
                    // Dismiss add peer screen
                    self.sheetToShow = nil
                case .failure(_):
                    // FIXME: Handle some saving error
                    print("Error saving peer to disk")
                }
            }
        }
        
        return AddPeerView(viewModel: addPeerViewModel)
    }
}
