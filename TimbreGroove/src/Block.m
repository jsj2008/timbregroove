//
//  Block.c
//  TimbreGroove
//
//  Created by victor on 3/4/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Block.h"
#import "TGTypes.h"

typedef NS_ENUM(int, BKBlockFlags) {
	BKBlockFlagsHasCopyDisposeHelpers	= (1 << 25),
	BKBlockFlagsHasConstructor			= (1 << 26),
	BKBlockFlagsIsGlobal				= (1 << 28),
	BKBlockFlagsReturnsStruct			= (1 << 29),
	BKBlockFlagsHasSignature			= (1 << 30)
};

typedef struct _BKBlock {
	void *isa;
	BKBlockFlags flags;
	int reserved;
	void (*invoke)(void);
	struct {
		unsigned long int reserved;
		unsigned long int size;
		// requires BKBlockFlagsHasCopyDisposeHelpers
		void (*copy)(void *dst, const void *src);
		void (*dispose)(const void *);
		// requires BKBlockFlagsHasSignature
		const char *signature;
		const char *layout;
	} *descriptor;
	// imported variables
} *BKBlockRef;

static NSMethodSignature *a2_blockGetSignature(id block) {
    
	BKBlockRef layout = (__bridge void *)block;
    
	if (!(layout->flags & BKBlockFlagsHasSignature))
		return nil;
    
	void *desc = layout->descriptor;
	desc += 2 * sizeof(unsigned long int);
    
	if (layout->flags & BKBlockFlagsHasCopyDisposeHelpers)
		desc += 2 * sizeof(void *);
    
	if (!desc)
		return nil;
    
	const char *signature = (*(const char **)desc);
	return [NSMethodSignature signatureWithObjCTypes: signature];
}

static char typeForSignature(const char *argumentType)
{
    static const char * sizeEncoded  = @encode(CGSize);
    static const char * pointEncoded = @encode(CGPoint);
    static const char * rectEncoded  = @encode(CGRect);
    static const char * vec3Encoded  = @encode(TGVector3);
    
    switch (*argumentType) {
        case _C_STRUCT_B:
			if (!strcmp(argumentType, sizeEncoded))
			{
				return TGC_SIZE;
			}
			else if (!strcmp(argumentType, pointEncoded))
			{
				return TGC_POINT;
			}
			else if (!strcmp(argumentType, rectEncoded)) 
			{
				return TGC_RECT;
			}
			else if (!strcmp(argumentType, vec3Encoded))
			{
				return TGC_VECTOR3;
			}
            break;
            
        default:
            return *argumentType;
    }
    
    return 0;
}

char GetBlockArgumentType(id block)
{
    NSMethodSignature *sig = a2_blockGetSignature(block);
    
    const char * argumentType = [sig getArgumentTypeAtIndex:1]; // 0 is return type
    
    return typeForSignature(argumentType);
}