# Comnyang Virtual Pet

Comnyang is a fun, interactive virtual pet that lives on your screen!

## Features
- **Mouse Tracking**: Comnyang will follow your mouse cursor with its eyes.
- **Typing Reactions**: When you type, Comnyang types along with you! If you type very fast (over 50 WPM), it will get "overheated" and turn red!
- **Dragging**: You can pick Comnyang up and move it anywhere on your screen. It looks surprised when you do!
- **Peeking Mode**: If you stop interacting with your Mac for 10 seconds, Comnyang will slide to the right edge of your screen and peek at you sideways. As soon as you move your mouse or type, it'll slide right back!

## How to Build
To build the application yourself, simply run the included build script from your terminal:

```bash
./build.sh
```

This uses `swiftc` to compile the Swift files into a native macOS `.app` bundle.

## How to Run
After building, you can run the app directly from your terminal:

```bash
open Comnyang.app
```

Alternatively, you can double-click `Comnyang.app` in Finder.

## Stopping the App
Comnyang adds an icon (🐱) to your macOS menu bar. Click it and select **Quit Comnyang** to close the app.
