# flutter_easy_logger_plus

A lightweight Flutter logging plugin powered by Socket.IO that streams logs in real time to a remote log viewer server.

-----

<br>
<br>

![log-dashboard.png](https://github.com/horlengg/easy-logger-server/raw/main/log-dashboard.png)

![json-viewer.png](https://github.com/horlengg/easy-logger-server/raw/main/json-viewer.png)

<br>
<br>

## Requirements

- Flutter 3.0+
- [`socket_io_client`](https://pub.dev/packages/socket_io_client)
- [easy-logger-server](https://github.com/horlengg/easy-logger-server) running on the same Wi-Fi network (Node.js 18+, or Docker)

-----

## Server Setup

`flutter_easy_logger` requires the [easy-logger-server](https://github.com/horlengg/easy-logger-server) running on the same local network as your device.

> **Source:** [github.com/horlengg/easy-logger-server](https://github.com/horlengg/easy-logger-server)

The server is a Node.js + Express + Socket.IO app. It binds to your machine’s local IP and port so your Flutter device (on the same Wi-Fi) can reach it.

```js
const PORT = process.env.PORT || 3000;
const host = process.env.HOST_IP || "172.20.10.12"; // Your machine's local IP
const uri = `http://${host}:${PORT}`;
```

### Option A — Run directly with Node

```bash
# Clone the repo
git clone https://github.com/horlengg/easy-logger-server.git
cd easy-logger-server

# Install dependencies (Express 5, Socket.IO 4)
npm install

# Start with your machine's local IP
HOST_IP=172.20.10.12 node server.js

# Or just use the default IP hardcoded in server.js
npm start
```

The log viewer UI will be available at `http://<your-ip>:3000` in your browser.

### Option B — Run with Docker

```bash
# Build the image
docker build -t easy-logger-server .

# Run with your local IP passed as an env variable
docker run -p 3000:3000 -e HOST_IP=172.20.10.12 easy-logger-server
```

The Dockerfile uses `node:18-alpine` and exposes port `3000`.

### Finding your local IP

Your device and machine must be on the **same Wi-Fi network**.

```bash
# macOS — look for en0 inet address
ifconfig en0 | grep "inet "

# Windows
ipconfig
```

Example output: `inet 172.20.10.12 netmask 0xffffff00`

Use that IP in both your server startup and in `EasyLogger.instance.initialize(...)`.

### Environment Variables

|Variable |Default       |Description                  |
|---------|--------------|-----------------------------|
|`HOST_IP`|`172.20.10.12`|Your machine’s LAN IP address|
|`PORT`   |`3000`        |Port the server listens on   |

-----

## Installation

Add `flutter_easy_logger_plus` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_easy_logger_plus: ^<latest-version>
```

Then run:

```bash
flutter pub get
```

Import it in your Dart file:

```dart
import 'package:flutter_easy_logger_plus/flutter_easy_logger_plus.dart';
```

-----

## Setup

### 1. Enable logging with a compile-time flag

`flutter_easy_logger_plus` uses `--dart-define` to gate logging at compile time, so it produces **zero overhead in production**.

```bash
# Development — logging enabled
flutter run --dart-define=ENABLE_LOG=true

# Production build — logging disabled (default)
flutter build apk
```

### 2. Initialize in `main()`

Initialize `EasyLogger` once at app startup, before `runApp`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_easy_logger/flutter_easy_logger_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  EasyLogger.instance.initialize("http://172.20.10.12:3000"); // Your local IP 
  runApp(const MyApp());
}
```

> Logs emitted before the socket connects are **queued** and automatically flushed once the connection is established.

-----

## API Reference

### `initialize(String url)`

Connects to the log server. Must be called before any logging.

```dart
EasyLogger.instance.initialize("http://<server-ip>:<port>");
```

|Parameter|Type    |Description         |
|---------|--------|--------------------|
|`url`    |`String`|WebSocket server URL|

Logging is controlled by the `ENABLE_LOG` compile-time flag. Pass it via `--dart-define=ENABLE_LOG=true` at run time.

-----

### Logging Methods

All three methods accept an optional `tag` to group related logs. Defaults to `"DEFAULT"` if omitted.

#### `debug(String message, {String? tag})`

```dart
EasyLogger.instance.debug("View appeared", tag: "HomeScreen");
```

#### `warning(String message, {String? tag})`

```dart
EasyLogger.instance.warning("Cache miss — fetching from network", tag: "Cache");
```

#### `error(String message, {String? tag})`

```dart
EasyLogger.instance.error("DB save failed", tag: "Persistence");
```

-----

### `toJSONString(dynamic object)`

Serializes any JSON-encodable object to a pretty-printed JSON string. Useful for logging API responses or model data inline.

```dart
final apiResponseStr = EasyLogger.instance.toJSONString(apiResponse);
EasyLogger.instance.debug("API Response: <json>$apiResponseStr<json>", tag: "API");
```

Wrap JSON payloads with `<json>...</json>` tags so the log viewer renders them with syntax highlighting.

-----

### `clear()`

Emits a `clear` event to the server, wiping all logs from the viewer.

```dart
EasyLogger.instance.clear();
```

-----

### `dispose()`

Disconnects the socket and releases all resources. Call this when logging is no longer needed (e.g. on logout or app termination).

```dart
EasyLogger.instance.dispose();
```

-----

## Full Usage Example

```dart
import 'package:flutter_easy_logger_plus/flutter_easy_logger_plus.dart';

// Log plain messages
EasyLogger.instance.debug("View appeared", tag: "HomeScreen");
EasyLogger.instance.warning("Cache miss — fetching from network", tag: "Cache");
EasyLogger.instance.error("CoreData save failed", tag: "Persistence");

// Log a JSON-encodable object
final apiResponseStr = EasyLogger.instance.toJSONString(apiResponse);
EasyLogger.instance.debug("API Response: <json>$apiResponseStr<json>", tag: "API");
EasyLogger.instance.warning("API Response: <json>$apiResponseStr<json>", tag: "API");
EasyLogger.instance.error("API Response: <json>$apiResponseStr<json>", tag: "API");

// Clear all logs from the viewer
EasyLogger.instance.clear();

// Teardown
EasyLogger.instance.dispose();
```

-----

## Log Types

|Type     |Raw Value|Use case                         |
|---------|---------|---------------------------------|
|`debug`  |`0`      |General info, state changes      |
|`warning`|`1`      |Non-critical issues, deprecations|
|`error`  |`2`      |Failures, exceptions             |

-----

## Socket Events

`flutter_easy_logger_plus` emits the following Socket.IO events to the server:

|Event      |Payload                 |Description                 |
|-----------|------------------------|----------------------------|
|`send-logs`|`{ message, tag, type }`|Sends a log entry           |
|`clear`    |*(none)*                |Signals server to clear logs|

-----

## Notes

- `EasyLogger` is a singleton — access it everywhere via `EasyLogger.instance`.
- Logs are **silently dropped** when `ENABLE_LOG` is `false` (no overhead in production builds).
- Logs emitted **while the socket is still connecting** are queued in memory and flushed automatically once the connection is ready.
- The socket uses `websocket` transport only (no polling fallback).

## Contact Me

If you have any questions, suggestions, or issues, feel free to reach out via my website:

👉 [Website](https://horleng.vercel.app)