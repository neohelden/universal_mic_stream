#import "UniversalMicStreamPlugin.h"
#if __has_include(<universal_mic_stream/universal_mic_stream-Swift.h>)
#import <universal_mic_stream/universal_mic_stream-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "universal_mic_stream-Swift.h"
#endif

@implementation UniversalMicStreamPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftUniversalMicStreamPlugin registerWithRegistrar:registrar];
}
@end
