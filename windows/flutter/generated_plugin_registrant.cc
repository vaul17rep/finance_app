//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <file_selector_windows/file_selector_windows.h>
#include <image_compress_plus_windows/image_compress_plus_windows_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FileSelectorWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FileSelectorWindows"));
  ImageCompressPlusWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ImageCompressPlusWindowsPlugin"));
}
