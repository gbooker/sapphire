/*
 * NSData-HashSupport.m
 * Software Loader
 *
 * Created by Graham Booker on Dec. 30 2007.
 * Copyright 2007 Sapphire Development Team and/or www.nanopi.net
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "NSData-HashSupport.h"
#include <openssl/evp.h>

@implementation NSData (HashSupport)
+ (NSData *)dataFromHexString:(NSString *)hex
{
	NSMutableData *ret = [[NSMutableData alloc] init];
	int i, length = [hex length];
	int loopLen = length - length % 16;
	const char *hexStr = [hex UTF8String];
	uint64_t number;
	for(i=0; i<loopLen; i+=16)
	{
		sscanf(hexStr+i, "%16qx", &number);
		number = CFSwapInt64HostToBig(number);
		[ret appendBytes:&number length:8];
	}
	if(loopLen != length)
	{
		sscanf(hexStr+i*16, "%16qx", &number);
		number = CFSwapInt64HostToBig(number);
		number = number << (8 - length + loopLen) * 8;
		[ret appendBytes:&number length:8];
	}
	NSData *returnData = [NSData dataWithData:ret];
	[ret release];
	return returnData;
}

+ (NSData *)md5HashForFile:(NSString *)path
{
	EVP_MD_CTX context;
	EVP_DigestInit(&context, EVP_md5());
#define BUFFER_SIZE 1024*1024
	unsigned char *data = malloc(BUFFER_SIZE);
	unsigned long len;
	int fp = open([path fileSystemRepresentation], O_RDONLY);
	
	while((len = read(fp, data, BUFFER_SIZE)) > 0)
		EVP_DigestUpdate(&context, data, len);
	
	unsigned char mdfinal[16];
	EVP_DigestFinal(&context, mdfinal, NULL);
	
	return [NSData dataWithBytes:mdfinal length:16];
}

@end
