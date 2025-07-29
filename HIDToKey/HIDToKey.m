//
//  HIDToKey.m
//  Created on 2025-07-28
//
//  Gamepad → Tastatur-Bridge für Google Earth Web und andere Anwendungen.
//
//  Entwickelt von:
//    - Stino (Projektleitung, Coding, Hardwareanalyse, Integration)
//    - Keysworth (ChatGPT) (unterstützende Assistenz für Code, Architektur und Debugging)
//
//  Lizenz: MIT
//
//  Hinweis: Dieses Tool ermöglicht die Nutzung von HID-Controllern in browserbasierten 3D-Umgebungen.
//  Die Nutzung erfolgt auf eigenes Risiko. Der Autor übernimmt keine Haftung für eventuelle Schäden.

#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDManager.h>
#import <ApplicationServices/ApplicationServices.h>

#define MAX_BUTTONS 16
#define NUM_AXES 4

IOHIDManagerRef hidManager;
bool lastButtonStates[MAX_BUTTONS] = { false };
bool shiftIsDown = false;

typedef struct {
    bool isDownLow;
    bool isDownHigh;
} AxisState;
AxisState axisStates[NUM_AXES] = { 0 };

NSMutableDictionary *configDict = nil;
NSString *configPath = nil;
NSNumber *reportIDExpected = @0x30;

#pragma mark - Datenstrukturen

typedef struct {
    uint8_t index;
    uint8_t offset;
    uint8_t mask;
    CGKeyCode keyCode;
    CGEventFlags modifier;
    NSString *label;
} ButtonMapEntry;

typedef struct {
    NSString *label;
    uint8_t offset;
    bool isHighNibbleFirst;
    uint16_t center;
    uint16_t tolerance;
    CGKeyCode keyCodeLow;
    CGEventFlags modifierLow;
    CGKeyCode keyCodeHigh;
    CGEventFlags modifierHigh;
} AxisMapEntry;

ButtonMapEntry buttonMap[MAX_BUTTONS] = { 0 };

AxisMapEntry axisMap[NUM_AXES] = { 0 };


NSString* deviceIdentifier(IOHIDDeviceRef device) {
    NSNumber *vendorID = (__bridge NSNumber *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDVendorIDKey));
    NSNumber *productID = (__bridge NSNumber *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductIDKey));
    if (vendorID && productID) {
        return [NSString stringWithFormat:@"VID_%04x_PID_%04x", vendorID.intValue, productID.intValue];
    }
    return @"UNKNOWN_DEVICE";
}



NSString *getConfigPath() {
    NSString *dir = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/HIDToKey"];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    return [dir stringByAppendingPathComponent:@"config.json"];
}


NSDictionary* serializeCurrentConfig() {
    NSMutableArray *buttons = [NSMutableArray array];
    for (int i = 0; i < MAX_BUTTONS; i++) {
        const ButtonMapEntry entry = buttonMap[i];
        if (entry.mask == 0) continue;
        [buttons addObject:@{
            @"index": @(entry.index),
            @"offset": @(entry.offset),
            @"mask": @(entry.mask),
            @"keyCode": @(entry.keyCode),
            @"modifier": @(entry.modifier),
            @"label": entry.label ?: @""
        }];
    }

    NSMutableArray *axes = [NSMutableArray array];
    for (int i = 0; i < NUM_AXES; i++) {
        const AxisMapEntry *entry = &axisMap[i];
        [axes addObject:@{
            @"label": entry->label ?: @"",
            @"offset": @(entry->offset),
            @"isHighNibbleFirst": @(entry->isHighNibbleFirst),
            @"center": @(entry->center),
            @"tolerance": @(entry->tolerance),
            @"keyCodeLow": @(entry->keyCodeLow),
            @"modifierLow": @(entry->modifierLow),
            @"keyCodeHigh": @(entry->keyCodeHigh),
            @"modifierHigh": @(entry->modifierHigh)
        }];
    }

    return @{
        @"note": @"Dies ist eine automatisch erzeugte Default-Mapping-Konfiguration",
        @"reportID": @0x30,
        @"buttons": buttons,
        @"axes": axes
    };
}


void loadConfigForDevice(IOHIDDeviceRef device) {
    if (!configDict) {
        configPath = getConfigPath();

        NSData *data = [NSData dataWithContentsOfFile:configPath];
        if (data) {
            NSError *err = nil;
            configDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
            if (!configDict) {
                NSLog(@"⚠️ Fehler beim Laden der Konfiguration: %@", err);
                configDict = [NSMutableDictionary dictionary];
            }
        } else {
            configDict = [NSMutableDictionary dictionary];
        }
    }

    // Gerätedaten ermitteln
    NSNumber *vid = IOHIDDeviceGetProperty(device, CFSTR(kIOHIDVendorIDKey));
    NSNumber *pid = IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductIDKey));
    if (!vid || !pid) return;

    NSString *deviceID = [NSString stringWithFormat:@"VID_%04x_PID_%04x", vid.intValue, pid.intValue];
    NSLog(@"🔌 Device connected: %@", deviceID);

    NSDictionary *entry = configDict[deviceID];
    
    if (!entry) {
        NSDictionary *defaultConfig = serializeCurrentConfig();
        configDict[deviceID] = defaultConfig;

        NSData *newData = [NSJSONSerialization dataWithJSONObject:configDict options:NSJSONWritingPrettyPrinted error:nil];
        [newData writeToFile:configPath atomically:YES];
        NSLog(@"💾 Default-Konfiguration gespeichert unter %@", configPath);
    } else {
        NSLog(@"📂 Konfiguration gefunden für %@", deviceID);
        reportIDExpected = entry[@"reportID"];
    }
}


// TODO unused code
void saveConfigurationForDevice(IOHIDDeviceRef device, NSDictionary *deviceConfig) {
    NSString *key = deviceIdentifier(device);
    NSMutableDictionary *allConfigs = [NSMutableDictionary dictionary];
    NSData *data = [NSData dataWithContentsOfFile:configPath];
    if (data) {
        allConfigs = [[NSJSONSerialization JSONObjectWithData:data options:0 error:nil] mutableCopy];
    }
    allConfigs[key] = deviceConfig;
    data = [NSJSONSerialization dataWithJSONObject:allConfigs options:NSJSONWritingPrettyPrinted error:nil];
    [data writeToFile:configPath atomically:YES];
}

// TODO unused code
NSDictionary *defaultConfiguration() {
    NSMutableArray *buttons = [NSMutableArray array];
    for (int i = 0; i < MAX_BUTTONS; i++) {
        [buttons addObject:@{ 
            @"index": @(i),
            @"offset": @(i < 4 ? 5 : 3),
            @"mask": @(1 << (i % 8)),
            @"keyCode": @(i < 4 ? 123 + i : 0),
            @"modifier": @(0),
            @"label": [NSString stringWithFormat:@"BTN%d", i]
        }];
    }
    NSArray *axes = @[ 
        @{ @"label": @"X", @"offset": @6, @"high": @NO, @"center": @2048, @"tolerance": @256, @"low": @123, @"lowMod": @0, @"highKey": @124, @"highMod": @0 },
        @{ @"label": @"Y", @"offset": @6, @"high": @YES, @"center": @2032, @"tolerance": @256, @"low": @125, @"lowMod": @0, @"highKey": @126, @"highMod": @0 },
        @{ @"label": @"Zx", @"offset": @9, @"high": @NO, @"center": @2048, @"tolerance": @256, @"low": @124, @"lowMod": @(kCGEventFlagMaskShift), @"highKey": @123, @"highMod": @(kCGEventFlagMaskShift) },
        @{ @"label": @"Zy", @"offset": @9, @"high": @YES, @"center": @2032, @"tolerance": @256, @"low": @126, @"lowMod": @(kCGEventFlagMaskShift), @"highKey": @125, @"highMod": @(kCGEventFlagMaskShift) }
    ];
    return @{ @"buttons": buttons, @"axes": axes, @"reportID": @0x30 };
}


// TODO unused code
void applyConfiguration(NSDictionary *config) {
    NSArray *buttons = config[@"buttons"];
    for (int i = 0; i < MAX_BUTTONS && i < buttons.count; i++) {
        NSDictionary *b = buttons[i];
        buttonMap[i].index = [b[@"index"] intValue];
        buttonMap[i].offset = [b[@"offset"] intValue];
        buttonMap[i].mask = [b[@"mask"] intValue];
        buttonMap[i].keyCode = [b[@"keyCode"] intValue];
        buttonMap[i].modifier = [b[@"modifier"] intValue];
        buttonMap[i].label = b[@"label"];
    }
    NSArray *axes = config[@"axes"];
    for (int i = 0; i < NUM_AXES && i < axes.count; i++) {
        NSDictionary *a = axes[i];
        axisMap[i].label = a[@"label"];
        axisMap[i].offset = [a[@"offset"] intValue];
        axisMap[i].isHighNibbleFirst = [a[@"high"] boolValue];
        axisMap[i].center = [a[@"center"] intValue];
        axisMap[i].tolerance = [a[@"tolerance"] intValue];
        axisMap[i].keyCodeLow = [a[@"low"] intValue];
        axisMap[i].modifierLow = [a[@"lowMod"] intValue];
        axisMap[i].keyCodeHigh = [a[@"highKey"] intValue];
        axisMap[i].modifierHigh = [a[@"highMod"] intValue];
    }
    
    reportIDExpected = config[@"reportID"];
}


uint16_t decodeAxis(const uint8_t* report, uint8_t offset, bool highNibbleFirst) {
    uint8_t b0 = report[offset];
    uint8_t b1 = report[offset + 1];
    uint8_t b2 = report[offset + 2];

    if (highNibbleFirst) {
        return ((b1 >> 4) & 0x0F) | (b2 << 4);
    } else {
        return b0 | ((b1 & 0x0F) << 8);
    }
}


void sendKey(CGKeyCode keyCode, bool down, CGEventFlags flags) {
    CGKeyCode modifierKeyCode = 0;
    if (flags & kCGEventFlagMaskShift) modifierKeyCode = 56; // Left Shift
    else if (flags & kCGEventFlagMaskControl) modifierKeyCode = 59;
    else if (flags & kCGEventFlagMaskAlternate) modifierKeyCode = 58;
    else if (flags & kCGEventFlagMaskCommand) modifierKeyCode = 55;

    if (keyCode == 0) return;

    if (modifierKeyCode != 0) {
        if (down) {
            CGEventRef modDown = CGEventCreateKeyboardEvent(NULL, modifierKeyCode, true);
            CGEventPost(kCGHIDEventTap, modDown);
            CFRelease(modDown);

            usleep(30000); // kurze Pause vor dem Hauptkey

            CGEventRef keyDown = CGEventCreateKeyboardEvent(NULL, keyCode, true);
            CGEventPost(kCGHIDEventTap, keyDown);
            CFRelease(keyDown);
        } else {
            CGEventRef keyUp = CGEventCreateKeyboardEvent(NULL, keyCode, false);
            CGEventPost(kCGHIDEventTap, keyUp);
            CFRelease(keyUp);

            usleep(30000); // ← wichtig: Shift bleibt *kurz* gedrückt

            CGEventRef modUp = CGEventCreateKeyboardEvent(NULL, modifierKeyCode, false);
            CGEventPost(kCGHIDEventTap, modUp);
            CFRelease(modUp);
        }
    } else {
        CGEventRef evt = CGEventCreateKeyboardEvent(NULL, keyCode, down);
        CGEventPost(kCGHIDEventTap, evt);
        CFRelease(evt);
    }
}


// Callback für HID Report
void Handle_InputReport(void* context,
                        IOReturn result,
                        void* sender,
                        IOHIDReportType type,
                        uint32_t reportID,
                        uint8_t* report,
                        CFIndex reportLength) {

//    NSLog(@"Report (%ld bytes): %@", reportLength, [[NSData dataWithBytes:report length:reportLength] description]);

    if (reportIDExpected && reportID != reportIDExpected.unsignedIntValue) {
        return; // Report ignorieren
    }

    if (reportLength < 6) return;

    for (int i = 0; i < MAX_BUTTONS; i++) {
        const ButtonMapEntry entry = buttonMap[i];
        if (entry.mask == 0 || entry.offset >= reportLength) continue;

        bool isDown = (report[entry.offset] & entry.mask) != 0;
        bool wasDown = lastButtonStates[i];

        if (!wasDown && isDown) {
            NSLog(@"%@ down", entry.label);
            sendKey(entry.keyCode, true, entry.modifier);
        } else if (wasDown && !isDown) {
            NSLog(@"%@ up", entry.label);
            sendKey(entry.keyCode, false, entry.modifier);
        }

        lastButtonStates[i] = isDown;
    }

    for (int i = 0; i < NUM_AXES; ++i) {
        AxisMapEntry *entry = &axisMap[i];
        AxisState *state = &axisStates[i];

        if (entry->offset + 2 >= reportLength) continue;

        uint16_t value = decodeAxis(report, entry->offset, entry->isHighNibbleFirst);
//        NSLog(@"%@: axis=%d", entry->label, value);

        bool isLow = value + entry->tolerance < entry->center;
        bool isHigh = value > entry->center + entry->tolerance;

        if (!state->isDownLow && isLow) {
            NSLog(@"%@ ⇦ down", entry->label);
            sendKey(entry->keyCodeLow, true, entry->modifierLow);
            state->isDownLow = true;
        } else if (state->isDownLow && !isLow) {
            NSLog(@"%@ ⇦ up", entry->label);
            sendKey(entry->keyCodeLow, false, entry->modifierLow);
            state->isDownLow = false;
        }

        if (!state->isDownHigh && isHigh) {
            NSLog(@"%@ ⇨ down", entry->label);
            sendKey(entry->keyCodeHigh, true, entry->modifierHigh);
            state->isDownHigh = true;
        } else if (state->isDownHigh && !isHigh) {
            NSLog(@"%@ ⇨ up", entry->label);
            sendKey(entry->keyCodeHigh, false, entry->modifierHigh);
            state->isDownHigh = false;
        }
    }
}

void resetDefaultMapping() {
    memcpy(buttonMap, (ButtonMapEntry[]){
        {  0, 5, 0x01, 125, 0, @"⬇️" },
        {  1, 5, 0x02, 126, 0, @"⬆️" },
        {  2, 5, 0x04, 124, 0, @"⬅️" },
        {  3, 5, 0x08, 123, 0, @"➡️" },
        {  4, 3, 0x04, 126,  kCGEventFlagMaskShift, @"🅱️" },
        {  5, 3, 0x02, 125,  kCGEventFlagMaskShift, @"❎" },
        {  6, 3, 0x01, 124,  kCGEventFlagMaskShift, @"🇾" },
        {  7, 3, 0x08, 123,  kCGEventFlagMaskShift, @"🅰️" },
        {  8, 5, 0x80, 121, 0, @"🇱2️⃣" },
        {  9, 3, 0x80, 116, 0, @"🇷2️⃣" },
        { 10, 5, 0x40, 121, kCGEventFlagMaskShift, @"🇱1️⃣" },
        { 11, 3, 0x40, 116, kCGEventFlagMaskShift, @"🇷1️⃣" },
        { 12, 4, 0x01, 0, 0, @"⏏️" },
        { 13, 4, 0x02, 0, 0, @"▶️" },
        { 14, 4, 0x04, 0, 0, @"🇱🕹️" },
        { 15, 4, 0x08, 0, 0, @"🇷🕹️" }
    }, sizeof(buttonMap));

    memcpy(axisMap, (AxisMapEntry[]){
        { @"X", 6, false, 2048, 256, 123, 0, 124, 0 },
        { @"Y", 6, true,  2032, 256, 125, 0, 126, 0 },
        { @"Zx", 9, false, 2048, 256,124, kCGEventFlagMaskShift, 123, kCGEventFlagMaskShift },
        { @"Zy", 9, true,  2032, 256,126, kCGEventFlagMaskShift, 125, kCGEventFlagMaskShift }
    }, sizeof(axisMap));
    
    reportIDExpected = @0x30;
}


void Handle_DeviceConnected(void* context, IOReturn result, void* sender, IOHIDDeviceRef device) {
    resetDefaultMapping();
    loadConfigForDevice(device);
}


void Handle_DeviceDisconnected(void* context, IOReturn result, void* sender, IOHIDDeviceRef device) {
    NSLog(@"🔌 Device disconnected: %@", deviceIdentifier(device));

    // Reset all pressed buttons
    for (int i = 0; i < MAX_BUTTONS; i++) {
        if (lastButtonStates[i]) {
            const ButtonMapEntry entry = buttonMap[i];
            sendKey(entry.keyCode, false, entry.modifier); // Key up
            lastButtonStates[i] = false;
        }
    }

    // Reset all axis states
    for (int i = 0; i < NUM_AXES; i++) {
        AxisMapEntry *entry = &axisMap[i];
        AxisState *state = &axisStates[i];

        if (state->isDownLow) {
            sendKey(entry->keyCodeLow, false, entry->modifierLow);
            state->isDownLow = false;
        }

        if (state->isDownHigh) {
            sendKey(entry->keyCodeHigh, false, entry->modifierHigh);
            state->isDownHigh = false;
        }
    }

    // 💡 Speicher freigeben oder zurücksetzen
    configDict = nil;
    configPath = nil;
}


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSLog(@"🎮 Starte HIDToKey (alle Buttons → Tastatur)");

        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);

        NSArray* matchMultiple = @[
            @{ @kIOHIDDeviceUsagePageKey: @(kHIDPage_GenericDesktop),
               @kIOHIDDeviceUsageKey: @(kHIDUsage_GD_Joystick) },

            @{ @kIOHIDDeviceUsagePageKey: @(kHIDPage_GenericDesktop),
               @kIOHIDDeviceUsageKey: @(kHIDUsage_GD_GamePad) }
        ];
        IOHIDManagerSetDeviceMatchingMultiple(hidManager, (__bridge CFArrayRef)matchMultiple);


        // Device connect/disconnect callbacks:
        IOHIDManagerRegisterDeviceMatchingCallback(hidManager, Handle_DeviceConnected, NULL);
        IOHIDManagerRegisterDeviceRemovalCallback(hidManager, Handle_DeviceDisconnected, NULL);

        IOHIDManagerRegisterInputReportCallback(hidManager,
                                                Handle_InputReport,
                                                NULL);

        IOHIDManagerScheduleWithRunLoop(hidManager,
                                        CFRunLoopGetCurrent(),
                                        kCFRunLoopDefaultMode);

        IOReturn ret = IOHIDManagerOpen(hidManager, kIOHIDOptionsTypeNone);
        if (ret != kIOReturnSuccess) {
            NSLog(@"❌ HID Manager konnte nicht geöffnet werden");
            return 1;
        }

        NSLog(@"✅ Lausche auf Eingaben...");
        CFRunLoopRun();
    }
    return 0;
}

