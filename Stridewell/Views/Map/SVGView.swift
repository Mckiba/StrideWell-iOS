//
//  SVGView.swift
//  Stridewell
//
//  Created by McKiba Williams on 3/5/26.
//
import Swift
import UIKit
import SwiftUI
import SVGKit

struct SVGView: UIViewRepresentable {
    let name: String // name of the svg in your bundle (e.g. "MapBackground")

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        guard let svgImage = SVGKImage(named: name) else {
            print("Failed to load SVG image named: \(name)")
            return container
        }
        
        guard let svgView = SVGKFastImageView(svgkImage: svgImage) else {
            print("Failed to create SVGKFastImageView from image: \(name)")
            return container
        }
        
        svgView.backgroundColor = .clear
        svgView.contentMode = .scaleAspectFill

        svgView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(svgView)

        NSLayoutConstraint.activate([
            svgView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            svgView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            svgView.topAnchor.constraint(equalTo: container.topAnchor),
            svgView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct MapBackground: View {
    var body: some View {
        SVGView(name: "Map") // MapBackground.svg in app bundle
            .ignoresSafeArea()
            .blur(radius: 2)
            .opacity(0.70)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        MapBackground()
    }
}

