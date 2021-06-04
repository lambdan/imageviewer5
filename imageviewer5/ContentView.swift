import SwiftUI
import AppKit
import Combine
import Foundation

//var screen_width = NSScreen.main?.frame.width // Current display max width
//var screen_height = NSScreen.main?.frame.height // and height


struct ContentView: View, DropDelegate {
    
    // TODO should also implement validateDrop function to validate file extension
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [(kUTTypeFileURL as String)]).first else { return false }
        itemProvider.loadItem(forTypeIdentifier: (kUTTypeFileURL as String), options: nil) { (data,error) in
            let url = URL(dataRepresentation: data as! Data, relativeTo: nil)!
            if HandledFileExtensions.contains(url.pathExtension) {
                DispatchQueue.main.async {
                    set_new_url(in_url: url.absoluteString)
                    send_NC(text: "Image drag n dropped")
                }
            }
        }
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // TODO show that frame around like other apps
        //self.bgcolor = Color(.systemOrange)
    }
    
    func dropExited(info: DropInfo) {
        //self.bgcolor = Color(.systemBlue)
    }
    
    @State var url_string = get_URL_String()
    @State var imgW = CGFloat(get_IMG_Size(axis: "Width"))
    @State var imgH = CGFloat(get_IMG_Size(axis: "Height"))
    //@State var bgcolor = Color(.systemBlue)
    
    
    let pub = NotificationCenter.default.publisher(for: NSNotification.Name(NCName))
    
    var body: some View {
        VStack {
            if url_string == "" {
                Text("No image loaded").fixedSize().padding(50)
                    
                
            } else {
                Image(nsImage: NSImage(contentsOf: URL(string:url_string)!)!).resizable().aspectRatio(contentMode: .fit)
            }
            
            
            }
            .onReceive(pub) {_ in
                // This gets run when notification is sent
                self.url_string = get_URL_String()
                self.imgW = CGFloat(get_IMG_Size(axis: "Width"))
                self.imgH = CGFloat(get_IMG_Size(axis: "Height"))
            
        }
        
        
        .frame(minWidth: 400, idealWidth: imgW, maxWidth: NSScreen.main?.frame.height, minHeight: 300, idealHeight: imgH, maxHeight: NSScreen.main?.frame.height)
        //.background(Rectangle().fill(bgcolor))
        .onDrop(of: [(kUTTypeFileURL as String)], delegate: self)
    }
}

