//
//  PeerViewModel.swift
//  Surge (iOS)
//
//  Created by Jurvis on 12/24/22.
//

import Foundation
import Combine

class PeerViewModel: ObservableObject {
    @Published var peer: Peer
    @Published var activePeerNodeIds: [String] = []
    
    @Published var isShowingEdit = false
    
    var isPeerConnected: Bool {
        return activePeerNodeIds.contains(peer.peerPubKey)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(peer: Peer) {
        self.peer = peer
        setup()
    }
    
    func connectPeer() async {
        do {
            try await LightningNodeService.shared.connectPeer(peer)
        } catch {
            print("Error connecting to peer")
        }
    }
    private func setup() {
        LightningNodeService.shared.activePeersPublisher
            .assign(to: \.activePeerNodeIds, on: self)
            .store(in: &cancellables)
    }
}
