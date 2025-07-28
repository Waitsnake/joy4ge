//
//  HIDToKey.m
//  Created on 2025-07-28
//
//  Gamepad → Tastatur-Bridge für Google Earth Web und andere Anwendungen.
//
//  Entwickelt von:
//    - Stino (Projektleitung, Coding, Hardwareanalyse, Integration)
//    - ChatGPT (unterstützende Assistenz für Code, Architektur und Debugging)
//
//  Lizenz: MIT
//
//  Hinweis: Dieses Tool ermöglicht die Nutzung von HID-Controllern in browserbasierten 3D-Umgebungen.
//  Die Nutzung erfolgt auf eigenes Risiko. Der Autor übernimmt keine Haftung für eventuelle Schäden.
//

#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDManager.h>
#import <ApplicationServices/ApplicationServices.h>

#define MAX_BUTTONS 16
#define NUM_AXES 4

IOHIDManagerRef hidManager;
bool lastButtonStates[MAX_BUTTONS] = { false };
bool shiftIsDown = false;

// Struktur für Button-Mapping
typedef struct {
    uint8_t index;       // Laufender Index 0–15
    uint8_t offset;      // Byte Offset im Report
    uint8_t mask;        // Bitmaske im Byte
    CGKeyCode keyCode;   // Ziel-Event-Taste
    CGEventFlags modifier; // z.B. kCGEventFlagMaskShift
    NSString *label;
} ButtonMapEntry;

// Beispiel-Mapping: 4 D-Pad-Richtungen + 2 Buttons (z. B. A und B)
const ButtonMapEntry buttonMap[MAX_BUTTONS] = {
    // D-Pad Buttons (Byte 5, Bit 0–3)
    {  0, 5, 0x01, 125, 0, @"⬇️" }, // dpad-down -> Down
    {  1, 5, 0x02, 126, 0, @"⬆️" }, // dpad-up -> Up
    {  2, 5, 0x04, 124, 0, @"⬅️" }, // dpad-left -> Left
    {  3, 5, 0x08, 123, 0, @"➡️" }, // dpad-reight -> Right

    // A/B/X/Y Buttons (Byte 3, Bit 0–3)
    {  4, 3, 0x04, 126,  kCGEventFlagMaskShift, @"🅱️" }, // B -> Shift+Up
    {  5, 3, 0x02, 125,  kCGEventFlagMaskShift, @"❎" }, // X -> Shift+Down
    {  6, 3, 0x01, 123,  kCGEventFlagMaskShift, @"🇾" }, // Y -> Shift+Left
    {  7, 3, 0x08, 124,  kCGEventFlagMaskShift, @"🅰️" }, // A -> Shift+Right

    // L1/L2/R1/R2 Buttons (Byte 3, Bit 6-7) und (Byte 5, Bit 6-7)
    {  8, 5, 0x80, 121, 0, @"🇱2️⃣" }, // L2 -> Page Down
    {  9, 3, 0x80, 116, 0, @"🇷2️⃣" }, // R2 -> Page Up
    { 10, 5, 0x40, 121, kCGEventFlagMaskShift, @"🇱1️⃣" }, // L1 -> Shift+Page Down
    { 11, 3, 0x40, 116, kCGEventFlagMaskShift, @"🇷1️⃣" }, // R1 -> Shift+Page Up

    // Platzhalter für Buttons 12–15
    { 12, 4, 0x01, 0, 0, @"⏏️" }, // Select -> 0
    { 13, 4, 0x02, 0, 0, @"▶️" }, // Start -> 0
    { 14, 4, 0x04, 0, 0, @"🇱🕹️" }, // Right Axis Button -> 0 
    { 15, 4, 0x08, 0, 0, @"🇷🕹️" } // Left Axis Button -> 0
};

typedef struct {
    NSString *label;
    uint8_t offset;  // Startoffset in Report (z. B. 6 für X/Y, 9 für Zx/Zy)
    bool isHighNibbleFirst; // true = Y-seitig der Wert beginnt oben (wie in deinem Fall)
    uint16_t center;  // z. B. 2048
    uint16_t tolerance; // Deadzone z. B. ±128
    CGKeyCode keyCodeLow;  // Taste bei Bewegung in Richtung "Low" (z. B. Links)
    CGEventFlags modifierLow; // z.B. kCGEventFlagMaskShift
    CGKeyCode keyCodeHigh; // Taste bei Bewegung in Richtung "High" (z. B. Rechts)
    CGEventFlags modifierHigh; // z.B. kCGEventFlagMaskShift
    bool isDownLow;
    bool isDownHigh;
} AxisMapEntry;


AxisMapEntry axisMap[NUM_AXES] = {
    { @"X", 6, false, 2048, 256, 123, 0, 124, 0, false, false }, // Left / Right
    { @"Y", 6, true,  2032, 256, 125, 0, 126, 0, false, false }, // Down / Up
    { @"Zx", 9, false, 2048, 256,123, kCGEventFlagMaskShift, 124, kCGEventFlagMaskShift, false, false },    // rotate
    { @"Zy", 9, true,  2032, 256,126, kCGEventFlagMaskShift, 125, kCGEventFlagMaskShift, false, false },    // inclination
};

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
        if (entry->offset + 2 >= reportLength) continue;

        uint16_t value = decodeAxis(report, entry->offset, entry->isHighNibbleFirst);
//        NSLog(@"%@: axis=%d", entry->label, value);

        bool isLow = value + entry->tolerance < entry->center;
        bool isHigh = value > entry->center + entry->tolerance;

        if (!entry->isDownLow && isLow) {
            NSLog(@"%@ ⇦ down", entry->label);
            sendKey(entry->keyCodeLow, true, entry->modifierLow);
            entry->isDownLow = true;
        } else if (entry->isDownLow && !isLow) {
            NSLog(@"%@ ⇦ up", entry->label);
            sendKey(entry->keyCodeLow, false, entry->modifierLow);
            entry->isDownLow = false;
        }

        if (!entry->isDownHigh && isHigh) {
            NSLog(@"%@ ⇨ down", entry->label);
            sendKey(entry->keyCodeHigh, true, entry->modifierHigh);
            entry->isDownHigh = true;
        } else if (entry->isDownHigh && !isHigh) {
            NSLog(@"%@ ⇨ up", entry->label);
            sendKey(entry->keyCodeHigh, false, entry->modifierHigh);
            entry->isDownHigh = false;
        }
    }


}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSLog(@"🎮 Starte HIDToKey (alle Buttons → Tastatur)");

        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);

        NSDictionary* matchDict = @{
            @kIOHIDDeviceUsagePageKey: @(0x01), // Generic Desktop
            @kIOHIDDeviceUsageKey: @(0x05)      // Gamepad
        };
        IOHIDManagerSetDeviceMatching(hidManager, (__bridge CFDictionaryRef)matchDict);

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

