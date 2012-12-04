/*
 *  ConfigHIDDevice.h
 *  3DconnexionClient
 *
 *  Created by Marco Köhler on 12.08.12.
 *
 */

#import <Cocoa/Cocoa.h>

#import "ConfigAxis.h"
#import "ConfigButton.h"

@interface ConfigHIDDevice : NSObject {
	// name of HID device for witch this configuration is valid
	NSString	*hidName;
	
	// mapping array contains the configurated buttons
	NSMutableArray		*mappingButtons;
	
	// mapping array contains the configurated axis
	NSMutableArray		*mappingAxis; 
}

@property (readwrite, retain) NSString			*hidName;
@property (readwrite, retain) NSMutableArray	*mappingButtons;
@property (readwrite, retain) NSMutableArray	*mappingAxis;

- (ConfigHIDDevice*) initWithHidName:(NSString*)name andMappingButtons:(NSMutableArray*)buttons andMappingAxis:(NSMutableArray*)axis;

@end
