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
    @Published var hostname: String = ""
    @Published var port: String = ""
    
    var onSave: ((Peer) -> Void)? = nil
    
    var isFormValid: Bool {
        !pubKey.isEmpty && !name.isEmpty
    }
    
    func savePeer() {
        guard let portInteger =  UInt16(port) else { return }
        let connectionInformation = Peer.PeerConnectionInformation(hostname: hostname, port: portInteger)
        // Send Peer information back to callback
        onSave?(Peer(peerPubKey: pubKey, name: name, connectionStatus: .unconnected, connectionInformation: connectionInformation))
    }
}
