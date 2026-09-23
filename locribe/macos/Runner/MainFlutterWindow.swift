import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let minWindowSize = NSSize(width: 1100, height: 760)
    let startingSize = NSSize(
      width: max(self.frame.width, minWindowSize.width),
      height: max(self.frame.height, minWindowSize.height)
    )
    let startingRect = NSRect(
      x: self.frame.origin.x,
      y: self.frame.origin.y,
      width: startingSize.width,
      height: startingSize.height
    )

    self.minSize = minWindowSize
    self.contentViewController = flutterViewController
    self.setFrame(startingRect, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
