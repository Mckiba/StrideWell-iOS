//
//  Residue.swift
//  Stridewell
//
//  Manages the pool of settled particles that accumulate at the bottom
//  of the residue overlay. Particles spawn at a rate proportional to
//  storm strength and expire after a short lifetime.
//

import SwiftUI

class Residue {
    var drops = Set<ResidueDrop>()
    var lastUpdated = Date.now
    var nextCreationTime = Date.now

    let image = Image("snow")
    let type: Storm.Contents

    let residueAmount: Int
    let lifetime: ClosedRange<Double>
    let creationDelay: ClosedRange<Double>?

    init(type: Storm.Contents, strength: Double) {
        self.type = type

        switch type {
        case .snow:
            residueAmount = 1
            lifetime = 1.0...2.0
        default:
            residueAmount = 3
            lifetime = 0.9...1.1
        }

        if strength == 0 || type == .none {
            creationDelay = nil
        } else {
            switch strength {
            case 1...200:
                creationDelay = 0...0.25
            case 201...400:
                creationDelay = 0...0.1
            case 401...800:
                creationDelay = 0...0.05
            default:
                creationDelay = 0...0.02
            }
        }
    }

    func update(date: Date, size: CGSize) {
        guard let creationDelay else { return }

        let currentTime = date.timeIntervalSince1970
        let delta = date.timeIntervalSince(lastUpdated)
        let divisor = size.height / size.width

        for drop in drops {
            drop.x += drop.xMovement * drop.speed * delta * divisor
            drop.y += drop.yMovement * drop.speed * delta

            drop.yMovement += delta * 2

            if drop.y > 0.5 {
                if drop.x > 0.075 && drop.x < 0.925 {
                    drop.y = 0.5
                    drop.yMovement = 0
                }
            }

            if drop.destructionTime < currentTime {
                drops.remove(drop)
            }
        }

        if nextCreationTime.timeIntervalSince1970 < currentTime {
            let dropX = Double.random(in: 0.075...0.925)

            for _ in 0..<residueAmount {
                drops.insert(ResidueDrop(
                    type: type,
                    xPosition: dropX,
                    destructionTime: currentTime + Double.random(in: lifetime)
                ))
            }

            nextCreationTime = Date.now + Double.random(in: creationDelay)
        }

        lastUpdated = date
    }
}
