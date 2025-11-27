# PowerShell Broadcast Chat System (Educational Purposes Only)

A PowerShell-based multi-client broadcast chat system with a central broadcast server and interactive clients.  
Designed for learning networking, sockets, PowerShell threading, and real-time message handling.

⚠️ **This project is for educational and cybersecurity lab use only.  
Do NOT use on systems you do not own or have permission to test.**

---

## 📂 Files Included

- **Broadcast-Server.ps1**
- **Client-Broadcast.ps1**

---

## 🚀 Features

### ✔ Broadcast-Server.ps1
- Accepts multiple simultaneous client connections  
- Displays real-time incoming messages from each client  
- Broadcasts messages to all clients  
- Supports **private messages**  
- Supports **kicking clients**  
- Gracefully handles disconnects  
- Uses background threads (jobs) for each client  

### ✔ Client-Broadcast.ps1
- Connects to the broadcast server  
- Sends messages  
- Receives messages in real-time  
- Clean refreshed prompt for better UX  

---

## ▶️ Usage

### 🔹 1. Start the Broadcast Server

Run this on your **server machine**:

```powershell
pwsh Broadcast-Server.ps1
```

**Expected output:**

```
Server listening on port 12345 for incoming connections...
```

---

### 🔹 2. Connect a Client

Run this on a **client machine**:

```powershell
pwsh Client-Broadcast.ps1
```

**Expected output:**

```
WIN10-CLIENT-01 has connected to server on port 12345
Enter a message (or type 'quit' to exit)
```

---

## 💬 Server Commands

| Command | Description |
|--------|-------------|
| `/list` | Show all connected clients |
| `/msg <host> <message>` | Send a private message |
| `/kick <host>` | Disconnect a client |
| `/whoami` | Show server identity |
| `/shutdown` | Disconnect all clients and stop the server |
| `quit` | Stop the server immediately |
| *(any text)* | Broadcast a message to all clients |

---

## 🧪 Example Commands

**Broadcast to everyone:**

```
Hello everyone!
```

**Private message:**

```
/msg WIN10-CLIENT-02 Hello there!
```

**Kick a client:**

```
/kick WIN10-CLIENT-01
```

**List all connected clients:**

```
/list
```

**Shutdown the server:**

```
/shutdown
```

---

## 🗂 Versioning

```
v1.0 – Initial release
v1.1 – Input cleanup & display improvements
v2.0 – Future expansion planned
```

---

## 📜 License

This project is licensed under the **MIT License**, allowing reuse and modification as long as the LICENSE file is included.

---

## ⚠️ Disclaimer

This project is intended only for:

- Lab environments  
- PowerShell learning  
- Networking/socket education  
- Red/Blue team simulations  
- Ethical cybersecurity research  

The author is **not responsible** for any misuse or illegal activity.
