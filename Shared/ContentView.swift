//
//  ContentView.swift
//  Shared
//
//  Created by Jurvis on 9/4/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    VStack(spacing: 48) {
                        VStack {
                            Text("100")
                                .font(.system(size: 72, design: .rounded))
                                .foregroundColor(Color(.darkText))
                            Text("sats")
                                .font(.system(.callout))
                                .foregroundColor(Color(.darkText))
                        }
                                            
                        HStack(spacing: 62) {
                            VStack(spacing: 4) {
                                Image(systemName: "paperplane.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.orange)
                                Text("Send")
                                    .font(.callout)
                                    .foregroundColor(Color(.darkText))
                            }
                            VStack(spacing: 4) {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 48))
                                    .foregroundColor(.teal)
                                Text("Receive")
                                    .font(.callout)
                                    .foregroundColor(Color(.darkText))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 48))
                        .foregroundColor(Color(.systemGray))
                }
                .navigationBarItems(
                    trailing: Button(action: {
                        print("Open Peers Menu")
                    }, label:  {
                        Image(systemName: "person.3.sequence.fill")
                            .foregroundColor(Color(.darkText))
                    })
                )
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
