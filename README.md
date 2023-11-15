# A `build.zig` for GLFW

I'm using this with Zig 0.11.0, targeting x86_64-windows-gnu and x86_64-linux.6.5.9...6.5.9-gnu.2.19 (native). I've ported over MacOS support from `CMakeLists.txt`, but it hasn't been tested and may or may not work.

A lot of things are hardcoded here! I assume that the GLFW source code is in `deps/glfw`, which is *really* ugly; but this works for me at the moment.
