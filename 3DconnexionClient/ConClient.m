/*
 *  ConClient.m
 *  3DconnexionClient
 *
 *  Created by Marco Köhler on 08.08.12.
 *
 */

#import "ConClient.h"

@implementation ConClient

@synthesize clientID;
@synthesize mask;
@synthesize mode;
@synthesize signature;
@synthesize name;

- (id) init
{
	return [self initWithClientID:0 andMask:0 andMode:0 andSignature:0 andName:nil]; 
}

- (id) initWithClientID:(UInt16)newClientID andMask:(UInt32)newMask andMode:(UInt16)newMode andSignature:(UInt32)newSignature andName:(NSString*)newName
{
	/* first initialize the base class */
	self = [super init]; 
	self.clientID = newClientID;
	self.mask = newMask;
	self.mode = newMode;
	self.signature = newSignature;
	self.name = newName;
	if (self.name != nil) [self.name retain];
	return self;
}

- (void) dealloc
{
	if (self.name != nil) [self.name release];
	[super dealloc];
}

@end
