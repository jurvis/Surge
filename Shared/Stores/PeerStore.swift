//
//  PeerStore.swift
//  Surge
//
//  Created by Jurvis on 9/11/22.
//

import Foundation

class PeerStore: ObservableObject {
    @Published var peers: [Peer] = []
    
    static func load(completion: @escaping (Result<[Peer], Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let fileURL = try fileUrl()
                guard let file = try? FileHandle(forReadingFrom: fileURL) else {
                    DispatchQueue.main.async {
                        completion(.success([]))
                    }
                    return
                }
                
                let peers = try JSONDecoder().decode([Peer].self, from: file.availableData)
                DispatchQueue.main.async {
                    completion(.success(peers))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    static func save(peers: [Peer], completion: @escaping (Result<Int, Error>)->Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try JSONEncoder().encode(peers)
                let outfile = try fileUrl()
                try data.write(to: outfile)
                DispatchQueue.main.async {
                    completion(.success(peers.count))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                    
                }
            }
        }
    }
    
    private static func fileUrl() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
            .appendingPathComponent("peers.data")
    }
}
