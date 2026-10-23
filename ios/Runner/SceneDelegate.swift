import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private var privacyCover: UIView?

  func sceneWillResignActive(_ scene: UIScene) {
    guard
      let windowScene = scene as? UIWindowScene,
      let window = windowScene.windows.first(where: \.isKeyWindow) ?? windowScene.windows.first
    else {
      return
    }

    let cover = UIView(frame: window.bounds)
    cover.backgroundColor = .systemBackground
    cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(cover)
    privacyCover = cover
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    privacyCover?.removeFromSuperview()
    privacyCover = nil
  }
}
