//
//  PeersListView.swift
//  Surge
//
//  Created by Jurvis on 9/10/22.
//

import SwiftUI

struct PeersListView: View {
    var body: some View {
        NavigationView {
            List {
                HStack(alignment: .center, spacing: 12) {
                    Text("Alice")
                    Spacer()
                    
                    HStack {
                        Text("100/250")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(Color(.darkGray))
                        Image(systemName: "circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                    }
                }
                
                HStack(alignment: .center, spacing: 12) {
                    Text("Bob")
                    Spacer()
                    
                    HStack {
                        Text("PENDING")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(Color(.darkGray))
                        Image(systemName: "circle.dotted")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                    }
                }
                
                HStack(alignment: .center, spacing: 12) {
                    Text("Charlie")
                    Spacer()
                    
                    HStack {
                        Text("Open Channel")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(Color(.darkGray))
                        Image(systemName: "circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(.systemGray2))
                    }
                }
            }
        }
    }
}

struct PeersListView_Previews: PreviewProvider {
    static var previews: some View {
        PeersListView()
    }
}
