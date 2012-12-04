/*
 *  ConfigHIDDevice.m
 *  3DconnexionClient
 *
 *  Created by Marco Köhler on 12.08.12.
 *
 */

#import "ConfigHIDDevice.h"


@implementation ConfigHIDDevice

@synthesize hidName;
@synthesize mappingButtons;
@synthesize mappingAxis;

- (ConfigHIDDevice*) init {
	return [self initWithHidName:nil andMappingButtons:nil andMappingAxis:nil];
}

- (ConfigHIDDevice*) initWithHidName:(NSString*)name andMappingButtons:(NSMutableArray*)buttons andMappingAxis:(NSMutableArray*)axis {
	self = [super init];
	if (!self) return nil;
	if (name!=nil) 
	{
		self.hidName = [[NSString alloc] initWithString:name];
	}
	else
	{
		self.hidName = nil;
	}
	if (buttons!=nil)
	{
		self.mappingButtons = [NSMutableArray arrayWithArray:buttons];
	}
	else
	{
		self.mappingButtons = nil;
	}
	if (axis!=nil)
	{
		self.mappingAxis = [NSMutableArray arrayWithArray:axis];
	}
	else
	{
		self.mappingAxis = nil;
	}
	return self;
}

- (void) dealloc {
	if (self.hidName!=nil) [self.hidName release];
	if (self.mappingButtons!=nil)
	{
		[self.mappingButtons removeAllObjects];
		[self.mappingButtons release];
	}
	if (self.mappingAxis!=nil)
	{
		[self.mappingAxis removeAllObjects];
		[self.mappingAxis release];
	}
	[super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder 
{ 
	[coder encodeObject:self.hidName forKey:@"hidName"];
	[coder encodeObject:self.mappingButtons forKey:@"mappingButtons"];
	[coder encodeObject:self.mappingAxis forKey:@"mappingAxis"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) 
	{
		self.hidName = [[decoder decodeObjectForKey:@"hidName"] retain];
		self.mappingButtons = [[decoder decodeObjectForKey:@"mappingButtons"] retain];
		self.mappingAxis = [[decoder decodeObjectForKey:@"mappingAxis"] retain];
    }
    return self;
}

@end
