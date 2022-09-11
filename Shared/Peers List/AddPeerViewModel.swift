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
    
    var onSave: (() -> Void)? = nil
    
    var isFormValid: Bool {
        !pubKey.isEmpty && !name.isEmpty
    }
    
    func savePeer() {
        // Write to disk
        // Tell Lightning node to connect to peer
        onSave?()
    }
}
