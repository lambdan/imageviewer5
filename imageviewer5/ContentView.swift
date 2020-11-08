import SwiftUI
import AppKit
import Combine
import Foundation

var screen_width = NSScreen.main?.frame.width // Current display max width
var screen_height = NSScreen.main?.frame.height // and height

struct ContentView: View {
    @State var url_string = get_URL_String()
    @State var imgW = CGFloat(get_IMG_Size(axis: "Width"))
    @State var imgH = CGFloat(get_IMG_Size(axis: "Height"))
    
    
    let pub = NotificationCenter.default.publisher(for: NSNotification.Name(NCName))
    
    var body: some View {
        VStack {
            if url_string == "" {
                Text("No image loaded").fixedSize().padding(50)
                
            } else {
                Image(nsImage: NSImage(contentsOf: URL(string:url_string)!)!).resizable().aspectRatio(contentMode: .fit)
            }
            
            }.onReceive(pub) {_ in
            // This gets run when notification is sent
            self.url_string = get_URL_String()
            self.imgW = CGFloat(get_IMG_Size(axis: "Width"))
            self.imgH = CGFloat(get_IMG_Size(axis: "Height"))
            
        }
        .frame(minWidth: 400, idealWidth: imgW, maxWidth: NSScreen.main?.frame.height, minHeight: 300, idealHeight: imgH, maxHeight: NSScreen.main?.frame.height)
    }
}
/*
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}*/

