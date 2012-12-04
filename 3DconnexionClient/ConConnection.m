/*
 *  ConConnection.m
 *  3DconnexionClient
 *
 *  Created by Marco Köhler on 10.08.12.
 *
 */

#import "ConConnection.h"

@implementation ConConnection

@synthesize connectionID;
@synthesize connectedClients;
@synthesize messageHandler;
@synthesize addedHandler;
@synthesize removedHandler;

- (ConConnection*) init
{
	return [self initWithConnectionID:NO_CON_ID andMsgHandler:NULL andAddHandler:NULL andRemHandler:NULL];
}

- (ConConnection*) initWithConnectionID: (io_connect_t) conID andMsgHandler: (ConnexionMessageHandlerProc) msgHand andAddHandler: (ConnexionAddedHandlerProc) addHand andRemHandler: (ConnexionRemovedHandlerProc) remHand
{
	/* first initialize the base class */
    self = [super init]; 
	self.connectedClients = [NSMutableArray arrayWithCapacity:0];
	[self.connectedClients retain];
	self.messageHandler = msgHand;
	self.connectionID = conID;
	self.addedHandler = addHand;
	self.removedHandler = remHand;
	return self;
}

- (void) dealloc
{
	for(ConClient *cl in connectedClients)
	{
		[self removeClient:cl];
	}
	[self.connectedClients release];
	self.connectionID = NO_CON_ID;
	self.addedHandler = NULL;
	self.removedHandler = NULL;
	self.messageHandler = NULL;
	[super dealloc];
}


- (UInt16) addClientWithMask:(UInt32)newMask andMode:(UInt16)newMode andSignature:(UInt32)newSignature andName:(NSString*)newName
{
	UInt16 newClientID = [self foundFreeClientID];
	// newClient will have an initial retainCount after creation (retainCount = 1)
	ConClient *newClient = [[ConClient alloc] initWithClientID:newClientID andMask:newMask andMode:newMode andSignature:newSignature andName:newName];
	// addObject of NSMutableArray increases automaticly retainCount of an added object (retainCount = 2)
	[self.connectedClients addObject:newClient];
	// so we can release newClient here because NSMutableArray hold the object (retainCount = 1)
	[newClient release];
	return newClientID;
}

- (void) removeClient: (ConClient*) clientObj
{
	clientObj.clientID = 0;
	clientObj.mask = 0;
	// removeObject will automaticly retain the object and this leeds to free the memory of clientObj
	[self.connectedClients removeObject:clientObj];
}

- (UInt16) foundFreeClientID
{
	// eindeutige clientID bestimmen	
	UInt16 newId = NO_CLIENT_ID; // if really no ID will be found, we use "0" for no ID is found
	for (UInt16 possibleId = 1; possibleId < 65535; possibleId++)
	{
		// check if possible ID is still used
		BOOL foundID = FALSE;
		for(ConClient *cl in self.connectedClients)
		{
			if (possibleId == cl.clientID)
			{
				foundID = TRUE;
				break;
			}
		}
		// we found an not used ID
		if (foundID == FALSE)
		{
			newId = possibleId;
			break;
		}
	}
	return newId;
}

@end
