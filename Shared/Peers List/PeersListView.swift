//
//  PeersListView.swift
//  Surge
//
//  Created by Jurvis on 9/10/22.
//

import SwiftUI

struct PeersListView: View {
    @StateObject var viewModel: PeersListViewModel = PeersListViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.peersViewModels, id: \.name) { peerCellViewModel in
                    PeerCell(viewModel: peerCellViewModel)
                }
            }
        }
    }
}

struct PeersListView_Previews: PreviewProvider {
    static var previews: some View {
        let listViewModel = PeersListViewModel(peersViewModels: [
            PeerCellViewModel(name: "Alice", connectionStatus: .connected(PeerCellViewModel.LiquidityInformation(inboundLiqudity: 100, outboundLiqudity: 250))),
            PeerCellViewModel(name: "Bob", connectionStatus: .pending(PeerCellViewModel.LiquidityInformation(inboundLiqudity: 0, outboundLiqudity: 0))),
            PeerCellViewModel(name: "Charlie", connectionStatus: .unconnected)
        ])
        
        PeersListView(viewModel: listViewModel)
    }
}
