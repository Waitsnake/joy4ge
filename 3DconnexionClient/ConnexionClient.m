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
	NSLog(@"InstallConnexionHandlers(messageHandler = %8.8X, addedHandler = %8.8X, removedHandler = %8.8X)\n",(int32_t)messageHandler,(int32_t)addedHandler,(int32_t)removedHandler);
	return noErr;
}

OSErr			SetConnexionHandlers				(ConnexionMessageHandlerProc messageHandler, ConnexionAddedHandlerProc addedHandler, ConnexionRemovedHandlerProc removedHandler, bool useSeparateThread)
{
    NSLog(@"SetConnexionHandlers()\n");
    // Not implemented, because not used by Google Earth	
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

uint16_t		RegisterConnexionClient				(uint32_t signature, uint8_t *name, uint16_t mode, uint32_t mask)
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
        NSLog(@"newclientID = %4.4X\n",newclientID);

		if (theConnection.addedHandler != NULL) theConnection.addedHandler(theConnection.connectionID);
        
	}
	return newclientID;
}

void			SetConnexionClientMask				(uint16_t clientID, uint32_t mask)
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

int16_t			ConnexionControl					(uint32_t message, int32_t param, int32_t *result)
{
	NSLog(@"ConnexionControl(message = %d, param = %d, result = %8.8X)\n",(int)message,(int)param,(unsigned int)*result);
	// Not implemented, because not used by Google Earth	
	return noErr;
}

int16_t			ConnexionClientControl				(uint16_t clientID, uint32_t message, int32_t param, int32_t *result)
{
	
	NSLog(@"ConnexionClientControl(clientID = %d, message = %d, param = %d, result = %8.8X)\n", clientID, (int)message,(int)param,(unsigned int)*result);
	// Not implemented, because not used by Google Earth	
	return noErr;
}

int16_t			ConnexionGetCurrentDevicePrefs		(uint32_t deviceID, ConnexionDevicePrefs *prefs)
{
	NSLog(@"ConnexionGetCurrentDevicePrefs(deviceID = %d)\n",(int)deviceID);
	// Not implemented, because not used by Google Earth	
	return noErr;
}

int16_t			ConnexionSetButtonLabels			(uint8_t *labels, uint16_t size)
{
    NSLog(@"ConnexionSetButtonLabels(labels = %s; size = %d)\n",labels, size);
    // Not implemented, because not used by Google Earth
    return noErr;
}
