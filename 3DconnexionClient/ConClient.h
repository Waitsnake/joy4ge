/*
 *  ConClient.h
 *  3DconnexionClient
 *
 *  Created by Marco Köhler on 08.08.12.
 *
 */

#import <Cocoa/Cocoa.h>

@interface ConClient : NSObject {
	UInt16 clientID;
	UInt32 mask;
	UInt32 signature; // not implemented
	UInt16 mode; // partly implemented
	NSString *name; // not implemented
}

@property (readwrite) UInt16 clientID; 
@property (readwrite) UInt32 mask; 
@property (readwrite) UInt16 mode; 
@property (readwrite) UInt32 signature;
@property (readwrite, retain) NSString *name;

- (id) initWithClientID:(UInt16)newClientID andMask:(UInt32)newMask andMode:(UInt16)newMode andSignature:(UInt32)newSignature andName:(NSString*)newName;

@end
