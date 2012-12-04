/*
 *  BoxBOOL.h
 *  3DconnexionClient
 *
 *  Created by Marco Köhler on 11.08.12.
 *
 */

#import <Cocoa/Cocoa.h>

// this class did an boxing of primitive type BOOL to an NSObject to use it inside an NSMutableArray
// because of readwrite access we also can change the primitive value inside the object, if we need it 
// (changing is not possible with NSNumber!)
@interface BoxBOOL : NSObject {
	BOOL boolValue;
}

@property (readwrite) BOOL boolValue; 

@end
