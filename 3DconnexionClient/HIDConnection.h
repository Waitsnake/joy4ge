/*
 *  HIDConnection.h
 *  3DconnexionClient
 *
 *  Created by Marco Köhler on 04.08.12.
 *
 */

#import <Cocoa/Cocoa.h>
#import <IOKit/hid/IOHIDLib.h>

#import "HIDDevice.h"
#import "ConConnection.h"

extern ConConnection * theConnection;

@interface HIDConnection : NSObject {
@private
	NSArray*		plugHidDevs;
	IOHIDManagerRef hidManagerRef;
}

@property (readonly, retain) NSArray* plugHidDevs;

@end
