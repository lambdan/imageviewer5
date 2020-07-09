import Cocoa
import SwiftUI

let NCName = "ImageViewer_NC"
let HandledFileExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "heif", "heic", "tif"]
let mainmenu = NSApplication.shared.mainMenu!
let subMenu = mainmenu.item(withTitle: "File")?.submenu

var WindowTitle = "imageviewer5"

var window: NSWindow!

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    
    // Right click open with
    private func application(_ sender: NSApplication, openFiles filenames: String) -> Bool {
        set_new_url(in_url: URL(fileURLWithPath: filenames).absoluteString)
        send_NC(text: "Opened via Open With")
        return true
    }
    
    // Drag and drop onto icon
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        set_new_url(in_url: URL(fileURLWithPath: filename).absoluteString)
        send_NC(text: "Opened via drag and drop onto icon")
        return true
    }
    
    // Quit when all windows closed
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    @IBAction func loadFile(_sender: NSMenuItem) {
        let panel = NSOpenPanel() // maybe make this its own function so we can use it elsewhere too
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let result = panel.runModal()
            if result == .OK {
                set_new_url(in_url: panel.url!.absoluteString)
                send_NC(text: "Image via menubar > open")
            }
        }
    }
    
    @IBAction func nextFile(_sender: NSMenuItem) {
        //print("Pressed next")
        NextPic(inc: 1)
    }
    
    @IBAction func prevFile(_sender: NSMenuItem) {
        //print("Pressed prev")
        NextPic(inc: -1)
    }
    
    @IBAction func copyFilePath(_sender: NSMenuItem) {
        // copy file path to image
        //print("copying path:", get_full_filepath())
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(get_full_filepath(), forType: .string)
    }
    
    @IBAction func copyAsFile(_sender: NSMenuItem) {
        // copy as image, used for pasting in finder or in documents etc
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects(NSArray(object: URL(string: get_URL_String())!) as! [NSPasteboardWriting]) // TODO understand this line better, i have no idea why it works
    }
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if current_url == "" { // No image loaded, spawn a blank window with the "No image loaded" text
            spawn_window()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

// The url names are confusing because you'd think we working with online files
// but its a file:// url

var current_url = ""
var current_folder = ""
var files_in_folder = [String]()
var window_spawned = false

func spawn_window() {
    // Create the SwiftUI view that provides the window contents.
    let contentView = ContentView()

    // Create the window and set the content view.
    window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
        styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
        backing: .buffered, defer: false)
    window.title = WindowTitle
    window.center()
    window.setFrameAutosaveName("Main Window")
    window.contentView = NSHostingView(rootView: contentView)
    window.makeKeyAndOrderFront(true)
    
    window_spawned = true
    
}

func set_new_url(in_url: String) {
    // TODO check if image is valid etc
    
    if window_spawned == false {
        spawn_window()
    }
    
    current_url = in_url
    window.title = get_filename()
    //window.makeKeyAndOrderFront(true)
    check_image_folder(file_url_string: in_url)
    
    // Enable menu items since we now should have a image loaded
    subMenu?.item(withTitle: "Next")?.isEnabled = true
    subMenu?.item(withTitle: "Previous")?.isEnabled = true
    subMenu?.item(withTitle: "Copy Image")?.isEnabled = true
    subMenu?.item(withTitle: "Copy Path to Image")?.isEnabled = true
 
}

func get_URL_String() -> String { /* file://path/to/picture.jpg */
    return current_url
}

func get_full_filepath() -> String { /* /path/to/picture.jpg */
    let fp = String ( ((NSURL(string: get_URL_String())?.path)!))
    return fp
}

func get_filename() -> String { /* picture.jpg */
    let fn = String( (NSURL(string: get_URL_String())?.lastPathComponent)! )
    return fn
}

func get_folder() -> String { /* /path/to/ */
    let NSs = (get_URL_String() as NSString)
    let folderpath = NSs.deletingLastPathComponent
    let fp = String ( ((NSURL(string: folderpath)?.path)!))
    return fp
}

func check_image_folder(file_url_string: String) {
    //print("Check image folder", file_url)
    let NSs = (file_url_string as NSString)
    
    //let filename = file_url_string
    let folderpath = NSs.deletingLastPathComponent
    //print(folderpath)
    
    
    if current_folder != folderpath { // Check if same folder so we dont re-do it
        current_folder = folderpath
        files_in_folder = [String]()
        // Check for files in folder
        do {
            let content = try FileManager.default.contentsOfDirectory(at: URL(string:folderpath)!, includingPropertiesForKeys: nil)
            //print("Files in folder:", content.count) // contains hidden files etc
            for file in content {
                if HandledFileExtensions.contains(file.pathExtension.lowercased()) {
                    files_in_folder.append(file.absoluteString)
                }
            }
            
            files_in_folder.sort() // TODO maybe add sorting options?
            
            //print("Files to handle:", files_in_folder.count)
        } catch {
            print ("error numerating folder")
        }
        
    }
    
}

func NextPic(inc: Int) {
    let curr = files_in_folder.firstIndex(of: current_url)
    //print("Current picture is", files_in_folder[curr!])
    var next = curr! + inc
    
    if next >= files_in_folder.count {
        next = 0 // TODO show some fancy loop indication here
    } else if next < 0 {
        next = files_in_folder.count - 1
    }
    //print("Next is", files_in_folder[next])
    let next_url = files_in_folder[next]
    set_new_url(in_url: next_url)
    send_NC(text: "Next pic")
}

func send_NC(text: String) {
    //print("NC:", text)
    NotificationCenter.default.post(name: NSNotification.Name(rawValue: NCName), object: nil)
}


