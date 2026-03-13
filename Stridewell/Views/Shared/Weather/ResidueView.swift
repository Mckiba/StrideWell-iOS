//
//  ResidueView.swift
//  Stridewell
//
//  Canvas renderer for particles that settle after rain or snow.
//  Placed as a bottom-anchored overlay above the tab bar.
//

import SwiftUI

struct ResidueView: View {
    let residue: Residue

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                residue.update(date: timeline.date, size: size)

                for drop in residue.drops {
                    var contextCopy = context
                    let xPos = drop.x * size.width
                    let yPos = drop.y * size.height

                    contextCopy.opacity = drop.opacity
                    contextCopy.translateBy(x: xPos, y: yPos)
                    contextCopy.scaleBy(x: drop.scale, y: drop.scale)
                    contextCopy.draw(residue.image, at: .zero)
                }
            }
        }
    }

    init(type: Storm.Contents, strength: Double) {
        residue = Residue(type: type, strength: strength)
    }
}
