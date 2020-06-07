#include <CoreFoundation/CoreFoundation.h>
#include <sys/sysctl.h>

bool modifyPlist(NSString *filename, void (^function)(id)) {
    NSData *data = [NSData dataWithContentsOfFile:filename];
    if (data == nil) {
        return false;
    }
    NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
    NSError *error = nil;
    id plist = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];
    if (plist == nil) {
        return false;
    }
    if (function) {
        function(plist);
    }
    NSData *newData = [NSPropertyListSerialization dataWithPropertyList:plist format:format options:0 error:&error];
    if (newData == nil) {
        return false;
    }
    if (![data isEqual:newData]) {
        if (![newData writeToFile:filename atomically:YES]) {
            return false;
        }
    }
    return true;
}

int main() {
    if (getuid() != 0) {
        printf("Run this as root!\n");
        return 1;
    }

    size_t size;
    sysctlbyname("hw.targettype", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.targettype", machine, &size, 0, 0);

    NSString *watchdogPlist;
    if (access([[NSString stringWithFormat:@"/System/Library/Watchdog/ThermalMonitor.bundle/%sAP.bundle/Info.plist", machine] UTF8String], F_OK) == 0) {
        watchdogPlist = [NSString stringWithFormat:@"/System/Library/Watchdog/ThermalMonitor.bundle/%sAP.bundle/Info.plist", machine];
    } else if (access([[NSString stringWithFormat:@"/System/Library/ThermalMonitor/%sAP-Info.plist", machine] UTF8String], F_OK) == 0) {
        watchdogPlist = [NSString stringWithFormat:@"/System/Library/ThermalMonitor/%sAP-Info.plist", machine];
    } else {
        printf("Error: Couldn't find the WatchDog properties plist file %s.\n", [watchdogPlist UTF8String]);
        return 2;
    }

    [[NSFileManager defaultManager] copyItemAtPath:watchdogPlist toPath:[NSString stringWithFormat:@"%@.bak", watchdogPlist] error:nil];
    printf("Created the backup file %s.\n", [[NSString stringWithFormat:@"%@.bak", watchdogPlist] UTF8String]);

    NSMutableDictionary *thermalMitigationLimits = [NSMutableDictionary dictionary];
    thermalMitigationLimits[@"heavy"] = [NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"thermalMitigationLimits"][@"light"];
    thermalMitigationLimits[@"light"] = [NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"thermalMitigationLimits"][@"light"];
    thermalMitigationLimits[@"moderate"] = [NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"thermalMitigationLimits"][@"light"];
    modifyPlist(watchdogPlist, ^(id plist) {
        plist[@"thermalMitigationLimits"] = thermalMitigationLimits;
    });

    modifyPlist(watchdogPlist, ^(id plist) {
        plist[@"contextualClampParams"][@"lowParamsPeakPower"] = nil;
    });
    modifyPlist(watchdogPlist, ^(id plist) {
        plist[@"contextualClampParams"][@"lowParamsSpeaker"] = nil;
    });

    for (int i = 0; i < [[NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"hotspots"] count]; i++) {
        if ([[NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"hotspots"] objectAtIndex:i][@"ForcedThermalLevelTarget0"] != nil) {
            modifyPlist(watchdogPlist, ^(id plist) {
                [plist[@"hotspots"] objectAtIndex:i][@"ForcedThermalLevelTarget0"] = [NSNumber numberWithInt:99];
            });
        }
        if ([[NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"hotspots"] objectAtIndex:i][@"ForcedThermalLevelTarget1"] != nil) {
            modifyPlist(watchdogPlist, ^(id plist) {
                [plist[@"hotspots"] objectAtIndex:i][@"ForcedThermalLevelTarget1"] = [NSNumber numberWithInt:99];
            });
        }
        if ([[NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"hotspots"] objectAtIndex:i][@"ForcedThermalPressureLevelLightTarget"] != nil) {
            modifyPlist(watchdogPlist, ^(id plist) {
                [plist[@"hotspots"] objectAtIndex:i][@"ForcedThermalPressureLevelLightTarget"] = [NSNumber numberWithInt:99];
            });
        }
        if ([[NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"hotspots"] objectAtIndex:i][@"THERMAL_TRAP_LOAD"] != nil) {
            modifyPlist(watchdogPlist, ^(id plist) {
                [plist[@"hotspots"] objectAtIndex:i][@"THERMAL_TRAP_LOAD"] = [NSNumber numberWithInt:99];
            });
        }
        if ([[NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"hotspots"] objectAtIndex:i][@"THERMAL_TRAP_SLEEP"] != nil) {
            modifyPlist(watchdogPlist, ^(id plist) {
                [plist[@"hotspots"] objectAtIndex:i][@"THERMAL_TRAP_SLEEP"] = [NSNumber numberWithInt:100];
            });
        }
        if ([[NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"hotspots"] objectAtIndex:i][@"target"] != nil) {
            modifyPlist(watchdogPlist, ^(id plist) {
                [plist[@"hotspots"] objectAtIndex:i][@"target"] = [NSNumber numberWithInt:99];
            });
        }
    }

    NSMutableDictionary *lowTempMitigationLimits = [NSMutableDictionary dictionary];
    lowTempMitigationLimits[@"heavy"] = [NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"lowTempMitigationLimits"][@"nominal"];
    lowTempMitigationLimits[@"light"] = [NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"lowTempMitigationLimits"][@"nominal"];
    lowTempMitigationLimits[@"moderate"] = [NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"lowTempMitigationLimits"][@"nominal"];
    lowTempMitigationLimits[@"nominal"] = [NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"lowTempMitigationLimits"][@"nominal"];
    modifyPlist(watchdogPlist, ^(id plist) {
        plist[@"lowTempMitigationLimits"] = lowTempMitigationLimits;
    });

    NSMutableArray *BacklightBrightness = [NSMutableArray new];
    for (int i = 0; i < 4; i++) {
        [BacklightBrightness addObject:[NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"backlightComponentControl"][@"BacklightBrightness"][0]];
    }
    modifyPlist(watchdogPlist, ^(id plist) {
        plist[@"backlightComponentControl"][@"BacklightBrightness"] = BacklightBrightness;
    });

    if ([NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"backlightComponentControl"][@"BacklightPower"] != nil) {
        NSMutableArray *BacklightPower = [NSMutableArray new];
        for (int i = 0; i < 4; i++) {
            [BacklightPower addObject:[NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"backlightComponentControl"][@"BacklightPower"][0]];
        }
        modifyPlist(watchdogPlist, ^(id plist) {
            plist[@"backlightComponentControl"][@"BacklightPower"] = BacklightPower;
        });
    }

    if ([NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"backlightComponentControl"][@"maxThermalPower"] != nil) {
        modifyPlist(watchdogPlist, ^(id plist) {
            plist[@"backlightComponentControl"][@"minThermalPower"] = plist[@"backlightComponentControl"][@"maxThermalPower"];
        });
    }

    printf("Everything Done! You need a reboot or ldrestart to Turbo Boost your Apple!\n");

    return 0;
}
