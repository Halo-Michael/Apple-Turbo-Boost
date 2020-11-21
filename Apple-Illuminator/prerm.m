#import <Foundation/Foundation.h>
#import <sys/sysctl.h>

int main() {
    if (getuid() != 0) {
        printf("Run this as root!\n");
        return 1;
    }

    size_t size;
    sysctlbyname("hw.targettype", NULL, &size, NULL, 0);
    char *machine = calloc(size, sizeof(char));
    sysctlbyname("hw.targettype", machine, &size, NULL, 0);

    NSString *watchdogPlist = [NSString stringWithFormat:@"/System/Library/Watchdog/ThermalMonitor.bundle/%sAP.bundle/Info.plist", machine];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[watchdogPlist stringByAppendingString:@".bak"]]) {
        watchdogPlist = [NSString stringWithFormat:@"/System/Library/ThermalMonitor/%sAP-Info.plist", machine];
    }
    free(machine);
    if (![[NSFileManager defaultManager] fileExistsAtPath:[watchdogPlist stringByAppendingString:@".bak"]]) {
        printf("Error: Couldn't find the original WatchDog properties plist file %s.\n", [watchdogPlist UTF8String]);
        return 2;
    }

    [[NSFileManager defaultManager] removeItemAtPath:watchdogPlist error:nil];
    [[NSFileManager defaultManager] moveItemAtPath:[watchdogPlist stringByAppendingString:@".bak"] toPath:watchdogPlist error:nil];
    printf("Restored the backup file.\n");

    return 0;
}
