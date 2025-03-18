import AVKit

final class FlashlightService {
    @discardableResult
    class func toggleFlashlight() -> Bool {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch
        else { return false }

        do {
            try device.lockForConfiguration()
            switch device.torchMode {
            case .off:
                device.torchMode = .on
            default:
                device.torchMode = .off
            }
            device.unlockForConfiguration()
        } catch {
            return false
        }
        return device.torchMode == .on
    }

    class func turnFlashlightOff() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch
        else { return }

        do {
            try device.lockForConfiguration()
            device.torchMode = .off
            device.unlockForConfiguration()
        } catch {
            return
        }
    }
}
