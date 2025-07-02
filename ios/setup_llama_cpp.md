# Setup llama.cpp Static Library for iOS

## Files Created:

- ✅ `ios/llama.cpp/` - llama.cpp source code (cloned)
- ✅ `ios/Runner/llama_wrapper.h` - C interface header
- ✅ `ios/Runner/llama_wrapper.cpp` - C++ implementation
- ✅ `lib/services/llama_cpp_service.dart` - Dart FFI service

## Manual Xcode Configuration Steps:

### 1. Open Xcode Project

```bash
open ios/Runner.xcworkspace
```

### 2. Add Source Files to Xcode

1. Right-click on **Runner** folder in Xcode
2. Choose **"Add Files to Runner"**
3. Navigate to `ios/Runner/` and add:
   - `llama_wrapper.h`
   - `llama_wrapper.cpp`
4. Navigate to `ios/llama.cpp/` and add:
   - `llama.h`
   - `llama.cpp`
   - `ggml.h`
   - `ggml.c`
   - `ggml-alloc.h`
   - `ggml-alloc.c`
   - `ggml-backend.h`
   - `ggml-backend.c`
   - `common/common.h`
   - `common/common.cpp`

### 3. Configure Build Settings

1. Select **Runner** target
2. Go to **Build Settings** tab
3. Search for **"Header Search Paths"**
4. Add: `$(SRCROOT)/llama.cpp`
5. Search for **"C++ Language Dialect"**
6. Set to: **C++17** or later
7. Search for **"Enable Bitcode"**
8. Set to: **No**

### 4. Configure Compiler Flags

1. Search for **"Other C++ Flags"**
2. Add: `-DGGML_USE_ACCELERATE -DGGML_USE_METAL`
3. Search for **"Other Linker Flags"**
4. Add: `-framework Accelerate -framework Metal -framework MetalKit`

### 5. Update Runner-Bridging-Header.h

Add this line to `ios/Runner/Runner-Bridging-Header.h`:

```objc
#import "llama_wrapper.h"
```

### 6. Build and Test

1. Clean project: **Product** > **Clean Build Folder**
2. Build project: **Product** > **Build**
3. Fix any compilation errors
4. Run on device or simulator

## Expected Build Output:

- Static library will be linked directly into the app
- No separate .dylib file needed
- All llama.cpp functions available via FFI
- SmolLM2-360M model can be loaded and used

## Troubleshooting:

- **Compilation errors**: Check C++17 is enabled
- **Linker errors**: Verify Accelerate/Metal frameworks added
- **Runtime errors**: Check model file is in app bundle
- **FFI errors**: Verify function names match wrapper

## Next Steps After Setup:

1. Build and run the Flutter app
2. Test model loading with SmolLM2-360M
3. Verify text generation works
4. Implement RAG system integration
