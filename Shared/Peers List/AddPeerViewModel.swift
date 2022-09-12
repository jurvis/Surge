//
//  AddPeerViewModel.swift
//  Surge
//
//  Created by Jurvis on 9/11/22.
//

import Foundation

class AddPeerViewModel: ObservableObject {
    @Published var pubKey: String = ""
    @Published var name: String = ""
    
    var onSave: ((Peer) -> Void)? = nil
    
    var isFormValid: Bool {
        !pubKey.isEmpty && !name.isEmpty
    }
    
    func savePeer() {
        // Send Peer information back to callback
        onSave?(Peer(peerPubKey: pubKey, name: name, connectionStatus: .unconnected))
    }
}
