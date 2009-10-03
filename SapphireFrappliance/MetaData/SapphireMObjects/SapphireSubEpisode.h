#define SapphireSubEpisodeName		@"SubEpisode"

#import "_SapphireSubEpisode.h"

@interface SapphireSubEpisode : _SapphireSubEpisode {}
+ (SapphireSubEpisode *)subEpisode:(int)subNum inEpisode:(SapphireEpisode *)ep;
+ (SapphireSubEpisode *)subEpisodeTitle:(NSString *)title inEpisode:(SapphireEpisode *)ep;
+ (SapphireSubEpisode *)createSubEpisode:(int)subNum inEpisode:(SapphireEpisode *)ep;
+ (SapphireSubEpisode *)createSubEpisodeTitle:(NSString *)title inEpisode:(SapphireEpisode *)ep;
+ (void)upgradeV1SubEpisode:(NSManagedObject *)oldEp toContext:(NSManagedObjectContext *)newMoc inEpisode:(SapphireEpisode *)ep;

- (void)insertDictionary:(NSDictionary *)dict epIndex:(int)index;
- (NSComparisonResult)compare:(SapphireSubEpisode *)other;
- (NSString *)path;
@end
