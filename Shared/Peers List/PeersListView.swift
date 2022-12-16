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
                        ForEach(viewModel.peersToShow, id: \.id) { peer in
                            peerCell(peer: peer)
                        }
                        .onDelete(perform: viewModel.deletePeer)
                    }
                }
            }
            .navigationTitle("Your Peers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    addPeerButton()
                }
            }
            .sheet(item: $viewModel.sheetToShow) { sheet  in
                switch sheet {
                case .addPeer:
                    viewModel.addPeerView()
                }
            }
            .confirmationDialog("Action", isPresented: viewModel.showConfirmationDialog) {
                Button("Connect Peer") {
                    Task {
                        await viewModel.connectFocusedPeer()
                        viewModel.dismissFocusedPeer()
                    }
                }
                Button("Open Channel") {
                    Task {
                        await viewModel.openChannelWithFocusedPeer()
                    }
                }
                Button("Cancel", role: .cancel) { viewModel.dismissFocusedPeer() }
            }
        }
    }
    
    @ViewBuilder
    func peerCell(peer: Peer) -> some View {
        let isPeerActive = viewModel.isNodeActive(nodeId: peer.peerPubKey)
        PeerCell(viewModel: PeerCellViewModel(name: peer.name), connectionStatus: isPeerActive ? .connected : .unconnected)
            .onTapGesture {
                self.viewModel.focusPeer(peer: peer)
            }
    }
    
    @ViewBuilder
    func addPeerButton() -> some View {
        Button {
            viewModel.showAddPeerScreen()
        } label: {
            HStack(spacing: 0) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    
                Text("Add")
                    .font(.system(size: 12, weight: .bold))
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .foregroundColor(.white)
            .background(Capsule(style: .circular))
        }
    }
}

struct PeersListView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyConnectionInfo = Peer.PeerConnectionInformation(hostname: "localhost", port: 8080)
        let listViewModel = PeersListViewModel(peers: [
            Peer(peerPubKey: "abc", name: "Alice", connectionInformation: dummyConnectionInfo),
            Peer(peerPubKey: "def", name: "Bob", connectionInformation: dummyConnectionInfo),
            Peer(peerPubKey: "ghi", name: "Charlie", connectionInformation: dummyConnectionInfo)]
        )
        
        PeersListView(viewModel: listViewModel)
        PeersListView()
    }
}
