/*
 *  HIDConnection.m
 *  3DconnexionClient
 *
 *  Created by Marco Köhler on 04.08.12.
 *
 */

#import "HIDConnection.h"


@interface HIDConnection ()

@property (readwrite, retain) __attribute__((NSObject)) IOHIDManagerRef hidManagerRef;
@property (readwrite, retain) NSArray* plugHidDevs;

- (void) startListeningOfNewDevices;
- (void) stopListeningOfNewDevices;
- (void) hidDevicePlugged:(IOHIDDeviceRef)devRef;
- (void) hidDeviceUnplugged:(IOHIDDeviceRef)devRef;

@end

void plugCallback(void* context, IOReturn result, void* sender, IOHIDDeviceRef device) {
	if (context == NULL) return;
	HIDConnection* connection = (HIDConnection*)context;
	[connection hidDevicePlugged:device];
}

void unplugCallback(void* context, IOReturn result, void* sender, IOHIDDeviceRef device) {
	if (context == NULL) return;
	HIDConnection* connection = (HIDConnection*)context;
	[connection hidDeviceUnplugged:device];
}

@implementation HIDConnection

@synthesize hidManagerRef;
@synthesize plugHidDevs;

- (id) init {
	self = [super init];
	if (!self) return nil;
	self.hidManagerRef = IOHIDManagerCreate(kCFAllocatorDefault, 0);
    
    // Workaround: Open HID Manager exclusive with kIOHIDOptionsTypeSeizeDevice to prevent that Google Earth detects the HID Joystick by itself. Since GE has it's own  code to handle HID Joystick this leads to problem that both applications(GE and 3DconnexionClient) try to handle the events differently.
	IOHIDManagerOpen(self.hidManagerRef, kIOHIDOptionsTypeSeizeDevice);
    
	self.plugHidDevs = [NSArray array];
	[self startListeningOfNewDevices];
	return self;
}

- (void) dealloc {
	[self stopListeningOfNewDevices];
	IOHIDManagerClose(self.hidManagerRef, 0);
	self.hidManagerRef = NULL;
	[super dealloc];
}

- (void) startListeningOfNewDevices {
	NSDictionary* matchDict = [NSDictionary dictionaryWithObjectsAndKeys:
							   [NSNumber numberWithInt:kHIDPage_GenericDesktop], @kIOHIDDeviceUsagePageKey,
							   [NSNumber numberWithInt:kHIDUsage_GD_Joystick],   @kIOHIDDeviceUsageKey,
							   nil];
	IOHIDManagerSetDeviceMatching(self.hidManagerRef, (CFDictionaryRef)matchDict);
	IOHIDManagerRegisterDeviceMatchingCallback(self.hidManagerRef, plugCallback, self);
	IOHIDManagerRegisterDeviceRemovalCallback(self.hidManagerRef, unplugCallback, self);
	IOHIDManagerScheduleWithRunLoop(self.hidManagerRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
}

- (void) stopListeningOfNewDevices {
	IOHIDManagerUnscheduleFromRunLoop(self.hidManagerRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
}

- (void) hidDevicePlugged:(IOHIDDeviceRef)devRef {
	HIDDevice* newDevice = [HIDDevice deviceWithRef:devRef];
    unsigned long int vedorDevId = 0x046DC626; // VID_046D & PID_C626
	if (newDevice) {
		self.plugHidDevs = [self.plugHidDevs arrayByAddingObject:newDevice];
		NSLog(@"HID device plugged: %@", newDevice);
		NSLog(@"Number of detected axis: %d",newDevice.countAxis);
		NSLog(@"Number of detected buttons: %d",newDevice.countButtons);

        if (theConnection.messageHandler != NULL) theConnection.messageHandler(theConnection.connectionID,kConnexionCtlGetDeviceID,&vedorDevId);
        
	}
}

- (void) hidDeviceUnplugged:(IOHIDDeviceRef)devRef {
	NSMutableArray* activeDevices = [NSMutableArray array];
	for (HIDDevice* hidDevice in self.plugHidDevs) {
		if (hidDevice.deviceRef != devRef) [activeDevices addObject:hidDevice];
		else {
			NSLog(@"HID device unplugged: %@",hidDevice);
		}
	}	
	self.plugHidDevs = activeDevices;
}

@end
