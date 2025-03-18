import Foundation
import SwiftUI
import SceneKit

struct PointCloudVisualizationHostView: UIViewControllerRepresentable {
    var pointCloud: PointCloud

    func makeUIViewController(context: UIViewControllerRepresentableContext<PointCloudVisualizationHostView>) -> PointCloudVisualizationViewController {

        let viewController = PointCloudVisualizationViewController()
        viewController.pointCloud = self.pointCloud
        return viewController
    }

    func updateUIViewController(_ uiViewController: PointCloudVisualizationViewController, context: UIViewControllerRepresentableContext<PointCloudVisualizationHostView>) {
    }
}
