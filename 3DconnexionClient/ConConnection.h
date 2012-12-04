/*
 *  ConConnection.h
 *  3DconnexionClient
 *
 *  Created by Marco Köhler on 10.08.12.
 *
 */

#import <Cocoa/Cocoa.h>
#import "ConClient.h"
#import "ConnexionClientAPI.h"

#define NO_CON_ID		0
#define NO_CLIENT_ID	0

@interface ConConnection : NSObject {
	io_connect_t connectionID;
	NSMutableArray *connectedClients;
	ConnexionMessageHandlerProc messageHandler;
	ConnexionAddedHandlerProc  addedHandler;
	ConnexionRemovedHandlerProc  removedHandler;
}

@property (readwrite, retain) NSMutableArray*		connectedClients;
@property (readwrite) ConnexionMessageHandlerProc	messageHandler;
@property (readwrite) ConnexionAddedHandlerProc		addedHandler;
@property (readwrite) ConnexionRemovedHandlerProc	removedHandler;
@property (readwrite) io_connect_t					connectionID;

- (ConConnection*) initWithConnectionID:(io_connect_t)conID 
						  andMsgHandler:(ConnexionMessageHandlerProc)msgHand 
						  andAddHandler:(ConnexionAddedHandlerProc)addHand 
						  andRemHandler: (ConnexionRemovedHandlerProc)remHand;
- (UInt16) addClientWithMask:(UInt32)newMask 
					 andMode:(UInt16)newMode 
				andSignature:(UInt32)newSignature 
					 andName:(NSString*)newName;
- (void) removeClient: (ConClient*) clientObj;
- (UInt16) foundFreeClientID;

@end
