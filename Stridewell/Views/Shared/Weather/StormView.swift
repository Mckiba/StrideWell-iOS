//
//  StormView.swift
//  Stridewell
//
//  Canvas-based rain/snow renderer driven by TimelineView(.animation).
//  Renders all drops in a single draw pass — no per-particle SwiftUI views.
//

import SwiftUI

struct StormView: View {
    let storm: Storm

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                storm.update(date: timeline.date, size: size)

                for drop in storm.drops {
                    var contextCopy = context
                    let xPos = drop.x * size.width
                    let yPos = drop.y * size.height

                    contextCopy.opacity = drop.opacity
                    contextCopy.translateBy(x: xPos, y: yPos)
                    contextCopy.rotate(by: drop.direction + drop.rotation)
                    contextCopy.scaleBy(x: drop.xScale, y: drop.yScale)
                    contextCopy.draw(storm.image, at: .zero)
                }
            }
        }
        .ignoresSafeArea()
    }

    init(type: Storm.Contents, direction: Angle, strength: Int) {
        storm = Storm(type: type, direction: direction, strength: strength)
    }
}
