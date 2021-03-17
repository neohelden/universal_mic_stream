#import "MicStreamPlusPlugin.h"
#if __has_include(<mic_stream_plus/mic_stream_plus-Swift.h>)
#import <mic_stream_plus/mic_stream_plus-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "mic_stream_plus-Swift.h"
#endif

@implementation MicStreamPlusPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMicStreamPlusPlugin registerWithRegistrar:registrar];
}
@end
