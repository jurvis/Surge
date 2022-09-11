//
//  PeersListViewModel.swift
//  Surge
//
//  Created by Jurvis on 9/11/22.
//

import Foundation
import Combine

class PeersListViewModel: ObservableObject {
    @Published var peersViewModels: [PeerCellViewModel]
    

    internal init(peersViewModels: [PeerCellViewModel] = []) {
        self.peersViewModels = peersViewModels
    }
    
    func setup() {
        // Grab list of peers and set `peersViewModels`
    }
}
