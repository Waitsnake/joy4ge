/*
 *  HIDDevice.m
 *  3DconnexionClient
 *
 *  Created by Marco Köhler on 04.08.12.
 *
 */

#import "HIDDevice.h"

@interface HIDDevice ()

@property (readwrite, retain) NSString* devName;
@property (readwrite, retain) __attribute__((NSObject)) IOHIDDeviceRef deviceRef;
@property (readwrite)         UInt16		 countAxis;
@property (readwrite)         UInt16		 countButtons;
@property (readwrite, assign) NSMutableArray *hidIoRefBtns;
@property (readwrite, assign) NSMutableArray *hidIoRefAxis;
@property (readwrite, assign) NSMutableArray *valuesOfButtons;
@property (readwrite, assign) NSMutableArray *valuesOfAxis;
@property (readwrite, assign) ConfigHIDDevice *config;

- (BOOL) findHIDlements;
- (IOHIDElementRef) findHIDElementWithType:(IOHIDElementType)type
							  andUsagePage:(uint32_t)usagePage
								  andUsage:(uint32_t)usage;
- (void) startListeningOfDevice;
- (void) stopListeningOfDevice;
- (void) valueReceived:(IOHIDValueRef)value;
- (UInt16) countHIDButtons;
- (UInt16) countHIDAxis;
- (BOOL) getButtonValueAt:(UInt16)index;
- (double) getAxisValueAt:(UInt16)index;
- (void) loadConfigOfDevice;

@end

void valueCallback(void* context, IOReturn result, void* sender, IOHIDValueRef value) {
	if (context == NULL) return;
	if (result) return;
	HIDDevice* device = (HIDDevice*)context;
	[device valueReceived:value];
}

@implementation HIDDevice

@synthesize deviceRef;
@synthesize devName;
@synthesize countAxis; // number of detected Axis
@synthesize countButtons; // number of detected HID valuesOfButtons
@synthesize hidIoRefBtns; // Array of HID io element references
@synthesize valuesOfButtons; // Array of BOOL with state of pressed button(NO or YES)
@synthesize hidIoRefAxis; // Array of HID io element references
@synthesize valuesOfAxis; // Array of double with state of axis position(between -1..0..1)
@synthesize config;

+ (HIDDevice*) deviceWithRef:(IOHIDDeviceRef)ref {
	return [[[HIDDevice alloc] initWithHIDDeviceRef:ref] autorelease];
}

- (id) initWithHIDDeviceRef:(IOHIDDeviceRef)ref {
	self = [super init];
	if (!self) return nil;
	self.config = nil;
	self.deviceRef = ref;
	self.countButtons = 0;
	self.valuesOfButtons = [[NSMutableArray alloc] initWithCapacity:1];
	self.hidIoRefBtns = [[NSMutableArray alloc] initWithCapacity:1];
	self.countAxis = 0;
	self.valuesOfAxis = [[NSMutableArray alloc] initWithCapacity:1];
	self.hidIoRefAxis = [[NSMutableArray alloc] initWithCapacity:1];
	self.devName = (NSString*)IOHIDDeviceGetProperty(self.deviceRef, CFSTR(kIOHIDProductKey));
	BOOL found = [self findHIDlements];
	if (!found) {
		[self release];
		return nil;
	}
	[self loadConfigOfDevice];
	[self startListeningOfDevice];
	return self;
}

- (void) loadConfigOfDevice
{
	BOOL foundConfig = NO;
	
	// default configuration
	self.config = [[ConfigHIDDevice alloc] initWithHidName:self.devName 
										 andMappingButtons:[NSMutableArray arrayWithObjects:
															[ConfigButton configButtonWithBtnIdx:0 andType:1 andHidBtnIdx:4],
															[ConfigButton configButtonWithBtnIdx:1 andType:1 andHidBtnIdx:5],
															nil]
											andMappingAxis:[NSMutableArray arrayWithObjects:
															[ConfigAxis configAxisWithAxisIdx:0 andType:2 andMapScale: 500 andMinAxBtnIdx:0 andMaxAxBtnIdx:0 andHidAxisIdx:0 andDeadZnMin:-0.25 andDeadZnMax:0.25],
															[ConfigAxis configAxisWithAxisIdx:1 andType:2 andMapScale:-500 andMinAxBtnIdx:0 andMaxAxBtnIdx:0 andHidAxisIdx:1 andDeadZnMin:-0.15 andDeadZnMax:0.25],
															[ConfigAxis configAxisWithAxisIdx:2 andType:1 andMapScale: 100 andMinAxBtnIdx:0 andMaxAxBtnIdx:2 andHidAxisIdx:0 andDeadZnMin: 0.0  andDeadZnMax:0.0 ],
															[ConfigAxis configAxisWithAxisIdx:2 andType:1 andMapScale: 500 andMinAxBtnIdx:3 andMaxAxBtnIdx:1 andHidAxisIdx:0 andDeadZnMin: 0.0  andDeadZnMax:0.0 ],
															[ConfigAxis configAxisWithAxisIdx:3 andType:2 andMapScale: 500 andMinAxBtnIdx:0 andMaxAxBtnIdx:0 andHidAxisIdx:2 andDeadZnMin:-0.28 andDeadZnMax:0.15],
															[ConfigAxis configAxisWithAxisIdx:5 andType:2 andMapScale:-500 andMinAxBtnIdx:0 andMaxAxBtnIdx:0 andHidAxisIdx:3 andDeadZnMin:-0.25 andDeadZnMax:0.15],
															nil]];
	
	// create path of application support directory
	NSString *appSuppDir = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex: 0] stringByAppendingPathComponent: @"3DConnexionClient"];
	// create Application Support Directory if it is not exsisting
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:appSuppDir] == NO) [fileManager createDirectoryAtPath:appSuppDir withIntermediateDirectories:YES attributes:nil error:nil];
	// create file name of config file
	NSString *appSuppFile = [appSuppDir stringByAppendingPathComponent:@"controller.config.plist"];
	
	// load configuration (an array of configs for different devices)
	NSData* arrayData = [NSData dataWithContentsOfFile:appSuppFile];
	NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:arrayData];
	NSMutableArray *configs = [unarchiver decodeObjectForKey:@"ConfigArray"];
	if ((arrayData != nil) && (unarchiver != nil) && (configs != nil))
	{
		// search for correct config
		for(ConfigHIDDevice *devConf in configs)
		{
			if ([devConf.hidName isEqualToString:self.devName] == YES)
			{
				NSLog(@"found config in file for: %@",devConf.hidName);
				// deleate default config
				[self.config release];
				// use config from file
				self.config = devConf;
				[self.config retain];
				foundConfig = YES;
			}
		}
		if (foundConfig == NO)
		{
			NSLog(@"no config in file found for: %@",self.devName);
			// add default config to config array
			[configs addObject:self.config];
			// save extended conif array to file
			NSMutableData *data = [NSMutableData new];
			NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
			[archiver setOutputFormat:NSPropertyListXMLFormat_v1_0];
			[archiver encodeObject:configs forKey:@"ConfigArray"];
			[archiver finishEncoding];
			[data writeToFile:appSuppFile atomically:YES];
			[archiver release];
			[data release];
			NSLog(@"add an default confiuration to file");
		}
	}
	else
	{
		NSLog(@"no config file found");
		// safe a new configuration with default values
		NSMutableData *data = [NSMutableData new];
		NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
		[archiver setOutputFormat:NSPropertyListXMLFormat_v1_0];
		NSMutableArray *hidConfigs = [[NSMutableArray alloc] initWithObjects:self.config, nil];
		[archiver encodeObject:hidConfigs forKey:@"ConfigArray"];
		[archiver finishEncoding];
		[data writeToFile:appSuppFile atomically:YES];
		[hidConfigs release];
		[archiver release];
		[data release];
		NSLog(@"create an new file with an default confiuration for %@",self.devName);
	}
	[unarchiver release];
}

- (void) dealloc {
	// if an HID device is removed than send event to all clients that none of the axis is rotating 
	for(ConClient *cl in theConnection.connectedClients)
	{
		ConnexionDeviceState event;
		event.version = kConnexionDeviceStateVers;
		event.client = cl.clientID;
		event.command = kConnexionCmdHandleAxis;
		event.axis[0] = 0;
		event.axis[1] = 0;
		event.axis[2] = 0;
		event.axis[3] = 0;
		event.axis[4] = 0;
		event.axis[5] = 0;
		if (theConnection.messageHandler != NULL) theConnection.messageHandler(theConnection.connectionID,kConnexionMsgDeviceState,&event);
	}
	[self stopListeningOfDevice];
	self.devName = nil;
	self.deviceRef = NULL;
	[self.valuesOfAxis removeAllObjects];
	[self.valuesOfAxis release];
	[self.hidIoRefAxis removeAllObjects];
	[self.hidIoRefAxis release];
	[self.valuesOfButtons removeAllObjects];
	[self.valuesOfButtons release];
	[self.hidIoRefBtns removeAllObjects];
	[self.hidIoRefBtns release];
	if (self.config != nil) [self.config release];
	[super dealloc];
}

- (NSString*) description {
	return [NSString stringWithFormat:@"%@",self.devName];
}

- (BOOL) findHIDlements {	
	// find valuesOfAxis of HID device
	self.countAxis = [self countHIDAxis];
	for (UInt16 i=kHIDUsage_GD_X;i<MAX_POSSIBLE_HID_AXIS+kHIDUsage_GD_X;i++)
	{
		// create array with ioHidElementRef references of the axis
		BoxIOHIDElementRef *refObj = [[BoxIOHIDElementRef alloc] init];
		refObj.ioHidElementRef = [self findHIDElementWithType:kIOHIDElementTypeInput_Misc
												 andUsagePage:kHIDPage_GenericDesktop
													 andUsage:i];
		// check if this axis really exists (hools possible between kHIDUsage_GD_X and kHIDUsage_GD_Rz !!)
		if (refObj.ioHidElementRef != NULL)
		{
			[self.hidIoRefAxis addObject:refObj];
			
			// create also an array of double valuesOfAxis thats will hold the actual state
			BoxDouble *doubleObj = [[BoxDouble alloc] init];
			doubleObj.doubleValue = 0.0;
			[self.valuesOfAxis addObject:doubleObj];
			[doubleObj release];
		}
		
		[refObj release];

	}
	
	// find valuesOfButtons of HID device
	self.countButtons = [self countHIDButtons];
	for (UInt16 i=1;i<self.countButtons+1;i++)
	{
		// create array with ioHidElementRef references of the buttons
		BoxIOHIDElementRef *refObj = [[BoxIOHIDElementRef alloc] init];
		refObj.ioHidElementRef = [self findHIDElementWithType:kIOHIDElementTypeInput_Button
												andUsagePage:kHIDPage_Button
													andUsage:i];
		[self.hidIoRefBtns addObject:refObj];
		[refObj release];
		
		// create also an array of BOOL valuesOfButtons thats will hold the actual state
		BoxBOOL *boolObj = [[BoxBOOL alloc] init];
		boolObj.boolValue = NO;
		[self.valuesOfButtons addObject:boolObj];
		[boolObj release];

	}		
	
	return (self.countAxis>0 && self.countButtons>0) ? YES : NO;
}

- (BOOL) getButtonValueAt:(UInt16)index
{
	if (index >= self.countButtons)
	{
		return NO;
	}
	else
	{
		return [[self.valuesOfButtons objectAtIndex:index] boolValue];
	}
}

- (double) getAxisValueAt:(UInt16)index
{
	if (index >= self.countAxis)
	{
		return 0.0;
	}
	else
	{
		return [[self.valuesOfAxis objectAtIndex:index] doubleValue];
	}
}

- (UInt16) countHIDButtons
{
	UInt16 foundButtons = 0;
	NSDictionary* matchDict = [NSDictionary dictionaryWithObjectsAndKeys:
							   [NSNumber numberWithInt:kIOHIDElementTypeInput_Button],	@kIOHIDElementTypeKey,
							   [NSNumber numberWithInt:kHIDPage_Button],				@kIOHIDElementUsagePageKey,
							   nil];
	CFArrayRef elements = IOHIDDeviceCopyMatchingElements(self.deviceRef, (CFDictionaryRef)matchDict, 0);
	if (!elements) return 0;
	foundButtons = CFArrayGetCount(elements);
	CFRelease(elements);
	return foundButtons;
}

- (UInt16) countHIDAxis
{
	UInt16 foundMiscElements = 0;
	UInt16 foundAxis = 0;
	uint32_t usage = 0;
	NSDictionary* matchDict = [NSDictionary dictionaryWithObjectsAndKeys:
							   [NSNumber numberWithInt:kIOHIDElementTypeInput_Misc],	@kIOHIDElementTypeKey,
							   [NSNumber numberWithInt:kHIDPage_GenericDesktop],		@kIOHIDElementUsagePageKey,
							   nil];
	CFArrayRef elements = IOHIDDeviceCopyMatchingElements(self.deviceRef, (CFDictionaryRef)matchDict, 0);
	if (!elements) return 0;
	foundMiscElements = CFArrayGetCount(elements);
	
	for(UInt16 i=0;i<foundMiscElements; i++)
	{
		usage = IOHIDElementGetUsage((IOHIDElementRef)CFArrayGetValueAtIndex(elements,i));
		switch(usage)
		{
			case kHIDUsage_GD_X:
				foundAxis++;
				break;
			case kHIDUsage_GD_Y:
				foundAxis++;
				break;
			case kHIDUsage_GD_Z:
				foundAxis++;
				break;
			case kHIDUsage_GD_Rx:
				foundAxis++;
				break;
			case kHIDUsage_GD_Ry:
				foundAxis++;
				break;
			case kHIDUsage_GD_Rz:
				foundAxis++;
				break;
			default:
				break;
		}
	}
	
	CFRelease(elements);
	return foundAxis;
}

- (IOHIDElementRef) findHIDElementWithType:(IOHIDElementType)type
							  andUsagePage:(uint32_t)usagePage
								  andUsage:(uint32_t)usage {
	NSDictionary* matchDict = [NSDictionary dictionaryWithObjectsAndKeys:
							   [NSNumber numberWithInt:type],		@kIOHIDElementTypeKey,
							   [NSNumber numberWithInt:usagePage],	@kIOHIDElementUsagePageKey,
							   [NSNumber numberWithInt:usage],		@kIOHIDElementUsageKey,
							   nil];
	CFArrayRef elements = IOHIDDeviceCopyMatchingElements(self.deviceRef, (CFDictionaryRef)matchDict, 0);
	if (!elements) return NULL;
	if (CFArrayGetCount(elements) < 0) 
	{
		CFRelease(elements);
		return NULL;
	}
	IOHIDElementRef element = (IOHIDElementRef)CFArrayGetValueAtIndex(elements, 0);
	CFRelease(elements);
	return element;
}

- (void) startListeningOfDevice {
	IOReturn err = IOHIDDeviceOpen(self.deviceRef, 0);
    // on older GE versions getting HID device gives only back kIOReturnSuccess,
    // but newer versions of GE try to get the same HID exclusive as well and so we get herekIOReturnExclusiveAccess instead
	NSAssert((err==kIOReturnSuccess)||(err=kIOReturnExclusiveAccess),@"IOHIDDeviceOpen failed err = %16.16llX",(uint64_t)err);
    
	// build array of dictionary entries for all valuesOfAxis				   
	NSMutableArray* axisArray = [[NSMutableArray alloc] initWithCapacity:1];
	for(UInt16 i=0;i<self.countAxis;i++)
	{
		[axisArray addObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:(unsigned int)IOHIDElementGetCookie([[self.hidIoRefAxis objectAtIndex:i] ioHidElementRef])] forKey:@ kIOHIDElementCookieKey]];
	}
	// build array of dictionary entries for all valuesOfButtons					   
	NSMutableArray* buttonArray = [[NSMutableArray alloc] initWithCapacity:1];
	for(UInt16 i=0;i<self.countButtons;i++)
	{
		[buttonArray addObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:(unsigned int)IOHIDElementGetCookie([[self.hidIoRefBtns objectAtIndex:i] ioHidElementRef])] forKey:@ kIOHIDElementCookieKey]];
	}
	// concat array of axis and valuesOfButtons in one match array 
	NSArray* matchArray = [axisArray arrayByAddingObjectsFromArray:buttonArray];
	[axisArray release];
	[buttonArray release];
	
	IOHIDDeviceSetInputValueMatchingMultiple(self.deviceRef, (CFArrayRef)matchArray);	
	IOHIDDeviceRegisterInputValueCallback(self.deviceRef, valueCallback, self);
}

- (void) stopListeningOfDevice {
	IOHIDDeviceClose(self.deviceRef, 0);
}



- (void) valueReceived:(IOHIDValueRef)value {
	IOHIDElementRef element = IOHIDValueGetElement(value);
	CFIndex unscaled = IOHIDValueGetIntegerValue(value);
	CFIndex min = IOHIDElementGetLogicalMin(element);
	CFIndex max = IOHIDElementGetLogicalMax(element);
	double scaled = ((double)unscaled-(double)min)/((double)max-(double)min)*2.0-1.0;
	unsigned short int buttonMask[MAX_3D_BUTTONS] = {kConnexionMaskButton1,kConnexionMaskButton2,kConnexionMaskButton3,kConnexionMaskButton4,kConnexionMaskButton5,kConnexionMaskButton6,kConnexionMaskButton7,kConnexionMaskButton8};
	unsigned short int axisMask[MAX_3D_AXIS] = {kConnexionMaskAxis1,kConnexionMaskAxis2,kConnexionMaskAxis3,kConnexionMaskAxis4,kConnexionMaskAxis5,kConnexionMaskAxis6};
		
	// check IOHIDElementRef of received HID event for all valuesOfAxis we have
	for(UInt16 i=0;i<self.countAxis;i++)
	{
		if (element==[[self.hidIoRefAxis objectAtIndex:i] ioHidElementRef]) 
		{
			
			[[self.valuesOfAxis objectAtIndex:i] setDoubleValue:scaled];
		}
	}
	
	// check IOHIDElementRef of received HID event for all valuesOfButtons we have
	for(UInt16 i=0;i<self.countButtons;i++)
	{
		if (element==[[self.hidIoRefBtns objectAtIndex:i] ioHidElementRef]) 
		{
		
			[[self.valuesOfButtons objectAtIndex:i] setBoolValue:unscaled];
		}
	}
	
	// make remapping of HID events to 3D mouse events and send them to 3D mouse interface (for all registered client connections)
	for(ConClient *cl in theConnection.connectedClients)
	{
		// valuesOfButtons of 3D mouse seems to be ignorred by google earth
		ConnexionDeviceState button_event;
        memset(&button_event,0,sizeof(button_event));
		button_event.buttons = 0;
		button_event.version = kConnexionDeviceStateVers;
		button_event.client = cl.clientID;
		button_event.command = kConnexionCmdHandleButtons;
		// check now all button configurations of device and map them
		for(ConfigButton *bt in self.config.mappingButtons)
		{
			switch([bt.hidMappingType unsignedIntValue])
			{
				case BtnMappingNone:
					break;
				case BtnMappingButton:
					if (([self getButtonValueAt:[bt.hidButtonIndex unsignedIntValue]] == YES) && ([bt.buttonIndex unsignedIntValue] < MAX_3D_BUTTONS))
					{
						if(cl.mask || buttonMask[[bt.buttonIndex unsignedIntValue]]) button_event.buttons |= buttonMask[[bt.buttonIndex unsignedIntValue]];
					}
					break;
				default:
					break;
			}
		}
		if (theConnection.messageHandler != NULL && button_event.buttons != 0)
        {
            theConnection.messageHandler(theConnection.connectionID,kConnexionMsgDeviceState,&button_event);
        }
		
		
		// google earth handle axis x,y,z,rx and rz (only ry is ignored)
		ConnexionDeviceState axis_event;
        memset(&axis_event,0,sizeof(axis_event));
		axis_event.client = cl.clientID;
		axis_event.version = kConnexionDeviceStateVers;
		axis_event.command = kConnexionCmdHandleAxis;
		// check now all axis configurations of device and map them
		for(ConfigAxis *ax in self.config.mappingAxis)
		{
			switch([ax.hidMappingType unsignedIntValue])
			{
				case AxisMappingNone:
					break;
				case AxisMappingButton:
					if ([ax.axisIndex unsignedIntValue] < MAX_3D_AXIS)
					{
						if ([self getButtonValueAt:[ax.hidMaxAxisButtonIndex unsignedIntValue]] == YES)
						{
							if(cl.mask || axisMask[[ax.axisIndex unsignedIntValue]])
                            {
                                axis_event.axis[[ax.axisIndex unsignedIntValue]] = [ax.hidMappingScale intValue];
                                /*
                                NSLog(@"Axis(Button Max) index %i %i",
                                      [ax.hidAxisIndex unsignedIntValue],
                                      [ax.hidMaxAxisButtonIndex unsignedIntValue]
                                      );
                                */
                            }
						}
						else if ([self getButtonValueAt:[ax.hidMinAxisButtonIndex unsignedIntValue]] == YES)
						{
							if(cl.mask || axisMask[[ax.axisIndex unsignedIntValue]])
                            {
                                axis_event.axis[[ax.axisIndex unsignedIntValue]] = -[ax.hidMappingScale intValue];
                                /*
                                NSLog(@"Axis(Button Min) index %i %i",
                                      [ax.hidAxisIndex unsignedIntValue],
                                      [ax.hidMinAxisButtonIndex unsignedIntValue]
                                      );
                                 */
                            }
						}
					}
					break;
				case AxisMappingAxis:
					if ([ax.axisIndex unsignedIntValue] < MAX_3D_AXIS)
					{
						if ([self getAxisValueAt:[ax.hidAxisIndex unsignedIntValue]] > [ax.hidDeadZoneMax floatValue] || [self getAxisValueAt:[ax.hidAxisIndex unsignedIntValue]] < [ax.hidDeadZoneMin floatValue])
						{
							if(cl.mask || axisMask[[ax.axisIndex unsignedIntValue]])
                            {
                                axis_event.axis[[ax.axisIndex unsignedIntValue]] = [ax.hidMappingScale intValue]*[self getAxisValueAt:[ax.hidAxisIndex unsignedIntValue]];
                                /*
                                NSLog(@"Axis(Analog) index %i mapped axis %5.2f/%5.2f %5.2f/%5.2f",
                                      [ax.hidAxisIndex unsignedIntValue],
                                      [self getAxisValueAt:[ax.hidAxisIndex unsignedIntValue]],
                                      [ax.hidDeadZoneMax floatValue],
                                      [self getAxisValueAt:[ax.hidAxisIndex unsignedIntValue]],
                                      [ax.hidDeadZoneMin floatValue]
                                      );
                                 */
                            }
						}
					}
					break;
				default:
					break;
			}
			
		}
        if (theConnection.messageHandler != NULL){
            theConnection.messageHandler(theConnection.connectionID,kConnexionMsgDeviceState,&axis_event);

            /*
            NSLog(@"ID:%4.4X %@ axis %5.2f/%5.2f %5.2f/%5.2f %5.2f/%5.2f buttons %i %i %i %i %i %i %i %i %i %i %i %i", theConnection.connectionID, self.devName,
                  [self getAxisValueAt:0],[self getAxisValueAt:1],
                  [self getAxisValueAt:2],[self getAxisValueAt:3],
                  [self getAxisValueAt:4],[self getAxisValueAt:5],
                  [self getButtonValueAt:0], [self getButtonValueAt:1],
                  [self getButtonValueAt:2], [self getButtonValueAt:3],
                  [self getButtonValueAt:4], [self getButtonValueAt:5],
                  [self getButtonValueAt:6], [self getButtonValueAt:7],
                  [self getButtonValueAt:8], [self getButtonValueAt:9],
                  [self getButtonValueAt:10], [self getButtonValueAt:11]
                  );
             */
        }
		 
	}
}

@end
