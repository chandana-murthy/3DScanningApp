import Foundation
import UIKit
import SceneKit

class PointCloudVisualizationViewController: UIViewController {
    var pointCloud: PointCloud?
    var pointCloudVisualizationView: PointCloudVisualizationView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.pointCloudVisualizationView = PointCloudVisualizationView()
        self.view = self.pointCloudVisualizationView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let pointCloud {
            self.pointCloudVisualizationView.draw(pointCloud: pointCloud)
        }
    }
}
