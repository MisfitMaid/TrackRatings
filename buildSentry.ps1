&{Import-Module "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"; Enter-VsDevShell bbc3b806 -StartInPath "."}

cd external/sentry

cmake -B build -D SENTRY_BACKEND=none
cmake --build build --config RelWithDebInfo
cmake --install build --prefix install --config RelWithDebInfo

cd ../..