/*
    Copyright (C) 2004-2005 NAKAHASHI Ichiro.
    
    This program is distributed under the GNU Public Lisence.
    This program comes with NO WARRANTY.
 */

#import "NSUserDefaults-FSExt.h"

@implementation NSUserDefaults (FSExtensions)

- unarchivedObjectForKey:key
{
    NSValueTransformer *vt = [NSValueTransformer
			valueTransformerForName:NSUnarchiveFromDataTransformerName];
    return [vt transformedValue:[self objectForKey:key]];
}

@end
