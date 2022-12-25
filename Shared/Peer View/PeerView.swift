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
                                await                             viewModel.connectPeer()
                            }
                        }
                    }

                    Button("Request Channel Open") {
                        print("")
                    }
                }
                Section(header: Text("Pending Funding Scripts")) {
                    Text("abcdef")
                }
                Section(header: Text("Active Channels")) {
                    Text("asbdvasd")
                }
            }
            .navigationTitle(viewModel.peer.name)
            .listStyle(.grouped)
        }
        
    }
}

struct PeerView_Previews: PreviewProvider {
    static var previews: some View {
        PeerView(viewModel: PeerViewModel(peer: Peer(peerPubKey: "abc", name: "Alice", connectionInformation: .init(hostname: "abc.com", port: 245))))
    }
}
