#import "_SapphireXMLData.h"

#define SapphireXMLDataName		@"XMLData"

#define overrideWithXMLForKey(objectType, key) \
	{ \
		NSEnumerator *xmlEnum = [self.xmlSet objectEnumerator]; \
		SapphireXMLData *xml; \
		while((xml = [xmlEnum nextObject]) != nil) \
		{ \
			objectType *ret = xml.key; \
			if(ret != nil) \
				return ret; \
		} \
	}
@interface SapphireXMLData : _SapphireXMLData {}
+ (void)upgradeXMLVersion:(int)version fromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc file:(NSDictionary *)fileLookup;
- (void)insertDictionary:(NSDictionary *)dict;
- (NSArray *)orderedCast;
- (void)setOrderedCast:(NSArray *)ordered;
- (NSArray *)orderedGenres;
- (void)setOrderedGenres:(NSArray *)ordered;
- (NSArray *)orderedDirectors;
- (void)setOrderedDirectors:(NSArray *)ordered;
- (void)constructMovie;
- (void)constructEpisode;
@end
