//
//  ARScnViewRepresentable.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 26.01.23.
//

import ARKit
import SwiftUI

struct ARViewRepresentable: UIViewRepresentable {
    var arScnViewModel: ARSCNViewModel
    let session: ARSession

    func makeUIView(context: Context) -> some UIView {
        let arView = ARSCNView(frame: .zero)
        arScnViewModel.setARView(arView, session: session)
        return arView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) { }
}
