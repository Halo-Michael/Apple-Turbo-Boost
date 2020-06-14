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

    NSMutableArray *BacklightBrightness = [NSMutableArray new];
    for (int i = 0; i < [[NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"backlightComponentControl"][@"BacklightBrightness"] count]; i++) {
        [BacklightBrightness addObject:[NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"backlightComponentControl"][@"BacklightBrightness"][0]];
    }
    modifyPlist(watchdogPlist, ^(id plist) {
        plist[@"backlightComponentControl"][@"BacklightBrightness"] = BacklightBrightness;
    });

    if ([NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"backlightComponentControl"][@"BacklightPower"] != nil) {
        NSMutableArray *BacklightPower = [NSMutableArray new];
        for (int i = 0; i < [[NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"backlightComponentControl"][@"BacklightPower"] count]; i++) {
            [BacklightPower addObject:[NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"backlightComponentControl"][@"BacklightPower"][0]];
        }
        modifyPlist(watchdogPlist, ^(id plist) {
            plist[@"backlightComponentControl"][@"BacklightPower"] = BacklightPower;
        });
    }

    if ([NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"backlightComponentControl"][@"expectsCPMSSupport"] != nil) {
        modifyPlist(watchdogPlist, ^(id plist) {
            plist[@"backlightComponentControl"][@"expectsCPMSSupport"] = [NSNumber numberWithBool:false];
        });
    }

    if ([NSDictionary dictionaryWithContentsOfFile:watchdogPlist][@"backlightComponentControl"][@"maxThermalPower"] != nil) {
        modifyPlist(watchdogPlist, ^(id plist) {
            plist[@"backlightComponentControl"][@"minThermalPower"] = plist[@"backlightComponentControl"][@"maxThermalPower"];
        });
    }

    printf("Everything Done! You need a reboot or ldrestart to illuminate your Apple!\n");

    char *cydia_env = getenv("CYDIA");
    if (cydia_env != NULL) {
        int cydiaFd = (int)strtoul(cydia_env, NULL, 10);
        if (cydiaFd != 0) {
            write(cydiaFd, "finish:reboot\n", 14);
        }
    }
    return 0;
}
