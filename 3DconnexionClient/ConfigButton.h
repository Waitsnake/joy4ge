/*
 *  ConfigButton.h
 *  3DconnexionClient
 *
 *  Created by Marco Köhler on 12.08.12.
 *
 */

#import <Cocoa/Cocoa.h>

typedef enum {
	BtnMappingNone,
	BtnMappingButton
} T_BtnMappingType;

@interface ConfigButton : NSObject {
	// the button index of the 3D mouse (where we map to)
	NSNumber	*buttonIndex;
	// Define if we map a Button=1 or None=0 to an 3D mouse button
	NSNumber	*hidMappingType;
	NSNumber	*hidButtonIndex;
}
@property (readwrite, retain) NSNumber *buttonIndex; 
@property (readwrite, retain) NSNumber *hidMappingType; 
@property (readwrite, retain) NSNumber *hidButtonIndex; 

+ (ConfigButton*) configButtonWithBtnIdx:(unsigned int)btnIdx
								 andType:(unsigned int)type 
							andHidBtnIdx:(unsigned int)hidBtnIdx;

- (ConfigButton*) initWithBtnIdx:(unsigned int)btnIdx
						 andType:(unsigned int)type 
					andHidBtnIdx:(unsigned int)hidBtnIdx;

@end
