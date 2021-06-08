![Screenshot 2021-06-08 at 20 39 11](https://user-images.githubusercontent.com/1690265/121239530-a80e6800-c899-11eb-9470-5884591a5408.png)

When I switched to macOS, I missed [Irfanview](https://www.irfanview.com) from Windows. I wanted a Mac app to quickly go through images in a folder by hitting left and right arrow keys, and also be able to copy the images to paste in another folder or in a document.

Thinking about it, it seemed like a pretty simple app to make and a great opportunity to dip my toes in Swift and Swift UI, so I did!

# Features

- Simple and fast (mostly thanks to Swift UI)
- Navigate images in a folder by hitting left/right arrow
- Copy image as...
	- ...an image (⌘C): Useful for pasting in a Finder window or into a Document
	- ...a file path (⌥⌘C): useful for pasting into a Terminal window
- Can show some basic information (filename, resolution, filesize) about image
- Trash (⌫) or Delete (⌥⌘⌫) files
- Multiple ways to open images:
	- Drag n drop into window
	- Drag n drop onto icon
	- File > Open... menu
	- Right click image > Open With
	- Command line: `open -a /Applications/imageviewer5.app /path/to/image.jpg`

# Download

- Download from the [Releases](https://github.com/lambdan/imageviewer5/releases) page
- Minimum macOS version is 11.0
- Because I am not a registered developer your Mac will probably scream at you when you try to open it
	- Feel free to compile/build it yourself to avoid this

# Known Issues

See the [Issues](https://github.com/lambdan/imageviewer5/issues) page. Most annoying issue right now is probably that GIF images are displayed, but not animated ([#5](https://github.com/lambdan/imageviewer5/issues/5)).
