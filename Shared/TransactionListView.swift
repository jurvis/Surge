//
//  TransactionListView.swift
//  Surge
//
//  Created by Jurvis on 9/10/22.
//

import SwiftUI

struct TransactionListView: View {
    var body: some View {
        NavigationView {
            List {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.up.forward.square.fill")
                    VStack(alignment: .leading) {
                        Text("Sent")
                            .font(.system(.callout))
                            .foregroundColor(Color(.darkText))
                        Text("5 days ago")
                            .font(.system(.caption))
                            .foregroundColor(Color.gray)
                    }
                    Spacer()
                    HStack(alignment: .bottom, spacing: 3) {
                        Text("100")
                            .font(.system(.callout, design: .rounded))
                        Text("sats")
                            .font(.system(.caption2))
                            .foregroundColor(Color(.darkGray))
                    }
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "arrow.down.backward.square.fill")
                    VStack(alignment: .leading) {
                        Text("Received")
                            .font(.system(.callout))
                            .foregroundColor(Color(.darkText))
                        Text("6 days ago")
                            .font(.system(.caption))
                            .foregroundColor(Color.gray)
                    }
                    Spacer()
                    HStack(alignment: .bottom, spacing: 3) {
                        Text("400")
                            .font(.system(.callout, design: .rounded))
                        Text("sats")
                            .font(.system(.caption2))
                            .foregroundColor(Color(.darkGray))
                    }
                }
            }
        }
    }
}

struct TransactionListView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionListView()
    }
}
