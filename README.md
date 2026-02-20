# MacVMPing

**MacVMPing** is a macOS application for monitoring multiple hosts in real time using ICMP ping — inspired by [VMPing](https://github.com/R-Smith/vmping) on Windows.
## Download 👉 [Télécharger la dernière version](https://github.com/f4nr4d/MacVMPing/releases/latest)

![MacVMPing Screenshot](screenshot.png)

---

## Features

- 📡 **Monitor multiple hosts simultaneously** in a customizable grid layout
- 🟢🔴 **Visual status indicators** — green when reachable, red when unreachable
- ⏱️ **Real-time response time** displayed in milliseconds
- 📊 **Live statistics** — OK count, KO count, and packet loss percentage
- 📋 **Response log** per host with timestamps
- ➕ **Add/remove hosts** on the fly
- 🖥️ **Native macOS app** built with SwiftUI

---

## Requirements

- macOS 13 or later
- Xcode 14+ (to build from source)

---

## Installation

### Build from source

1. Clone the repository:
   ```bash
   git clone https://github.com/f4nr4d/MacVMPing.git
   ```
2. Open `MacVMPing.xcodeproj` in Xcode
3. Select your target (My Mac)
4. Press **⌘R** to build and run

---

## Usage

1. Launch **MacVMPing**
2. Click **Ajouter** to add a host (IP address or hostname)
3. Click **Démarrer tout** to start monitoring all hosts
4. Hosts turn **green** when reachable and **red** when unreachable
5. Adjust the number of columns using the **Colonnes** control

---
## Roadmap

- [ ] Save and load host lists for future use 

---

## Inspired by

- [VMPing](https://github.com/R-Smith/vmping) — the original Windows tool by R-Smith

---

## Author

**f4n** — [@f4nr4d](https://github.com/f4nr4d)

---

## License

This project is open source. Feel free to use, modify, and distribute it.
