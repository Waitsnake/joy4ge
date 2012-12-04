/*
 *  ConnexionClient.c
 *  3DconnexionClient
 *
 *  Created by Marco Köhler on 04.08.12.
 *
 */

#import "ConnexionClientAPI.h"
#import "HIDConnection.h"
#import "ConConnection.h"

#define MY_ONE_CON_ID		88

NSAutoreleasePool * pool;
ConConnection * theConnection;
HIDConnection * theHidCollection;


OSErr			InstallConnexionHandlers			(ConnexionMessageHandlerProc messageHandler, ConnexionAddedHandlerProc addedHandler, ConnexionRemovedHandlerProc removedHandler)
{
	pool = [[NSAutoreleasePool alloc] init];
	theConnection = [[[ConConnection alloc] initWithConnectionID:MY_ONE_CON_ID  andMsgHandler:messageHandler andAddHandler:addedHandler andRemHandler:removedHandler] retain];
	theHidCollection = [[[HIDConnection alloc] init] retain];
	NSLog(@"InstallConnexionHandlers()\n");
	return noErr;
}

void			CleanupConnexionHandlers			(void)
{		
	NSLog(@"CleanupConnexionHandlers()\n");
	[theConnection.connectedClients removeAllObjects];
	[theConnection release];
	[theHidCollection release];
//	[pool release];
}

UInt16			RegisterConnexionClient				(UInt32 signature, UInt8 *name, UInt16 mode, UInt32 mask)
{
	NSLog(@"RegisterConnexionClient(signature = %8.8X, name = %s, mode = %4.4X, mask = %8.8X)\n",(unsigned int)signature,name,mode,(unsigned int)mask);
	NSString  *newName = nil;
	UInt16 newclientID = NO_CLIENT_ID;	
	// only direct mode is supported here and used by Google Earth
	if (mode == kConnexionClientModeTakeOver)
	{
		if (name != NULL)
		{
			newName = [[NSString alloc] initWithCString:(char*)name encoding:NSASCIIStringEncoding];
		}
		newclientID = [theConnection addClientWithMask:mask andMode:mode andSignature:signature andName:newName];
		if (newName != nil) [newName release];
		if (theConnection.addedHandler != NULL) theConnection.addedHandler(theConnection.connectionID);
	}
	return newclientID;
}

void			SetConnexionClientMask				(UInt16 clientID, UInt32 mask)
{
	NSLog(@"SetConnexionClientMask(clientID= %d, mask = %8.8X)\n",clientID,(unsigned int)mask);
	for(ConClient *cl in theConnection.connectedClients)
	{
		if (cl.clientID == clientID) cl.mask = mask;
	}
}

void			UnregisterConnexionClient			(UInt16 clientID)
{
	NSLog(@"UnregisterConnexionClient(clientID = %d)\n",clientID);
	if (theConnection.removedHandler != NULL) theConnection.removedHandler(theConnection.connectionID);
	if (clientID != NO_CLIENT_ID)
	{
		ConClient* foundCl=nil;
		for(ConClient* cl in theConnection.connectedClients)
		{		
			if (cl.clientID == clientID)
			{
				foundCl = cl;
			}
		}
		// we have to remove an object from array it outside the loop!
		if (foundCl!=nil) [theConnection removeClient: foundCl];
	}
}

OSErr			ConnexionControl					(UInt32 message, SInt32 param, SInt32 *result)
{
	NSLog(@"ConnexionControl(message = %d, param = %d, result = %8.8X)\n",(int)message,(int)param,(unsigned int)*result);
	// Not implemented, because not used by Google Earth	
	return noErr;
}

OSErr			ConnexionClientControl				(UInt16 clientID, UInt32 message, SInt32 param, SInt32 *result)
{
	
	NSLog(@"ConnexionClientControl(clientID = %d, message = %d, param = %d, result = %8.8X)\n", clientID, (int)message,(int)param,(unsigned int)*result);
	// Not implemented, because not used by Google Earth	
	return noErr;
}

OSErr			ConnexionGetCurrentDevicePrefs		(UInt32 deviceID, ConnexionDevicePrefs *prefs)
{
	NSLog(@"ConnexionGetCurrentDevicePrefs(deviceID = %d)\n",(int)deviceID);
	// Not implemented, because not used by Google Earth	
	return noErr;
}
