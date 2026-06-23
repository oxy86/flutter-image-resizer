import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private let openFileChannelName = "image_resizer/open_file"

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func application(_ sender: NSApplication, openFiles filenames: [String]) {
    for filename in filenames {
      sendOpenFile(filename)
    }
    sender.reply(toOpenOrPrint: .success)
  }

  override func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls where url.isFileURL {
      sendOpenFile(url.path)
    }
  }

  private func sendOpenFile(_ path: String) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      guard
        let controller = NSApplication.shared.mainWindow?.contentViewController
          as? FlutterViewController
      else {
        return
      }

      let channel = FlutterMethodChannel(
        name: self.openFileChannelName,
        binaryMessenger: controller.engine.binaryMessenger
      )
      channel.invokeMethod("openFile", arguments: path)
    }
  }
}
