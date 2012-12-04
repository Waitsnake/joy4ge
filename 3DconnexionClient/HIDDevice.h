/*
 *  HIDDevice.h
 *  3DconnexionClient
 *
 *  Created by Marco Köhler on 04.08.12.
 *
 */

#import <Cocoa/Cocoa.h>
#import <IOKit/hid/IOHIDLib.h>

#import "ConConnection.h"
#import "BoxIOHIDElementRef.h"
#import "BoxBOOL.h"
#import "BoxDouble.h"
#import "ConfigHIDDevice.h"
 
#define MAX_3D_AXIS 6
#define MAX_3D_BUTTONS 8
#define MAX_POSSIBLE_HID_AXIS 6

extern ConConnection * theConnection;

@interface HIDDevice : NSObject {
	IOHIDDeviceRef deviceRef;
	NSString*		devName;
	UInt16	        countAxis;
	UInt16	        countButtons;
	NSMutableArray *hidIoRefAxis;
	NSMutableArray *valuesOfAxis;
	NSMutableArray *hidIoRefBtns;
	NSMutableArray *valuesOfButtons;
	ConfigHIDDevice *config;
}

@property (readonly, retain) __attribute__((NSObject)) IOHIDDeviceRef deviceRef;
@property (readonly, retain) NSString* devName;
@property (readonly)         UInt16	 countAxis;
@property (readonly)         UInt16	 countButtons;
@property (readonly, assign) NSMutableArray *valuesOfButtons;
@property (readonly, assign) NSMutableArray *valuesOfAxis;

+ (HIDDevice*) deviceWithRef:(IOHIDDeviceRef)ref;

- (id) initWithHIDDeviceRef:(IOHIDDeviceRef)ref;

@end
