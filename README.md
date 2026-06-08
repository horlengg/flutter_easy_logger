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
const host = process.env.HOST_IP || "172.xx.xx.xx"; // Your machine's local IP
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
PORT=5000 HOST_IP=172.xx.xx.xx node server.js 

# Or just use the default IP hardcoded in server.js
npm start
```

The log viewer UI will be available at `http://<your-ip>:<your-port>` in your browser.

### Option B — Run with Docker

```bash
# Build the image
docker build -t easy-logger-server .

# Run with your local IP passed as an env variable
docker run -p 3000:3000 -e HOST_IP=172.xx.xx.xx easy-logger-server
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

Example output: `inet 172.xx.xx.xx netmask 0xffffff00`

Use that IP in both your server startup when first time call `EasyLogger()`.

### Environment Variables

|Variable |Default       |Description                  |
|---------|--------------|-----------------------------|
|`HOST_IP`|`xx.xx.xx.xx`|Your machine’s LAN IP address|
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
flutter run --dart-define=LOG_SERVER_URI=http://10.105.141.142:3000

# Production build — logging disabled (default)
flutter build apk
```

> Logs emitted before the socket connects are **queued** and automatically flushed once the connection is established.

-----

## API Reference


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
final _log = EasyLogger()
final apiResponseStr = _log.toJSONString(apiResponse);
_log.debug("API Response: <json>$apiResponseStr<json>", tag: "API");
```

Wrap JSON payloads with `<json>...</json>` tags so the log viewer renders them with syntax highlighting.

-----

### `clear()`

Emits a `clear` event to the server, wiping all logs from the viewer.

```dart
EasyLogger().clear();
```

-----

### `dispose()`

Disconnects the socket and releases all resources. Call this when logging is no longer needed (e.g. on logout or app termination).

```dart
EasyLogger().dispose();
```

-----

## Full Usage Example

```dart
import 'package:flutter_easy_logger_plus/flutter_easy_logger_plus.dart';

final _log = EasyLogger();
// Log plain messages
_log.debug("View appeared", tag: "HomeScreen");
_log.warning("Cache miss — fetching from network", tag: "Cache");
_log.error("CoreData save failed", tag: "Persistence");

// Log a JSON-encodable object
final apiResponseStr = _log.toJSONString(apiResponse);
_log.debug("API Response: <json>$apiResponseStr<json>", tag: "API");
_log.warning("API Response: <json>$apiResponseStr<json>", tag: "API");
_log.error("API Response: <json>$apiResponseStr<json>", tag: "API");

// Clear all logs from the viewer
_log.clear();

// Teardown
_log.dispose();
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

- `EasyLogger` is a singleton — access it everywhere via `EasyLogger()`(No memory leak,No initialize needed).
- Logs are **silently dropped** when `LOG_SERVER_URI` is `null` (no overhead in production builds).
- Logs emitted **while the socket is still connecting** are queued in memory and flushed automatically once the connection is ready.
- The socket uses `websocket` transport only (no polling fallback).

## Contact Me

If you have any questions, suggestions, or issues, feel free to reach out via my website:

👉 [Website](https://horleng.vercel.app)