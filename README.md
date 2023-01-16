# FlightLog

[![swift](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2F453jerry%2FFlightLog%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/453jerry/FlightLog) [![platform](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2F453jerry%2FFlightLog%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/453jerry/FlightLog)  
This package implements a recorder to record runtime log to file.  

## How to use

Only need to invoke `LogRecorder.shared.record()`, Recorder will automatically log all stdout and stderr to a file. No need to modify `NSLog(_:)` or `print(_:)` in your code.

```swift
_ = LogRecorder.shared.record()
```

If you want the logs to have different levels, you can use the log enum.

```swift
Log.debug.write("This is a debug log")          // 🔍 This is a debug log
Log.info.write("This is a info log")            // 💬 This is a info log
Log.warning.write("This is a warning log")      // ⚠️ This is a warning log
Log.error.write("This is a error log")          // ❌ This is a error log
```

Log enumeration also supports ignoring logs by log level.

```swift
Log.setIngore(levels: [.debug])
```
