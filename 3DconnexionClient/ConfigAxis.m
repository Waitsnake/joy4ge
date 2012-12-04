/*
 *  ConfigAxis.m
 *  3DconnexionClient
 *
 *  Created by Marco Köhler on 12.08.12.
 *
 */

#import "ConfigAxis.h"


@implementation ConfigAxis
@synthesize axisIndex;
@synthesize hidMappingType;
@synthesize hidMappingScale;
@synthesize hidMinAxisButtonIndex;
@synthesize hidMaxAxisButtonIndex;
@synthesize hidAxisIndex;
@synthesize hidDeadZoneMin;
@synthesize hidDeadZoneMax;

+ (ConfigAxis*) configAxisWithAxisIdx:(unsigned int)axisIdx
							  andType:(unsigned int)mapType 
						  andMapScale:(int)mapScale
					   andMinAxBtnIdx:(unsigned int)minAxBtnIdx
					   andMaxAxBtnIdx:(unsigned int)maxAxBtnIdx
						andHidAxisIdx:(unsigned int)hidAxisIdx
						 andDeadZnMin:(float)deadZnMin
						 andDeadZnMax:(float)deadZnMax
{
	return [[[ConfigAxis alloc] initWithAxisIdx:(unsigned int)axisIdx
										andType:(unsigned int)mapType 
									andMapScale:(int)mapScale
								 andMinAxBtnIdx:(unsigned int)minAxBtnIdx
								 andMaxAxBtnIdx:(unsigned int)maxAxBtnIdx
								  andHidAxisIdx:(unsigned int)hidAxisIdx
								   andDeadZnMin:(float)deadZnMin
								   andDeadZnMax:(float)deadZnMax] autorelease];
}

- (ConfigAxis*) init
{
	return [self initWithAxisIdx:0 andType:AxisMappingNone andMapScale:1 andMinAxBtnIdx:0 andMaxAxBtnIdx:0 andHidAxisIdx:0 andDeadZnMin:0.0 andDeadZnMax:0.0];
}

- (ConfigAxis*) initWithAxisIdx:(unsigned int)axisIdx
						andType:(unsigned int)mapType 
					andMapScale:(int)mapScale
				 andMinAxBtnIdx:(unsigned int)minAxBtnIdx
				 andMaxAxBtnIdx:(unsigned int)maxAxBtnIdx
				  andHidAxisIdx:(unsigned int)hidAxisIdx
				   andDeadZnMin:(float)deadZnMin
				   andDeadZnMax:(float)deadZnMax
{
	self = [super init];
	if (!self) return nil;
	self.axisIndex = [[NSNumber alloc] initWithUnsignedInt:axisIdx];
	self.hidMappingType = [[NSNumber alloc] initWithUnsignedInt:mapType];
	self.hidMappingScale = [[NSNumber alloc] initWithInt:mapScale];
	self.hidMinAxisButtonIndex = [[NSNumber alloc] initWithUnsignedInt:minAxBtnIdx];
	self.hidMaxAxisButtonIndex = [[NSNumber alloc] initWithUnsignedInt:maxAxBtnIdx];
	self.hidAxisIndex = [[NSNumber alloc] initWithUnsignedInt:hidAxisIdx];
	self.hidDeadZoneMin = [[NSNumber alloc] initWithFloat:deadZnMin];
	self.hidDeadZoneMax = [[NSNumber alloc] initWithFloat:deadZnMax];	
	return self;
}

- (void) dealloc {
	[self.axisIndex release];
	[self.hidMappingType release];
	[self.hidMappingScale release];
	[self.hidMinAxisButtonIndex release];
	[self.hidMaxAxisButtonIndex release];
	[self.hidAxisIndex release];
	[self.hidDeadZoneMin release];
	[self.hidDeadZoneMax release];
	[super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder 
{ 
	[coder encodeInt:[axisIndex unsignedIntValue] forKey:@"axisIndex"];
    [coder encodeInt:[hidMappingType unsignedIntValue] forKey:@"hidMappingType"];
	[coder encodeInt:[hidMappingScale intValue] forKey:@"hidMappingScale"];
	[coder encodeInt:[hidMinAxisButtonIndex unsignedIntValue] forKey:@"hidMinAxisButtonIndex"];
	[coder encodeInt:[hidMaxAxisButtonIndex unsignedIntValue] forKey:@"hidMaxAxisButtonIndex"];
	[coder encodeInt:[hidAxisIndex unsignedIntValue] forKey:@"hidAxisIndex"];
	[coder encodeFloat:[hidDeadZoneMin floatValue] forKey:@"hidDeadZoneMin"];
	[coder encodeFloat:[hidDeadZoneMax floatValue] forKey:@"hidDeadZoneMax"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
		self.axisIndex = [NSNumber numberWithUnsignedInt:[decoder decodeIntForKey:@"axisIndex"]];
        self.hidMappingType = [NSNumber numberWithUnsignedInt:[decoder decodeIntForKey:@"hidMappingType"]];
		self.hidMappingScale = [NSNumber numberWithInt:[decoder decodeIntForKey:@"hidMappingScale"]];
		self.hidMinAxisButtonIndex = [NSNumber numberWithUnsignedInt:[decoder decodeIntForKey:@"hidMinAxisButtonIndex"]];
		self.hidMaxAxisButtonIndex = [NSNumber numberWithUnsignedInt:[decoder decodeIntForKey:@"hidMaxAxisButtonIndex"]];
		self.hidAxisIndex = [NSNumber numberWithUnsignedInt:[decoder decodeIntForKey:@"hidAxisIndex"]];
		self.hidDeadZoneMin = [NSNumber numberWithFloat:[decoder decodeFloatForKey:@"hidDeadZoneMin"]];
		self.hidDeadZoneMax = [NSNumber numberWithFloat:[decoder decodeFloatForKey:@"hidDeadZoneMax"]];
    }
    return self;
}
@end
