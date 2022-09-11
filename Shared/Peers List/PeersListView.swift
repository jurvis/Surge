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
            Group {
                if viewModel.shouldShowEmptyState {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 64))
                            .foregroundColor(Color(.systemGray))
                        VStack(spacing: 8) {
                            Text("You have no peers.")
                            Text("Hit the \"+\" button to add one.")
                        }
                        .foregroundColor(Color(.darkText))
                    }
                } else {
                    List {
                        ForEach(viewModel.peersViewModels, id: \.name) { peerCellViewModel in
                            PeerCell(viewModel: peerCellViewModel)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        print("Add a Peer")
                    } label: {
                        Image(systemName: "plus")
                    }
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
        PeersListView()
    }
}
