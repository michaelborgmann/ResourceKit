# 📦 ResourceKit

![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg?logo=swift)
![iOS](https://img.shields.io/badge/iOS-17%2B-blue.svg?logo=apple)
![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen?logo=swift)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)
![Version](https://img.shields.io/github/v/tag/michaelborgmann/ResourceKit?label=release)

**ResourceKit** is a lightweight Swift package for **loading, decoding, and managing local resources** in your app.
Built for modern Swift apps, documented with DocC, and fully tested with Swift Testing.

---

## ✨ Features

* ✅ Simple resource loading from app bundles
* ✅ Built-in JSON decoding helpers
* ✅ Clear and structured error reporting (`ResourceError`)
* ✅ **AudioResourcePlayer**: simple, UI-safe playback of bundled audio (segments & looping)
* ✅ Fully documented using DocC
* ✅ Tested using Swift's native [`import Testing`](https://developer.apple.com/documentation/swift/testing) framework
* ✅ Designed to be extensible for additional resource types (audio, images, etc.)
* ✅ Normalized resource indexing via `ResourceIndex`

---

## 📦 Installation

Add **ResourceKit** via Swift Package Manager:

```swift
.package(url: "https://github.com/michaelborgmann/ResourceKit.git", from: "0.3.0")
````

Then import it into your code:

```swift
import ResourceKit
```

---

## 🚀 Usage

### 🔹 Load a JSON file

```swift
import ResourceKit

struct Config: Decodable {
    let apiKey: String
}

do {
    let config: Config = try JSON.load(name: "AppConfig")
    print(config.apiKey)
} catch {
    print("Failed to load AppConfig.json:", error)
}
```

---

### 🔹 Decode JSON from `Data`

```swift
let data = #"{"id": "abc123", "name": "Michael"}"#.data(using: .utf8)!

struct User: Decodable {
    let id: String
    let name: String
}

do {
    let user: User = try JSON.decode(data: data)
    print(user.name)
} catch {
    print("Decoding failed:", error)
}
```

---

### 🔹 Load raw resource data

```swift
let url = try Resource.url(name: "filename", ext: "json")
let data = try Resource.data(for: url)
```

---

### 🔊 Play a bundled audio file (AudioResourcePlayer)

`AudioResourcePlayer` is a tiny, main-actor–isolated helper for playing **local** audio files (e.g., sounds bundled in your app or test target).
It supports whole-file playback as well as **segment** playback with optional looping.

```swift
import ResourceKit

let player = AudioResourcePlayer()

// Load a file from your bundle (e.g., Tests/Resources/beep.mp3)
try player.load(named: "beep", ext: "mp3", in: .module)

// Whole file
try player.play()

// Or a time slice with looping: play [0.0, 0.25) three times total
try player.play(fromSeconds: 0.0, toSeconds: 0.25, loops: .times(2))
```

#### 🔹 Observe playback state in SwiftUI

You can use `onPlaybackStateChange` to bind playback state to your SwiftUI views:

```
@MainActor
@Observable
final class AudioPlayerViewModel {
    
    let player = AudioResourcePlayer()
    var isPlaying: Bool = false
    
    init(audioFile: String) {
        try? player.load(named: audioFile, ext: "mp3")
        
        player.onPlaybackStateChange = { [weak self] playing in
            self?.isPlaying = playing
        }
    }
    
    func toggle() {
        player.isPlaying ? player.stop() : try? player.play()
    }
}

struct AudioPlayerView: View {
    
    @State private var viewModel: AudioPlayerViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.isPlaying ? "Playing…" : "Stopped")
            Button(viewModel.isPlaying ? "Stop" : "Play") {
                viewModel.toggle()
            }
        }
    }
}
```

> Notes:
>
> * The API is `@MainActor`, making it safe for UI use.
> * Segment playback is drift-free via anchored timers.
> * This is for **local** files; streaming is out of scope.

#### 🔹 Observe playback finished

Use `onPlaybackFinished` to run a callback when a whole-file playback ends naturally:

```swift
player.onPlaybackFinished = {
    print("Audio finished playing — move to next track or update UI")
}
````

> Note:
>
> * Triggered only when the audio finishes naturally (whole-file playback).
> * Not called for segment playback; timers handle segment loops separately.

---

### 🔹 ResourceIndex (lightweight resource index)

A small JSON index file that lists the resources in a collection, designed for previews and lists.

#### Example `index.json`

```json
{
  "schema": 1,
  "title": "Example Content Set",
  "setId": "example-set",
  "version": "0.1.0",
  "items": [
    {
      "id": "item-001",
      "order": 1,
      "payload": {
        "title": "Getting Started",
        "difficulty": 1
      },
      "target": { "kind": "resource", "ref": "resources/item-001" }
    }
  ]
}
```

#### Load the index

```swift
let index = try ResourceIndex.load(fileName: "index")
```

#### Using custom payloads

`payload` is stored as `JSONValue` so each project can define its own lightweight preview metadata.

**Define a payload model:**

```swift
struct ExamplePayload: Codable {
    let title: String
    let difficulty: Int?
}
```

**Decode payloads:**

```swift
let payload = try item.decodePayload(ExamplePayload.self)
```

---

## 🧩 Requirements

* **Swift:** 5.9+
* **iOS:** 17+
* **Package Manager:** Swift Package Manager (SPM)

---

## 👤 About

Created by [Michael Borgmann](https://github.com/michaelborgmann)
Part of the **Vicentina Studios** toolchain.

---

📄 **License**

MIT License — see [LICENSE](./LICENSE) for details.
