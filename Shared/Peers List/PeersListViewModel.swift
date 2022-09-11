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
    @Published var shouldShowEmptyState = true

    internal init(peersViewModels: [PeerCellViewModel] = []) {
        self.peersViewModels = peersViewModels
        
        setup()
    }
    
    func setup() {
        // Grab list of peers and set `peersViewModels`
        
        if peersViewModels.count > 0 {
            self.shouldShowEmptyState = false
        }
    }
}
