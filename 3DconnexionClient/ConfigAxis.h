/*
 *  ConfigAxis.h
 *  3DconnexionClient
 *
 *  Created by Marco Köhler on 12.08.12.
 *
 */

#import <Cocoa/Cocoa.h>

typedef enum {
	AxisMappingNone,
	AxisMappingButton,
	AxisMappingAxis,
} T_AxisMappingType;

@interface ConfigAxis : NSObject {
	// the axis index of the 3D mouse (where we map to)
	NSNumber	*axisIndex;
	// Define if we map two Buttons=1 or an Axis=2 or None=0 to an 3D mouse axis
	NSNumber	*hidMappingType;
	
	// Scaling factor that is applied to the mapped axis or buttons
	NSNumber	*hidMappingScale;
	
	// if we map two buttons to the 3D mouse axis we define this here
	NSNumber	*hidMinAxisButtonIndex;
	NSNumber	*hidMaxAxisButtonIndex;

	// if we map an axis we define this here
	NSNumber	*hidAxisIndex;
	NSNumber	*hidDeadZoneMin;
	NSNumber	*hidDeadZoneMax;
}

@property (readwrite, retain) NSNumber	*axisIndex;
@property (readwrite, retain) NSNumber	*hidMappingType;
@property (readwrite, retain) NSNumber	*hidMappingScale;
@property (readwrite, retain) NSNumber	*hidMinAxisButtonIndex;
@property (readwrite, retain) NSNumber	*hidMaxAxisButtonIndex;
@property (readwrite, retain) NSNumber	*hidAxisIndex;
@property (readwrite, retain) NSNumber	*hidDeadZoneMin;
@property (readwrite, retain) NSNumber	*hidDeadZoneMax;

+ (ConfigAxis*) configAxisWithAxisIdx:(unsigned int)axisIdx
							  andType:(unsigned int)mapType 
						  andMapScale:(int)mapScale
					   andMinAxBtnIdx:(unsigned int)minAxBtnIdx
					   andMaxAxBtnIdx:(unsigned int)maxAxBtnIdx
						andHidAxisIdx:(unsigned int)hidAxisIdx
						 andDeadZnMin:(float)deadZnMin
						 andDeadZnMax:(float)deadZnMax;

- (ConfigAxis*) initWithAxisIdx:(unsigned int)axisIdx
						andType:(unsigned int)mapType 
					andMapScale:(int)mapScale
				 andMinAxBtnIdx:(unsigned int)minAxBtnIdx
				 andMaxAxBtnIdx:(unsigned int)maxAxBtnIdx
				  andHidAxisIdx:(unsigned int)hidAxisIdx
				   andDeadZnMin:(float)deadZnMin
				   andDeadZnMax:(float)deadZnMax;

@end
