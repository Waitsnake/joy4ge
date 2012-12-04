/*
 *  ConfigButton.m
 *  3DconnexionClient
 *
 *  Created by Marco Köhler on 12.08.12.
 *
 */

#import "ConfigButton.h"

@implementation ConfigButton
@synthesize buttonIndex;
@synthesize hidMappingType;
@synthesize hidButtonIndex;

+ (ConfigButton*) configButtonWithBtnIdx:(unsigned int)btnIdx
								 andType:(unsigned int)type 
							andHidBtnIdx:(unsigned int)hidBtnIdx
{
	return [[[ConfigButton alloc] initWithBtnIdx:btnIdx
										 andType:type 
									andHidBtnIdx:hidBtnIdx] autorelease];
}

- (ConfigButton*) init
{
	return [self initWithBtnIdx:0 andType:BtnMappingNone andHidBtnIdx:0];
}

- (ConfigButton*) initWithBtnIdx:(unsigned int)btnIdx
						 andType:(unsigned int)type 
					andHidBtnIdx:(unsigned int)hidBtnIdx
{
	self = [super init];
	if (!self) return nil;
	self.buttonIndex = [[NSNumber alloc] initWithUnsignedInt:btnIdx];
	self.hidMappingType = [[NSNumber alloc] initWithUnsignedInt:type];
	self.hidButtonIndex = [[NSNumber alloc] initWithUnsignedInt:hidBtnIdx];
	return self;
}

- (void) dealloc {
	[self.buttonIndex release];
	[self.hidMappingType release];
	[self.hidButtonIndex release];
	[super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder 
{ 
	[coder encodeInt:[buttonIndex unsignedIntValue] forKey:@"buttonIndex"];
    [coder encodeInt:[hidMappingType unsignedIntValue] forKey:@"hidMappingType"];
	[coder encodeInt:[hidButtonIndex unsignedIntValue] forKey:@"hidButtonIndex"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
		self.buttonIndex = [NSNumber numberWithUnsignedInt:[decoder decodeIntForKey:@"buttonIndex"]];
        self.hidMappingType = [NSNumber numberWithUnsignedInt:[decoder decodeIntForKey:@"hidMappingType"]];
		self.hidButtonIndex = [NSNumber numberWithUnsignedInt:[decoder decodeIntForKey:@"hidButtonIndex"]];
    }
    return self;
}

@end
