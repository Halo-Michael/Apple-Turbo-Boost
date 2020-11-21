#import <Foundation/Foundation.h>
#import <sys/sysctl.h>

int main(){
    if (getuid() != 0) {
        printf("Run this as root!\n");
        return 1;
    }

    size_t size;
    sysctlbyname("hw.targettype", NULL, &size, NULL, 0);
    char *machine = calloc(size, sizeof(char));
    sysctlbyname("hw.targettype", machine, &size, NULL, 0);

    NSString *watchdogPlist = [NSString stringWithFormat:@"/System/Library/Watchdog/ThermalMonitor.bundle/%sAP.bundle/Info.plist", machine];
    if (![[NSFileManager defaultManager] fileExistsAtPath:watchdogPlist]) {
        watchdogPlist = [NSString stringWithFormat:@"/System/Library/ThermalMonitor/%sAP-Info.plist", machine];
    }
    free(machine);
    if (![[NSFileManager defaultManager] fileExistsAtPath:watchdogPlist]) {
        printf("Error: Couldn't find the WatchDog properties plist file %s.\n", [watchdogPlist UTF8String]);
        return 2;
    }

    NSMutableDictionary *watchdog = [[NSMutableDictionary alloc] initWithContentsOfFile:watchdogPlist];
    if (watchdog == nil) {
        printf("Error: Couldn't load the WatchDog properties plist file %s.\n", [watchdogPlist UTF8String]);
        return 2;
    }

    NSString *watchdogPlistBak = [watchdogPlist stringByAppendingString:@".bak"];
    [[NSFileManager defaultManager] copyItemAtPath:watchdogPlist toPath:watchdogPlistBak error:nil];
    printf("Created the backup file %s.\n", [watchdogPlistBak UTF8String]);

    watchdog[@"thermalMitigationLimits"][@"moderate"] = watchdog[@"thermalMitigationLimits"][@"light"];
    watchdog[@"thermalMitigationLimits"][@"heavy"] = watchdog[@"thermalMitigationLimits"][@"light"];

    watchdog[@"contextualClampParams"][@"lowParamsPeakPower"] = nil;
    watchdog[@"contextualClampParams"][@"lowParamsSpeaker"] = nil;

    for (NSUInteger i = 0; i < [watchdog[@"hotspots"] count]; i++) {
        if (watchdog[@"hotspots"][i][@"ForcedThermalLevelTarget0"] != nil) {
            watchdog[@"hotspots"][i][@"ForcedThermalLevelTarget0"] = [NSNumber numberWithUnsignedInteger:99];
        }
        if (watchdog[@"hotspots"][i][@"ForcedThermalLevelTarget1"] != nil) {
            watchdog[@"hotspots"][i][@"ForcedThermalLevelTarget1"] = [NSNumber numberWithUnsignedInteger:99];
        }
        if (watchdog[@"hotspots"][i][@"ForcedThermalPressureLevelLightTarget"] != nil) {
            watchdog[@"hotspots"][i][@"ForcedThermalPressureLevelLightTarget"] = [NSNumber numberWithUnsignedInteger:99];
        }
        if (watchdog[@"hotspots"][i][@"THERMAL_TRAP_LOAD"] != nil) {
            watchdog[@"hotspots"][i][@"THERMAL_TRAP_LOAD"] = [NSNumber numberWithUnsignedInteger:99];
        }
        if (watchdog[@"hotspots"][i][@"THERMAL_TRAP_SLEEP"] != nil) {
            watchdog[@"hotspots"][i][@"THERMAL_TRAP_SLEEP"] = [NSNumber numberWithUnsignedInteger:100];
        }
        if (watchdog[@"hotspots"][i][@"target"] != nil) {
            watchdog[@"hotspots"][i][@"target"] = [NSNumber numberWithUnsignedInteger:99];
        }
    }

    watchdog[@"lowTempMitigationLimits"][@"light"] = watchdog[@"lowTempMitigationLimits"][@"nominal"];
    watchdog[@"lowTempMitigationLimits"][@"moderate"] = watchdog[@"lowTempMitigationLimits"][@"nominal"];
    watchdog[@"lowTempMitigationLimits"][@"heavy"] = watchdog[@"lowTempMitigationLimits"][@"nominal"];

    for (NSUInteger i = 1; i < [watchdog[@"backlightComponentControl"][@"BacklightBrightness"] count]; i++) {
        watchdog[@"backlightComponentControl"][@"BacklightBrightness"][i] = watchdog[@"backlightComponentControl"][@"BacklightBrightness"][0];
    }

    if (watchdog[@"backlightComponentControl"][@"BacklightPower"] != nil) {
        for (NSUInteger i = 1; i < [watchdog[@"backlightComponentControl"][@"BacklightPower"] count]; i++) {
            watchdog[@"backlightComponentControl"][@"BacklightPower"][i] = watchdog[@"backlightComponentControl"][@"BacklightPower"][0];
        }
    }

    if (watchdog[@"backlightComponentControl"][@"expectsCPMSSupport"] != nil) {
        watchdog[@"backlightComponentControl"][@"expectsCPMSSupport"] = @NO;
    }

    if (watchdog[@"backlightComponentControl"][@"maxThermalPower"] != nil) {
        watchdog[@"backlightComponentControl"][@"minThermalPower"] = watchdog[@"backlightComponentControl"][@"maxThermalPower"];
    }

    [[NSPropertyListSerialization dataWithPropertyList:watchdog format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil] writeToFile:watchdogPlist atomically:YES];

    printf("Everything Done! You need a reboot or ldrestart to Turbo Boost your Apple!\n");

    char *cydia_env = getenv("CYDIA");
    if (cydia_env != NULL) {
        int cydiaFd = (int)strtoul(cydia_env, NULL, 10);
        if (cydiaFd != 0) {
            write(cydiaFd, "finish:reboot\n", 14);
        }
    }
    return 0;
}
