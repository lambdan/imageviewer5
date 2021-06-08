import Cocoa
import SwiftUI

// Variables
var DefaultWindowTitle = "imageviewer5" // Shown in the titlebar of the window when no image is loaded
var window_spawned = false // Is the window created?

var current_url = "" // file:// URL to the current image we are showing
var current_image_width = 0 // width of current image in pixels
var current_image_height = 0 // height -"-

var current_folder = "" // file:// URL to the current folder we are showing images from
var files_in_folder = [String]() // This array will hold images we can display

var currentImageIndex = 0 // Which image in the array we are showing
var totalFilesInFolder = 0 // How many images in the folder that we can show

// Infobar vars
var InfoBar_Name = "(Filename goes here)"
var InfoBar_Format = "(Resolution etc goes here)"
var InfoBar_FileSize = "(Filesize goes here)"
var InfoBar_Misc = "(Misc stuff goes here)"


let UD = UserDefaults.standard

//
// Main code...
//

let NCName = "ImageViewer_NC"
let mainmenu = NSApplication.shared.mainMenu!
let subMenu = mainmenu.item(withTitle: "File")?.submenu
let InfoBar_MenuItem = mainmenu.item(withTitle: "Window")?.submenu?.item(withTitle: "Info Bar")
let defaultWindowTitle = "imageviewer5"
var window: NSWindow!

let HandledFileExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "heif", "heic", "tif", "webp", "tiff"] // File extensions we can handle

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
    
    @IBAction func openPrefs(_sender: NSMenuItem) {
        OpenPrefsWindow()
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
    
    @IBAction func deleteFile(_sender: NSMenuItem) {
        let fileManager = FileManager()
        do {
            try fileManager.removeItem(atPath: get_full_filepath())
            
            if files_in_folder.count > 1 { // this wasnt the last image so just move to the next one
                current_folder = "" // need to do this to refresh the folder check.. TODO maybe just remove the deleted file from the array instead?
                NextPic(inc: 1)
            } else { // no files left in folder
                reset_everything()
            }
        }
        catch {
            //TODO probably need to do more here
            print("Error deleting file")
        }
    }
    
    @IBAction func trashFile(_sender: NSMenuItem) {
        let fileManager = FileManager()
        do {
            try fileManager.trashItem(at: URL(string: get_URL_String())!, resultingItemURL: nil)
            //TODO catch the resultingItemURL to add Undo functionality
            
            if files_in_folder.count > 1 { // this wasnt the last image so just move to the next one
                current_folder = "" // need to do this to refresh the folder check.. TODO maybe just remove the deleted file from the array instead?
                NextPic(inc: 1)
            } else { // no files left in folder
                reset_everything()
            }
        }
        catch {
            //TODO probably need to do more here
            print("Error trashing file")
        }
    }
    
    @IBAction func toggleInfoBar(_sender: NSMenuItem) {
        ToggleInfoBar()
    }
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        loadUserDefaults()
        
        if UD.string(forKey: "Last Session Image") != "NULL" {
            // Make sure file exists
            let filePath = URL(string: UD.string(forKey: "Last Session Image")!)!.path
            let fileManager = FileManager.default
            
            if fileManager.fileExists(atPath: filePath) { // It exists
                set_new_url(in_url: UD.string(forKey: "Last Session Image")!)
                send_NC(text: "Loaded last session")
            } else {
                print("Image from last session was not found!")
            }
        }
        
        if current_url == "" { // No image loaded, spawn a blank window with the "No image loaded" text
            spawn_window()
        }
        
        if UD.bool(forKey: "Show Info Bar") == true {
            InfoBar_MenuItem?.state = .on
        } else {
            InfoBar_MenuItem?.state = .off
        }
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

func spawn_window() {
    // Create the SwiftUI view that provides the window contents.
    let contentView = ContentView()

    // Create the window and set the content view.
    window = NSWindow(
        contentRect: NSRect(),
        styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
        backing: .buffered, defer: false)
    
    //contentView.frame(minWidth: CGFloat(current_image_width), minHeight:CGFloat(current_image_height))
    window.title = DefaultWindowTitle
    window.center()
    window.setFrameAutosaveName("Main Window")
    window.contentView = NSHostingView(rootView: contentView)
    window.makeKeyAndOrderFront(true)
        
    window_spawned = true
    
}

func set_new_url(in_url: String) { // This is the main thing. It gets called whenever we change picture.
    // TODO check if image is valid etc
    
    if window_spawned == false {
        spawn_window()
    }
    //window.makeKeyAndOrderFront(true)
    
    // Set all variables etc
    current_url = in_url
    check_image_folder(file_url_string: in_url)
    currentImageIndex = files_in_folder.firstIndex(of: current_url)!
    totalFilesInFolder = files_in_folder.count
    
    // Get image resolution, https://stackoverflow.com/a/13228091
    let img = NSImageRep(contentsOf: URL(string: current_url)!)
    current_image_width = Int( img!.pixelsWide )
    current_image_height = Int( img!.pixelsHigh )
    
    // Set up the window title
    var WindowTitle = ""
    
    if UD.bool(forKey: "Show Index In Title") == true { // First the index at the start...
        let TitlebarImageIndex = currentImageIndex + 1 // because 0/x looks weird
        WindowTitle = WindowTitle + "[" + String(TitlebarImageIndex) + "/" + String(totalFilesInFolder) + "] "
    }
    
    if UD.bool(forKey: "Show Name In Title") == true {
        WindowTitle = WindowTitle + get_filename() // ...filename in the middle...
    }
    
    if UD.bool(forKey: "Show Resolution In Title") == true { // And then the resolution at the end
        WindowTitle = WindowTitle + " (" + String(current_image_width) + "x" + String(current_image_height) + ")"
    }
    
    if WindowTitle == "" {
        WindowTitle = DefaultWindowTitle
    }
    
    window.title = WindowTitle
    
    // Generate text for the infobar
    InfoBar_Name = get_filename()
    InfoBar_Format = String(current_image_width) + "x" + String(current_image_height) // TODO show color depth etc too
    let TitlebarImageIndex = currentImageIndex + 1 // because 0/x looks weird
    InfoBar_Misc = String(TitlebarImageIndex) + "/" + String(totalFilesInFolder)
    InfoBar_FileSize = get_human_size(bytes: get_file_size(urlString: current_url))
    
    
    // Enable menu items since we now should have a image loaded
    subMenu?.item(withTitle: "Next")?.isEnabled = true
    subMenu?.item(withTitle: "Previous")?.isEnabled = true
    subMenu?.item(withTitle: "Copy Image")?.isEnabled = true
    subMenu?.item(withTitle: "Copy Path to Image")?.isEnabled = true
    subMenu?.item(withTitle: "Delete")?.isEnabled = true // TODO enable this only if file exists
    subMenu?.item(withTitle: "Trash")?.isEnabled = true
    
    // Update last session image
    if UD.bool(forKey: "Remember Last Session Image") == true {
        UD.setValue(current_url, forKey: "Last Session Image")
    } else {
        UD.setValue("NULL", forKey: "Last Session Image")
    }
 
}

func get_URL_String() -> String { /* file://path/to/picture.jpg */
    return current_url
}

func get_IMG_Size(axis: String) -> Int {
    if axis == "Width" {
        return current_image_width
    }
    if axis == "Height" {
        return current_image_height
    }
    return 0
}

func get_full_filepath() -> String { /* /path/to/picture.jpg */
    let fp = String ( ((NSURL(string: get_URL_String())?.path)!))
    return fp
}

func get_filename() -> String { /* picture.jpg */
    let fn = String( (NSURL(string: get_URL_String())?.lastPathComponent)! )
    return fn
}

func get_file_size(urlString: String) -> Int {
    let local_url = URL(string: urlString)
    do {
        let resources = try local_url!.resourceValues(forKeys:[.fileSizeKey])
        let fileSize = resources.fileSize!
        return fileSize
    } catch {
        return 0
    }
}

func get_human_size(bytes: Int) -> String {
    // https://stackoverflow.com/a/42723243
    // get_human_size(bytes: get_file_size(urlString: current_url))
    let bcf = ByteCountFormatter()
    //bcf.allowedUnits = [.useMB, .useKB] // optional: restricts the units to MB and KB only
    bcf.countStyle = .file
    bcf.isAdaptive = true
    let string = bcf.string(fromByteCount: Int64(bytes))
    return string
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
    //print("Current picture is", files_in_folder[curr!])
    var next = currentImageIndex + inc
    
    if next >= totalFilesInFolder {
        // we've gone through all pictures in the folder... lets go to the first one!
        next = 0 // TODO show some fancy loop indication here
    } else if next < 0 {
        // we've gone through all pictures in the folder, but backwards... lets go to the last one!
        next = totalFilesInFolder - 1
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

func reset_everything() {
    window.title = defaultWindowTitle

    current_url = "" // file:// URL to the current image we are showing
    current_image_width = 0 // width of current image in pixels
    current_image_height = 0 // height -"-

    current_folder = "" // file:// URL to the current folder we are showing images from
    files_in_folder = [String]() // This array will hold images we can display

    currentImageIndex = 0 // Which image in the array we are showing
    totalFilesInFolder = 0 // How many images in the folder that we can show
    
    // Disable menu items again
    subMenu?.item(withTitle: "Next")?.isEnabled = false
    subMenu?.item(withTitle: "Previous")?.isEnabled = false
    subMenu?.item(withTitle: "Copy Image")?.isEnabled = false
    subMenu?.item(withTitle: "Copy Path to Image")?.isEnabled = false
    subMenu?.item(withTitle: "Delete")?.isEnabled = false
    subMenu?.item(withTitle: "Trash")?.isEnabled = false
    
    // Tell window to refresh
    send_NC(text: "Reset")
}

func OpenPrefsWindow() {
        var windowRef: NSWindow
        windowRef = NSWindow(
                contentRect: NSRect(x: 100, y: 100, width: 100, height: 100),
                styleMask: [.titled, .closable],
                backing: .buffered, defer: false)
        windowRef.title = "Preferences"
        windowRef.center()
        windowRef.contentView = NSHostingView(rootView: PrefsView())
        windowRef.makeKeyAndOrderFront(windowRef)
        NSApp.activate(ignoringOtherApps: true)
        windowRef.isReleasedWhenClosed = false
}

func isKeyPresentInUserDefaults(key: String) -> Bool { // https://smartcodezone.com/check-if-key-is-exists-in-userdefaults-in-swift/
       return UD.object(forKey: key) != nil
}

func loadUserDefaults() {
    if isKeyPresentInUserDefaults(key: "Show Index In Title") == false {
        UD.set(false, forKey: "Show Index In Title")
    }
    
    if isKeyPresentInUserDefaults(key: "Show Name In Title") == false {
        UD.set(true, forKey: "Show Name In Title")
    }
    
    if isKeyPresentInUserDefaults(key: "Show Resolution In Title") == false {
        UD.set(false, forKey: "Show Resolution In Title")
    }
    
    if isKeyPresentInUserDefaults(key: "Show Info Bar") == false {
        UD.set(false, forKey: "Show Info Bar")
    }

    // Last session vars
    if isKeyPresentInUserDefaults(key: "Remember Last Session Image") == false {
        UD.set(true, forKey: "Remember Last Session Image")
    }
    if isKeyPresentInUserDefaults(key: "Last Session Image") == false {
        UD.set("NULL", forKey: "Last Session Image")
    }
}

func SettingsUpdated() {
    print("Settings updated")
    if current_url != "" {
        set_new_url(in_url: current_url)
    }
}

func ToggleInfoBar() {
    var local_InfoBarState = UD.bool(forKey: "Show Info Bar")
    
    if local_InfoBarState == false {
        // Enabled infobar
        local_InfoBarState = true
        InfoBar_MenuItem?.state = .on
    } else {
        local_InfoBarState = false
        InfoBar_MenuItem?.state = .off
    }
    
    UD.set(local_InfoBarState, forKey: "Show Info Bar")
    send_NC(text: "info bar toggled")
}
