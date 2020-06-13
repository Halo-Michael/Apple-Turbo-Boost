#include <CoreFoundation/CoreFoundation.h>

int main() {
    char *cydia_env = getenv("CYDIA");
    if (cydia_env != NULL) {
        int cydiaFd = (int)strtoul(cydia_env, NULL, 10);
        if (cydiaFd != 0) {
            write(cydiaFd, "finish:reboot\n", 14);
        }
    }
    return 0;
}

