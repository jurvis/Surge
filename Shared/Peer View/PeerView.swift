//
//  PeerView.swift
//  Surge (iOS)
//
//  Created by Jurvis on 12/17/22.
//

import SwiftUI

struct PeerView: View {
    @StateObject var viewModel: PeerViewModel
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Action")) {
                    if viewModel.isPeerConnected {
                        Text("Peer Connected!")
                            .foregroundColor(.green)
                    } else {
                        Button("Connect Peer") {
                            Task {
                                await viewModel.connectPeer()
                            }
                        }
                    }
                    
                    NavigationLink(
                        destination: PeerRequestChannelView(
                            viewModel: PeerRequestChannelViewModel(
                                isViewActive: $viewModel.isShowingEdit
                            )
                        ),
                        isActive: $viewModel.isShowingEdit
                    ) {
                        Text("Request Channel Open")
                    }
                }
                Section(header: Text("Pending Funding Scripts")) {
                    ForEach(viewModel.peer.pendingFundingTransactionPubKeys, id: \.self) { pubKey in
                        Text(pubKey)
                    }
                }
                Section(header: Text("Active Channels")) {
                    Text("asbdvasd")
                }
            }
            .navigationTitle(viewModel.peer.name)
            .listStyle(.grouped)
        }
        .environmentObject(viewModel.peer)
    }
}

struct PeerView_Previews: PreviewProvider {
    static var previews: some View {
        PeerView(viewModel: PeerViewModel(peer: Peer(peerPubKey: "abc", name: "Alice", connectionInformation: .init(hostname: "abc.com", port: 245))))
    }
}
