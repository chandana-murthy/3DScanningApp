# DataFlor 3D Scanner 
##### (Developed in SwiftUI)

### Getting Started
- Download the source code from Gitlab
- Go to Project -> Target -> Signing & Capabilities -> Select your Development Team 
- Project would be ready to run once all packages are loaded

-------------------------------------------------------------------------------------------------------------------------

### Project Modes

 To Start a Scan, click on the * + * button. When there are no scans available, users also have the option of clicking the * + New point cloud * button on the scan list to start a new scan. On click, the user is immediately navigated to the scan screen
 
<p align="center" width="100%">
    <img width="33%" src="https://i.postimg.cc/L5X48sfJ/IMG-D37-AAEB5-AC4-F-1.jpg">
</p>


Point Cloud Scanning 
- Uses Metal to display a camera feed by placing a collection of points in the physical environment, according to depth information from the device’s LiDAR Scanner.
- For more information, checkout https://developer.apple.com/documentation/arkit/environmental_analysis/displaying_a_point_cloud_using_scene_depth
- Point Cloud can be exported in .ply format
- We also project a 3d mesh along with the point cloud. So the 3d model here can also be downloaded in the .obj format
- We use open3D to support normal estimation, outlier removal and surface reconstruction

-------------------------------------------------------------------------------------------------------------------------

How to:

**1. Change the color of the mesh while scanning:**

- Find the function `renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor)` 
- Find the line `colorizer.assignColor(to: meshAnchor.identifier, classification: classification, color: UIColor.red)` within the funtion.
- Change the color parameter to the desired color

**2. Increase/decrease point size on viewer:**

- Go to file `PointCloudKitHelpers`
- Within the func `pointCloudNode(from.... `, find the following lines

~~~~~~
    particles.pointSize = 10
    particles.minimumPointScreenSpaceRadius = 1.0
    particles.maximumPointScreenSpaceRadius = 8.0

~~~~~~

- Decrease the `particles.pointSize` value to have bigger points
- Increase `maximumPointScreenSpaceRadius` value, and decrease `particles.minimumPointScreenSpaceRadius` (optional) value for bigger and closer points.


**3. Increase or decrease point size on scanner:**

- Go to file `RenderingService`
- Find the property `particleSize `. Increase(bigger points) or decrease(smaller points) value 


------------------------------------------------------------------------------------------------------------------
**1. Open3D - iOS**

 Installation hint for developers: 
~~~
    - Go to Xcode 
     -> file 
     -> Add Packages... 
     -> search for Open3D-iOS or type "https://github.com/kewlbear/Open3D-iOS.git" in the search bar 
     -> Dependency rule Branch : main
     -> click on Add Package
~~~

This is a Swift package to use Open3D in iOS apps.


**2. PythonKit**

 Installation hint for developers:
 ~~~
    - Go to Xcode 
     -> file 
     -> Add Packages... 
     -> search for PythonKit or type https://github.com/pvieito/PythonKit.git in the search bar
     -> Dependency rule Branch : master
     -> click on Add Package
 ~~~

This is a Swift framework to interact with Python.

**3. Common - external Package**
    - Package folder is present in the project.
    - min version: Swift 5.3 required

**4. PointCloudRendererService**
    - Package folder is present in the project.
    - min version: Swift 5.3 required
    - Has a dependency on the Common package

Go to Targets -> DataFlor (Project name) -> Frameworks, libraries and embedded content and ensure that the 4 packages available:

    - Common
    - Open3D-iOS
    - PointCloudRendererService
    - PythonKit


If not, click on '+' icon and add the packages with the greek building symbol
If you come across the error 'Missing Package Product...', try one of the following solutions:

If it is an external package, make sure the package folder is present within the project folder. If it is present and it still doesn't work, 'remove reference' of that package from the project navigator. Add the whole folder again


    DataFlor 
    -> DataFlor target 
    -> General 
    -> Frameworks, libraries and embedded content 
    -> Click on '+' 
    -> Add Files 
    -> Select package folder and click OK




Go to File -> Packages -> Reset Package Caches.


Re-add the local packages using the "Add Packages…" menu option on the project that has the framework targets using the local package. This creats a new "Packages" group in the project, and eventually starts compiling correctly.


Sometimes the gray binary for a package is not on the list. Target -> Build Phases -> Link Binary with Libraries. Try closing xcode and reopening again. Clean and try again.

-------------------------------------------------------------------------------------------------------------------------

To change initial point Size and background visibility radius:
Go to "RenderingService"present in Frameworks -> PointCloudRendererService -> Sources -> PointCloudRendererService -> RenderingService.
particleSize refers to the size of the particle / point in pixels
rgbRadius can be adjusted to change the visibility of the background from 0(black) to 2(fully visible)

PointCloudView - We use MTKView for rendering the particles.
For more info on MetalView - https://medium.com/@warrenm - There is a 30 days of metal series on medium that has a lot of necessary information.
Detect Planes - We use ARSCNView to show the mesh and measure distances in real-time

-------------------------------------------------------------------------------------------------------------------------
