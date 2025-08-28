# 📦 ResourceKit

![Swift](https://img.shields.io/badge/Swift-5.7%2B-orange.svg?logo=swift)
![iOS](https://img.shields.io/badge/iOS-13%2B-blue.svg?logo=apple)
![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen?logo=swift)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)
![Version](https://img.shields.io/github/v/tag/michaelborgmann/ResourceKit?label=release)
![Tests](https://github.com/michaelborgmann/ResourceKit/actions/workflows/test.yml/badge.svg)

**ResourceKit** is a lightweight Swift package for **loading, decoding, and managing local resources** in your app.
Built for modern Swift apps, documented with DocC, and fully tested with Swift Testing.

---

## ✨ Features

* ✅ Simple resource loading from app bundles
* ✅ Built-in JSON decoding helpers
* ✅ Clear and structured error reporting (`ResourceError`)
* ✅ Fully documented using DocC
* ✅ Tested using Swift's native [`import Testing`](https://developer.apple.com/documentation/swift/testing) framework
* ✅ Designed to be extensible for additional resource types (audio, images, etc.)

---

## 📦 Installation

Add **ResourceKit** via Swift Package Manager:

```swift
.package(url: "https://github.com/michaelborgmann/ResourceKit.git", from: "0.1.0")
```

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
