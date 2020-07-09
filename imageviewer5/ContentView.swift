import SwiftUI
import AppKit
import Combine
import Foundation

var screen_width = NSScreen.main?.frame.width
var screen_height = NSScreen.main?.frame.height


struct ContentView: View {
    @State var url_string = get_URL_String()
    //@State var window_width = (screen_width)! / 2 // get macs screen resolution
    //@State var window_height = (screen_height)! / 2
    
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
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

