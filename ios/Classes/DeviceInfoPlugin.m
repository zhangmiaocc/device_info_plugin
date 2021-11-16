#import "DeviceInfoPlugin.h"
#import <sys/utsname.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AdSupport/AdSupport.h>
#import <CommonCrypto/CommonDigest.h>
#import <SAMKeychain/SAMKeychain.h>


static NSString *_first_install_app = @"";

@implementation DeviceInfoPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"device_info_plugin"
            binaryMessenger:[registrar messenger]];
  DeviceInfoPlugin* instance = [[DeviceInfoPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getIosDeviceInfo" isEqualToString:call.method]) {
    UIDevice* device = [UIDevice currentDevice];
    struct utsname un;
    uname(&un);
    CGFloat scale = [UIScreen mainScreen].scale;
    int screenX = [[UIScreen mainScreen] bounds].size.width * scale;
    int screenY = [[UIScreen mainScreen] bounds].size.height * scale;

    
    
    result(@{
      @"bundleId"           : SafeString(NSBundle.mainBundle.bundleIdentifier),
      @"appName"            : SafeString([NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleDisplayName"]),
      @"uuid"               : [DeviceInfoPlugin deviceUUID],                              // 设备的唯一标识符.第一次获取之后保存到钥匙链
      @"adid"               : ASIdentifierManager.sharedManager.advertisingIdentifier.UUIDString, //广告标识符
      @"appversion"         : [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleShortVersionString"],
      @"screenWidthPX"       : [NSString stringWithFormat:@"%d",screenX],
      @"screenHeightPX"       : [NSString stringWithFormat:@"%d",screenY],
      @"runtimesize"        : [NSString stringWithFormat:@"%.2fG", [DeviceInfoPlugin physicalMemory] / 1024.f / 1024.f / 1024.f],
      @"realRegion"        : [NSLocale.currentLocale objectForKey:NSLocaleCountryCode],
      @"devieceUserName"    : [device name],                      // 获取用户关于本机中的名称,比如 Minger's iPhone
      @"systemName"         : [device systemName],                // 当前系统名称,比如 iOS
      @"systemVersion"      : [device systemVersion],             // 当前系统版本,比如 11.4
      @"deviceModelName"    : [DeviceInfoPlugin deviceModelName], // 设备型号名称,例如 iPhone 8 Plus
      @"localizedModel"     : [device localizedModel],
      @"identifierForVendor" : [[device identifierForVendor] UUIDString],
      @"isPhysicalDevice"   : [self isDevicePhysical],
      @"deviceRegion"       : [NSLocale.currentLocale objectForKey:NSLocaleCountryCode],
      @"utsname" : @{
        @"sysname" : @(un.sysname),
        @"nodename" : @(un.nodename),
        @"release" : @(un.release),
        @"version" : @(un.version),
        @"machine" : @(un.machine),
      },
      @"isFirstInstall" : @([DeviceInfoPlugin isFirstInstall]),
    });
  } else {
    result(FlutterMethodNotImplemented);
  }
}

+ (long long)physicalMemory {
    return NSProcessInfo.processInfo.physicalMemory;
}


NS_INLINE NSString * SafeString(NSString *str) {
    
    if ([str isKindOfClass:[NSString class]]) {
        
        return str.length ? str : @"";
        
    } else {
        
        return @"";
    }
}

+ (NSString *)deviceUUID {
    static NSString *code;
    NSString *app_name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    NSString *account = [NSString stringWithFormat:@"%@_User_DeviceCode",app_name];
    static dispatch_once_t readUUIDOnceToken;
    dispatch_once(&readUUIDOnceToken, ^{
            // 如果Keychain里面有code,则直接获取并存储起来
        NSString *tempStr = [SAMKeychain passwordForService:@"User_DeviceCode" account:account];
        if (tempStr) {
            _first_install_app = @"false";
            code = tempStr;
            [NSUserDefaults.standardUserDefaults setValue:code forKey:@"User_DeviceCode"];
        } else {  // 如果没有，说明是第一次安装应用

            _first_install_app = @"true";
            code = [DeviceInfoPlugin md532BitLower:[[NSProcessInfo processInfo] globallyUniqueString]];
            [NSUserDefaults.standardUserDefaults setValue:code forKey:@"User_DeviceCode"];
            
            // 存储keychain
            [SAMKeychain setPassword:code forService:@"User_DeviceCode" account:account];
        }
    });

    return code;
}

// 是否是第一次安装
+ (BOOL)isFirstInstall {
    if (_first_install_app.length > 0) {
        return [_first_install_app isEqualToString:@"true"];
    }
    
    [DeviceInfoPlugin deviceUUID];
    return [_first_install_app isEqualToString:@"true"];;
}


+ (NSString*)md532BitLower:(NSString *)string {

    const char    *cStr = [string UTF8String];
    unsigned char  result[16];
    CC_MD5(cStr, (unsigned int)strlen(cStr), result);

    return [[NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
             result[0], result[1], result[2], result[3],
             result[4], result[5], result[6], result[7],
             result[8], result[9], result[10], result[11],
             result[12], result[13], result[14], result[15]] lowercaseString];
}

+ (NSString *)deviceModelName {

    static NSString *retVal = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        // 请查阅 https://www.theiphonewiki.com/wiki/Models 更新设备号
        // 如果上面维基百科没有更新,请查阅https://github.com/pluwen/Apple-Device-Model-list 更新设备号,这个比较及时

        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *devStr = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

        // iPhone
        if      ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone1,1"]])                             retVal = @"iPhone";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone1,2"]])                             retVal = @"iPhone 3G";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone2,1"]])                             retVal = @"iPhone 3GS";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone3,1", @"iPhone3,2", @"iPhone3,3"]]) retVal = @"iPhone 4";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone4,1"]])                             retVal = @"iPhone 4S";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone5,1", @"iPhone5,2"]])               retVal = @"iPhone 5";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone5,3", @"iPhone5,4"]])               retVal = @"iPhone 5c";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone6,1", @"iPhone6,2"]])               retVal = @"iPhone 5s";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone7,2"]])                             retVal = @"iPhone 6";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone7,1"]])                             retVal = @"iPhone 6 Plus";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone8,1"]])                             retVal = @"iPhone 6s";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone8,2"]])                             retVal = @"iPhone 6s Plus";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone8,4"]])                             retVal = @"iPhone SE";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone9,1", @"iPhone9,3"]])               retVal = @"iPhone 7";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone9,2", @"iPhone9,4"]])               retVal = @"iPhone 7 Plus";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone10,1", @"iPhone10,4"]])             retVal = @"iPhone 8";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone10,2", @"iPhone10,5"]])             retVal = @"iPhone 8 Plus";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone10,3", @"iPhone10,6"]])             retVal = @"iPhone X";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone11,8"]])                            retVal = @"iPhone XR";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone11,2"]])                            retVal = @"iPhone XS";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone11,4", @"iPhone11,6"]])             retVal = @"iPhone XS Max";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone12,1"]])                            retVal = @"iPhone 11";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone12,3"]])                            retVal = @"iPhone 11 Pro";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone12,5"]])                            retVal = @"iPhone 11 Pro Max";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone12,8"]])                            retVal = @"iPhone SE 2";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone13,1"]])                            retVal = @"iPhone 12 mini";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone13,2"]])                            retVal = @"iPhone 12";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone13,3"]])                            retVal = @"iPhone 12 Pro";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPhone13,4"]])                            retVal = @"iPhone 12 Pro Max";


        // iPod
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPod1,1"]])             retVal = @"iPod touch";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPod2,1"]])             retVal = @"iPod touch (2nd generation)";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPod3,1"]])             retVal = @"iPod touch (3rd generation)";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPod4,1"]])             retVal = @"iPod touch (4th generation)";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPod5,1"]])             retVal = @"iPod touch (5th generation)";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPod7,1"]])             retVal = @"iPod touch (6th generation)";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPod9,1"]])             retVal = @"iPod touch (7th generation)";

        // iPad
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad1,1"]])                                     retVal = @"iPad";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad2,1", @"iPad2,2", @"iPad2,3", @"iPad2,4"]]) retVal = @"iPad 2";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad3,1", @"iPad3,2", @"iPad3,3"]])             retVal = @"iPad 3";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad3,4", @"iPad3,5", @"iPad3,6"]])             retVal = @"iPad 4";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad6,11", @"iPad6,12"]])                       retVal = @"iPad 5";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad7,5", @"iPad7,6"]])                         retVal = @"iPad 6";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad7,11", @"iPad7,12"]])                       retVal = @"iPad 7";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad11,6", @"iPad11,7"]])                       retVal = @"iPad 8";

        // iPad  Air
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad4,1", @"iPad4,2", @"iPad4,3"]])             retVal = @"iPad Air";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad5,3", @"iPad5,4"]])                         retVal = @"iPad Air 2";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad11,3", @"iPad11,4"]])                       retVal = @"iPad Air 3";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad13,1", @"iPad13,2"]])                       retVal = @"iPad Air 4";

        //iPad Pro
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad6,3", @"iPad6,4"]])                         retVal = @"iPad Pro (9.7-inch)";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad7,3", @"iPad7,4"]])                         retVal = @"iPad Pro (10.5-inch)";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad8,1", @"iPad8,2", @"iPad8,3", @"iPad8,4"]]) retVal = @"iPad Pro (11-inch)";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad6,7", @"iPad6,8"]])                         retVal = @"iPad Pro (12.9-inch)";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad7,1", @"iPad7,2"]])                         retVal = @"iPad Pro (12.9-inch, 2)";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad8,5", @"iPad8,6", @"iPad8,7", @"iPad8,8"]]) retVal = @"iPad Pro (12.9-inch, 3)";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad8,11", @"iPad8,12"]])                       retVal = @"iPad Pro (12.9-inch, 4)";

        // iPad mini
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad2,5", @"iPad2,6", @"iPad2,7"]]) retVal = @"iPad mini";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad4,4", @"iPad4,5", @"iPad4,6"]]) retVal = @"iPad mini 2";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad4,7", @"iPad4,8", @"iPad4,9"]]) retVal = @"iPad mini 3";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad5,1", @"iPad5,2"]])             retVal = @"iPad mini 4";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"iPad11,1", @"iPad11,2"]])           retVal = @"iPad mini 5";

        // HomePod
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"AudioAccessory1,1", @"AudioAccessory1,2"]]) retVal = @"HomePod";

        // AirPods
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"AirPods1,1"]]) retVal = @"AirPods (1st generation)";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"AirPods2,1"]]) retVal = @"AirPods (2nd generation)";

        // Apple Watch
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"Watch1,1", @"Watch1,2"]])                           retVal = @"Apple Watch (1st generation)";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"Watch2,6", @"Watch2,7"]])                           retVal = @"Apple Watch Series 1";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"Watch2,3", @"Watch2,4"]])                           retVal = @"Apple Watch Series 2";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"Watch3,1", @"Watch3,2", @"Watch3,3", @"Watch3,4"]]) retVal = @"Apple Watch Series 3";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"Watch4,1", @"Watch4,2", @"Watch4,3", @"Watch4,4"]]) retVal = @"Apple Watch Series 4";

        // Apple TV
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"AppleTV2,1"]])                retVal = @"Apple TV (2nd generation)";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"AppleTV3,1", @"AppleTV3,2"]]) retVal = @"Apple TV (3rd generation)";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"AppleTV5,3"]])                retVal = @"Apple TV (4th generation)";
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"AppleTV6,2"]])                retVal = @"Apple TV 4K";

        // Simulator
        else if ([DeviceInfoPlugin devStr:devStr equalTo:@[@"i386", @"x86_64"]]) retVal = @"Simulator";

        // New device.
        else retVal = devStr;
    });

    return retVal;
}

+ (BOOL)devStr:(NSString *)devStr equalTo:(NSArray <NSString *> *)array {

    __block BOOL equal = NO;

    [array enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

        if ([devStr isEqualToString:obj]) {

            equal = YES;
            *stop = YES;
        }
    }];

    return equal;
}

// return value is false if code is run on a simulator
- (NSString*)isDevicePhysical {
#if TARGET_OS_SIMULATOR
  NSString* isPhysicalDevice = @"false";
#else
  NSString* isPhysicalDevice = @"true";
#endif

  return isPhysicalDevice;
}
@end
