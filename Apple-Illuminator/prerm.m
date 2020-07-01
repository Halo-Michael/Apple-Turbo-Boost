#include <Foundation/Foundation.h>
#include <sys/sysctl.h>

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
    if (access([[NSString stringWithFormat:@"/System/Library/Watchdog/ThermalMonitor.bundle/%sAP.bundle/Info.plist.bak", machine] UTF8String], F_OK) == 0) {
        watchdogPlist = [NSString stringWithFormat:@"/System/Library/Watchdog/ThermalMonitor.bundle/%sAP.bundle/Info.plist", machine];
    } else if (access([[NSString stringWithFormat:@"/System/Library/ThermalMonitor/%sAP-Info.plist.bak", machine] UTF8String], F_OK) == 0) {
        watchdogPlist = [NSString stringWithFormat:@"/System/Library/ThermalMonitor/%sAP-Info.plist", machine];
    } else {
        printf("Error: Couldn't find the original WatchDog properties plist file %s.\n", [watchdogPlist UTF8String]);
        return 2;
    }

    remove([watchdogPlist UTF8String]);
    [[NSFileManager defaultManager] moveItemAtPath:[NSString stringWithFormat:@"%@.bak", watchdogPlist] toPath:watchdogPlist error:nil];
    printf("Restored the backup file.\n");

    return 0;
}
