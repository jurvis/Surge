//
//  PeerRequestChannelViewModel.swift
//  Surge
//
//  Created by Jurvis on 12/25/22.
//

import Foundation
import SwiftUI

class PeerRequestChannelViewModel: ObservableObject {
    @Published var channelValue: String = ""
    @Published var reserveAmount: String = ""
    
    var isViewActive: Binding<Bool>
    
    internal init(isViewActive: Binding<Bool>) {
        self.isViewActive = isViewActive
    }
    
    var isSaveButtonEnabled: Bool {
        return !channelValue.isEmpty && !reserveAmount.isEmpty
    }
    
    func createNewFundingTransaction(for peer: Peer) async {
        do {
            let scriptPubKey = try await getFundingTransactionScriptPubkey(peer: peer)
            peer.addFundingTransactionPubkey(pubkey: scriptPubKey)
            PeerStore.update(peer: peer) { result in
                switch result {
                case .success(_):
                    print("Saved peer: \(peer.peerPubKey)")
                case .failure(_):
                    // TOODO: Handle saving new funding transaction pubkey error
                    print("Error persisting new pub key")
                }
            }
            DispatchQueue.main.async { [weak self] in
                self?.isViewActive.wrappedValue.toggle()
            }
        } catch {
            print("Unable to create funding script pub key")
        }
    }
    
    private func getFundingTransactionScriptPubkey(peer: Peer) async throws -> String {
        return try await LightningNodeService.shared.requestChannelOpen(
            peer.peerPubKey,
            channelValue: UInt64(channelValue)!,
            reserveAmount: UInt64(reserveAmount)!
        )
    }
}
