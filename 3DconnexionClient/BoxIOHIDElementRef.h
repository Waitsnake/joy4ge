/*
 *  BoxIOHIDElementRef.h
 *  3DconnexionClient
 *
 *  Created by Marco Köhler on 11.08.12.
 *
 */

#import <Cocoa/Cocoa.h>
#import <IOKit/hid/IOHIDLib.h>

// this class did an boxing of primitive type IOHIDElementRef to an NSObject to use it inside an NSMutableArray
// because of readwrite access we also can change the primitive value inside the object, if we need it
@interface BoxIOHIDElementRef : NSObject {
	IOHIDElementRef ioHidElementRef;
}

@property (readwrite) IOHIDElementRef ioHidElementRef; 

@end
