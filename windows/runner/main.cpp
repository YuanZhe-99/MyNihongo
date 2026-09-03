#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

/// Purpose: Windows entry point: enforce a single instance, then create the
/// Flutter window and pump the message loop.
/// Inputs: `instance`, `prev`, `command_line`, `show_command` from Windows.
/// Returns: `EXIT_SUCCESS` on a clean exit, `EXIT_FAILURE` when the window
/// could not be created.
/// Side effects: Creates a named mutex, a console when debugging, initializes
/// COM, and creates the application window.
/// Notes: The single-instance check matches the sibling apps: a second launch
/// activates the running window instead of opening a duplicate. The window
/// class name is the one the Flutter runner registers, so the lookup cannot
/// match an unrelated window that happens to share the title. The initial size
/// is wide enough for the two-column reference layouts described in
/// `doc/en-us/adaptive-layout.md`.
int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  HANDLE mutex = ::CreateMutexW(nullptr, TRUE, L"MyNihongo_SingleInstance_A1B2C3D4");
  if (::GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND existing = ::FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"MyNihongo!!!!!");
    if (existing) {
      if (::IsIconic(existing)) {
        ::ShowWindow(existing, SW_RESTORE);
      }
      ::SetForegroundWindow(existing);
    }
    ::CloseHandle(mutex);
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1000, 720);
  if (!window.Create(L"MyNihongo!!!!!", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  ::CloseHandle(mutex);
  return EXIT_SUCCESS;
}
