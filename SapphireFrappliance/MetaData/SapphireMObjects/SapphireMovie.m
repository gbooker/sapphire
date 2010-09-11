#import "SapphireMovie.h"
#import "SapphireGenre.h"
#import "SapphireCast.h"
#import "SapphireDirector.h"
#import "CoreDataSupportFunctions.h"
#import "SapphireMetaDataSupport.h"
#import "SapphireFileMetaData.h"
#import "SapphireApplianceController.h"
#import "SapphireXMLData.h"
#import "NSString-Extensions.h"
#import "SapphireMovieTranslation.h"

NSString *FILE_DID_CHANGE_MOVIE_NOTIFICATION = @"FileDidChangeMovie";
NSString *MOVIE_DID_CHANGE_PREDICATE_MATCHING = @"MovieDidChangePredicateMatching";

#define ORDERED_CAST_KEY			@"orderedCast"
#define ORDERED_CAST_DATA			@"orderedCastData"
#define OVERRIDDEN_CAST_DATA		@"overriddenCastData"
#define ORDERED_DIRECTOR_KEY		@"orderedDirectors"
#define ORDERED_DIRECTOR_DATA		@"orderedDirectorsData"
#define OVERRIDDEN_DIRECTOR_DATA	@"overriddenDirectorsData"
#define ORDERED_GENRES_KEY			@"orderedGenres"
#define ORDERED_GENRES_DATA			@"orderedGenresData"
#define OVERRIDDEN_GENRES_DATA		@"overriddenGenresData"

@interface SapphireMovie ()
- (NSString *)movieSortTitle;
@end

@implementation SapphireMovie

+ (SapphireMovie *)movieWithIMDB:(int)imdbNumber inContext:(NSManagedObjectContext *)moc
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"imdbNumber == %d", imdbNumber];
	return (SapphireMovie *)doSingleFetchRequest(SapphireMovieName, moc, predicate);
}
	
+ (SapphireMovie *)createMovieWithIMDB:(int)imdbNumber inContext:(NSManagedObjectContext *)moc
{
	SapphireMovie *ret = [SapphireMovie movieWithIMDB:imdbNumber inContext:moc];
	if(ret != nil)
		return ret;
	
	ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireMovieName inManagedObjectContext:moc];
	ret.imdbNumber = [NSNumber numberWithInt:imdbNumber];
	return ret;
}

+ (SapphireMovie *)movieWithTitle:(NSString *)title inContext:(NSManagedObjectContext *)moc
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"imdbNumber == nil && title == %@", title];
	return (SapphireMovie *)doSingleFetchRequest(SapphireMovieName, moc, predicate);
}

+ (SapphireMovie *)createMovieWithTitle:(NSString *)title inContext:(NSManagedObjectContext *)moc
{
	SapphireMovie *ret = [SapphireMovie movieWithTitle:title inContext:moc];
	if(ret != nil)
		return ret;
	
	ret = [NSEntityDescription insertNewObjectForEntityForName:SapphireMovieName inManagedObjectContext:moc];
	ret.title = title;
	ret.imdbNumber = nil;
	return ret;
}

+ (SapphireMovie *)movieWithDictionary:(NSDictionary *)dict inContext:(NSManagedObjectContext *)moc
{
	return [self movieWithDictionary:dict inContext:moc lookup:nil];
}

+ (SapphireMovie *)movieWithDictionary:(NSDictionary *)dict inContext:(NSManagedObjectContext *)moc lookup:(NSDictionary *)lookup
{
	NSString *imdbStr = [dict objectForKey:META_MOVIE_IDENTIFIER_KEY];
	int imdbNumber = [SapphireMovie imdbNumberFromString:imdbStr];
	if(imdbNumber == 0)
		return nil;
	
	NSString *title = [dict objectForKey:META_MOVIE_TITLE_KEY];
	if(![title length])
	{
		SapphireLog(SapphireLogTypeImport, SapphireLogLevelError, @"Imported a movie with no title: %@", dict);
		return nil;
	}
	
	SapphireMovie *ret = [SapphireMovie createMovieWithIMDB:imdbNumber inContext:moc];
	ret.title = title;
	ret.releaseDate = [dict objectForKey:META_MOVIE_RELEASE_DATE_KEY];
	ret.MPAARating = [dict objectForKey:META_MOVIE_MPAA_RATING_KEY];
	ret.imdbRating = [dict objectForKey:META_MOVIE_IMDB_RATING_KEY];
	ret.plot = [dict objectForKey:META_MOVIE_PLOT_KEY];
	id value = [dict objectForKey:META_MOVIE_IMDB_250_KEY];
	int i;
	if((i = [value intValue]) != 0)
		ret.imdbTop250RankingValue = i;
	value = [dict objectForKey:META_MOVIE_OSCAR_KEY];
	if((i = [value intValue]) != 0)
		ret.oscarsWonValue = i;
	NSMutableArray *genreArray = [NSMutableArray array];
	NSEnumerator *genreEnum = [[dict objectForKey:META_MOVIE_GENRES_KEY] objectEnumerator];
	NSString *genre;
	while((genre = [genreEnum nextObject]) != nil)
		[genreArray addObject:[SapphireGenre createGenre:genre inContext:moc]];
	ret.orderedGenres = genreArray;
	
	NSMutableDictionary *directorLookup = [lookup objectForKey:@"Directors"];
	NSMutableArray *dirArray = [NSMutableArray array];
	NSEnumerator *directorEnum = [[dict objectForKey:META_MOVIE_DIRECTOR_KEY] objectEnumerator];
	if(directorLookup == nil)
	{
		NSString *director;
		while((director = [directorEnum nextObject]) != nil)
			[dirArray addObject:[SapphireDirector createDirector:director inContext:moc]];
	}
	else
	{
		NSString *director;
		while((director = [directorEnum nextObject]) != nil)
		{
			SapphireDirector *cached = [directorLookup objectForKey:director];
			if(cached == nil)
			{
				cached = [SapphireDirector createDirector:director inContext:moc];
				[directorLookup setObject:cached forKey:director];
			}
			[dirArray addObject:cached];
		}
	}
	ret.orderedDirectors = dirArray;

	NSMutableDictionary *castLookup = [lookup objectForKey:@"Cast"];
	NSMutableArray *castArray = [NSMutableArray array];
	NSEnumerator *castEnum = [[dict objectForKey:META_MOVIE_CAST_KEY] objectEnumerator];
	NSString *cast;
	if(castLookup == nil)
	{
		while((cast = [castEnum nextObject]) != nil)
			[castArray addObject:[SapphireCast createCast:cast inContext:moc]];
	}
	else
	{
		while((cast = [castEnum nextObject]) != nil)
		{
			SapphireCast *cached = [castLookup objectForKey:cast];
			if(cached == nil)
			{
				cached = [SapphireCast createCast:cast inContext:moc];
				[castLookup setObject:cached forKey:cast];
			}
			[castArray addObject:cached];
		}
	}
	ret.orderedCast = castArray;
	return ret;
}

+ (int)imdbNumberFromString:(NSString *)imdbStr
{
	int imdbNumber = 0;
	if(imdbStr != nil)
	{
		NSScanner *scanner = [NSScanner scannerWithString:imdbStr];
		[scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
		[scanner scanInt:&imdbNumber];
	}
	return imdbNumber;
}

+ (NSDictionary *)upgradeMoviesVersion:(int)version fromContext:(NSManagedObjectContext *)oldMoc toContext:(NSManagedObjectContext *)newMoc withCast:(NSDictionary *)cast directors:(NSDictionary *)directors genres:(NSDictionary *)genres
{
	NSMutableDictionary *lookup = [NSMutableDictionary dictionary];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray *oldMovies = doFetchRequest(SapphireMovieName, oldMoc, nil);
	NSEnumerator *movieEnum = [oldMovies objectEnumerator];
	NSManagedObject *oldMovie;
	while((oldMovie = [movieEnum nextObject]) != nil)
	{
		NSString *title = [oldMovie valueForKey:@"title"];
		NSNumber *imdbNumber = [oldMovie valueForKey:@"imdbNumber"];
		if(imdbNumber == nil && title == nil)
			//Reject b/c this movie info isn't useful
			continue;
		SapphireMovie *newMovie = [NSEntityDescription insertNewObjectForEntityForName:SapphireMovieName inManagedObjectContext:newMoc];
		newMovie.imdbNumber = imdbNumber;
		newMovie.imdbRating = [oldMovie valueForKey:@"imdbRating"];
		newMovie.imdbTop250Ranking = [oldMovie valueForKey:@"imdbTop250Ranking"];
		newMovie.MPAARating = [oldMovie valueForKey:@"MPAARating"];
		newMovie.oscarsWon = [oldMovie valueForKey:@"oscarsWon"];
		newMovie.plot = [oldMovie valueForKey:@"plot"];
		newMovie.releaseDate = [oldMovie valueForKey:@"releaseDate"];
		newMovie.title = title;
		
		NSData *propData = [oldMovie valueForKey:@"orderedCastData"];
		NSArray *castNames = [NSKeyedUnarchiver unarchiveObjectWithData:propData];
		NSEnumerator *castEnum = [castNames objectEnumerator];
		NSString *name;
		NSMutableArray *objArray = [NSMutableArray array];
		while((name = [castEnum nextObject]) != nil)
		{
			SapphireCast *castMember = [cast objectForKey:name];
			if(castMember == nil)
				castMember = [SapphireCast createCast:name inContext:newMoc];
			[objArray addObject:castMember];
		}
		newMovie.orderedCast = objArray;
		
		propData = [oldMovie valueForKey:@"orderedDirectorsData"];
		NSArray *directorNames = [NSKeyedUnarchiver unarchiveObjectWithData:propData];
		NSEnumerator *directorEnum = [directorNames objectEnumerator];
		objArray = [NSMutableArray array];
		while((name = [directorEnum nextObject]) != nil)
		{
			SapphireDirector *director = [directors objectForKey:name];
			if(director == nil)
				director = [SapphireDirector createDirector:name inContext:newMoc];
			[objArray addObject:director];
		}
		newMovie.orderedDirectors = objArray;
		
		propData = [oldMovie valueForKey:@"orderedGenresData"];
		NSArray *genreNames = [NSKeyedUnarchiver unarchiveObjectWithData:propData];
		NSEnumerator *genreEnum = [genreNames objectEnumerator];
		objArray = [NSMutableArray array];
		while((name = [genreEnum nextObject]) != nil)
		{
			SapphireGenre *genre = [genres objectForKey:name];
			if(genre == nil)
				genre = [SapphireGenre createGenre:name inContext:newMoc];
			[objArray addObject:genre];
		}
		newMovie.orderedGenres = objArray;
		
		NSEnumerator *translationEnum = [[oldMovie valueForKey:@"translations"] objectEnumerator];
		NSManagedObject *translation;
		while((translation = [translationEnum nextObject]) != nil)
		{
			[SapphireMovieTranslation upgradeMovieTranslationVersion:version from:translation toMovie:newMovie];
		}
		if(imdbNumber != nil)
			[lookup setObject:newMovie forKey:imdbNumber];
		else if(title != nil)
			[lookup setObject:newMovie forKey:title];
	}
	[SapphireMovieTranslation upgradeMovieLessMovieTranslationVersion:version fromContext:oldMoc toContext:newMoc];
	[pool drain];
	return lookup;
}

- (NSComparisonResult)releaseDateCompare:(SapphireMovie *)other
{
	return [self.releaseDate compare:other.releaseDate];
}

- (NSComparisonResult)titleCompare:(SapphireMovie *)other
{
	return [[self movieSortTitle] nameCompare:[other movieSortTitle]];
}

- (NSComparisonResult)imdbTop250RankingCompare:(SapphireMovie *)other
{
	return [self.imdbTop250Ranking compare:other.imdbTop250Ranking];
}

- (NSComparisonResult)oscarsWonCompare:(SapphireMovie *)other
{
	return [self.oscarsWon compare:other.oscarsWon];
}

- (NSComparisonResult)imdbRatingCompare:(SapphireMovie *)other
{
	NSNumber *otherNum = other.imdbRating;
	NSNumber *myNum = self.imdbRating;
	if(myNum != nil)
		if(otherNum != nil)
			return [myNum compare:otherNum];
		else
			return NSOrderedDescending;
	else if(otherNum != nil)
		return NSOrderedAscending;
	return NSOrderedSame;
}

- (NSArray *)orderedCast
{
	[self willAccessValueForKey:ORDERED_CAST_KEY];
	NSArray *ret = [self primitiveValueForKey:ORDERED_CAST_KEY];
	[self didAccessValueForKey:ORDERED_CAST_KEY];
	if(ret == nil)
	{
		NSData *propData = [self valueForKey:OVERRIDDEN_CAST_DATA];
		if(propData == nil)
			propData = [self valueForKey:ORDERED_CAST_DATA];
		if(propData != nil)
		{
			NSArray *names = [NSKeyedUnarchiver unarchiveObjectWithData:propData];
			NSMutableArray *mutRet = [NSMutableArray arrayWithCapacity:[names count]];
			
			NSSet *allCast = [self castSet];
			NSMutableDictionary *castByName = [[NSMutableDictionary alloc] initWithCapacity:[allCast count]];
			SapphireCast *cast;
			NSEnumerator *castEnum = [allCast objectEnumerator];
			while((cast = [castEnum nextObject]) != nil)
				[castByName setObject:cast forKey:cast.name];
			
			NSString *castName;
			castEnum = [names objectEnumerator];
			while((castName = [castEnum nextObject]) != nil)
			{
				cast = [castByName objectForKey:castName];
				if(cast != nil)
					[mutRet addObject:cast];
				else
					[mutRet addObject:[SapphireCast createCast:castName inContext:[self managedObjectContext]]];
			}
			[castByName release];
			ret = [NSArray arrayWithArray:mutRet];
			
			[self setPrimitiveValue:ret forKey:ORDERED_CAST_KEY];
		}
	}
	
	return ret;
}

- (void)setOrderedCast:(NSArray *)ordered
{
	[self willChangeValueForKey:ORDERED_CAST_KEY];
	[self setPrimitiveValue:ordered forKey:ORDERED_CAST_KEY];
	[self didChangeValueForKey:ORDERED_CAST_KEY];
	NSArray *arc = [ordered valueForKey:@"name"];
	[self setValue:[NSKeyedArchiver archivedDataWithRootObject:arc] forKey:ORDERED_CAST_DATA];
	[self setValue:[NSSet setWithArray:ordered] forKey:@"cast"];
	int i, count=[ordered count];
	if(count > 10)
		count = 10;
	for(i=0; i<count; i++)
	{
		((SapphireCast *)[ordered objectAtIndex:i]).hasMajorRoleValue = YES;
	}	
}

- (NSArray *)orderedGenres
{
	[self willAccessValueForKey:ORDERED_GENRES_KEY];
	NSArray *ret = [self primitiveValueForKey:ORDERED_GENRES_KEY];
	[self didAccessValueForKey:ORDERED_GENRES_KEY];
	if(ret == nil)
	{
		NSData *propData = [self valueForKey:OVERRIDDEN_GENRES_DATA];
		if(propData == nil)
			propData = [self valueForKey:ORDERED_GENRES_DATA];
		if(propData != nil)
		{
			NSArray *genres = [NSKeyedUnarchiver unarchiveObjectWithData:propData];
			NSMutableArray *mutRet = [NSMutableArray arrayWithCapacity:[genres count]];
			
			NSSet *allGenres = [self genresSet];
			NSMutableDictionary *genreByName = [[NSMutableDictionary alloc] initWithCapacity:[allGenres count]];
			SapphireGenre *genre;
			NSEnumerator *genreEnum = [allGenres objectEnumerator];
			while((genre = [genreEnum nextObject]) != nil)
				[genreByName setObject:genre forKey:genre.name];
			
			NSString *genreName;
			genreEnum = [genres objectEnumerator];
			while((genreName = [genreEnum nextObject]) != nil)
			{
				genre = [genreByName objectForKey:genreName];
				if(genre != nil)
					[mutRet addObject:genre];
				else
					[mutRet addObject:[SapphireGenre createGenre:genreName inContext:[self managedObjectContext]]];
			}
			[genreByName release];
			ret = [NSArray arrayWithArray:mutRet];			
			
			[self setPrimitiveValue:ret forKey:ORDERED_GENRES_KEY];
		}
	}
	
	return ret;
}

- (void)setOrderedGenres:(NSArray *)ordered
{
	[self willChangeValueForKey:ORDERED_GENRES_KEY];
	[self setPrimitiveValue:ordered forKey:ORDERED_GENRES_KEY];
	[self didChangeValueForKey:ORDERED_GENRES_KEY];
	NSArray *arc = [ordered valueForKey:@"name"];
	[self setValue:[NSKeyedArchiver archivedDataWithRootObject:arc] forKey:ORDERED_GENRES_DATA];
	[self setValue:[NSSet setWithArray:ordered] forKey:@"genres"];
}

- (NSArray *)orderedDirectors
{
	[self willAccessValueForKey:ORDERED_DIRECTOR_KEY];
	NSArray *ret = [self primitiveValueForKey:ORDERED_DIRECTOR_KEY];
	[self didAccessValueForKey:ORDERED_DIRECTOR_KEY];
	if(ret == nil)
	{
		NSData *propData = [self valueForKey:OVERRIDDEN_DIRECTOR_DATA];
		if(propData == nil)
			propData = [self valueForKey:ORDERED_DIRECTOR_DATA];
		if(propData != nil)
		{
			NSArray *names = [NSKeyedUnarchiver unarchiveObjectWithData:propData];
			NSMutableArray *mutRet = [NSMutableArray arrayWithCapacity:[names count]];
			NSManagedObjectContext *moc = [self managedObjectContext];
			NSEnumerator *nameEnum = [names objectEnumerator];
			NSString *name;
			while((name = [nameEnum nextObject]) != nil)
			{
				SapphireDirector *aDir = [SapphireDirector createDirector:name inContext:moc];
				if(aDir != nil)
					[mutRet addObject:aDir];
			}
			ret = [NSArray arrayWithArray:mutRet];
			[self setPrimitiveValue:ret forKey:ORDERED_DIRECTOR_KEY];
		}
	}
	
	return ret;
}

- (void)setOrderedDirectors:(NSArray *)ordered
{
	[self willChangeValueForKey:ORDERED_DIRECTOR_KEY];
	[self setPrimitiveValue:ordered forKey:ORDERED_DIRECTOR_KEY];
	[self didChangeValueForKey:ORDERED_DIRECTOR_KEY];
	NSArray *arc = [ordered valueForKey:@"name"];
	[self setValue:[NSKeyedArchiver archivedDataWithRootObject:arc] forKey:ORDERED_DIRECTOR_DATA];
	[self setValue:[NSSet setWithArray:ordered] forKey:@"directors"];
}

#define checkOrderedData(property, overridden) \
{ \
	NSEnumerator *xmlEnum = [self.xmlSet objectEnumerator]; \
	SapphireXMLData *xml; \
	while([overridden count] == 0 && (xml = [xmlEnum nextObject]) != nil) \
		overridden = xml.property; \
}

- (void)checkOrderedCast
{
	NSArray *overridden = nil;
	checkOrderedData(orderedCast, overridden);
	if(![overridden count])
		self.overriddenCastData = nil;
	else
	{
		NSArray *names = [overridden valueForKey:@"name"];
		self.overriddenCastData = [NSKeyedArchiver archivedDataWithRootObject:names];
	}
	[self setPrimitiveValue:nil forKey:ORDERED_CAST_KEY];
	[self setValue:[NSSet setWithArray:self.orderedCast] forKey:@"cast"];
}

- (void)checkOrderedGenres
{
	NSArray *overridden = nil;
	checkOrderedData(orderedGenres, overridden);
	if(![overridden count])
		self.overriddenGenresData = nil;
	else
	{
		NSArray *names = [overridden valueForKey:@"name"];
		self.overriddenGenresData = [NSKeyedArchiver archivedDataWithRootObject:names];
	}
	[self setPrimitiveValue:nil forKey:ORDERED_GENRES_KEY];
	[self setValue:[NSSet setWithArray:self.orderedGenres] forKey:@"genres"];
}

- (void)checkOrderedDirectors
{
	NSArray *overridden = nil;
	checkOrderedData(orderedDirectors, overridden);
	if(![overridden count])
		self.overriddenDirectorsData = nil;
	else
	{
		NSArray *names = [overridden valueForKey:@"name"];
		self.overriddenDirectorsData = [NSKeyedArchiver archivedDataWithRootObject:names];
	}
	[self setPrimitiveValue:nil forKey:ORDERED_DIRECTOR_KEY];
	[self setValue:[NSSet setWithArray:self.orderedDirectors] forKey:@"directors"];
}

- (void)checkXMLOverridenSets
{
	[self checkOrderedCast];
	[self checkOrderedGenres];
	[self checkOrderedDirectors];
}

- (void)addXml:(NSSet*)addedXMLs
{
	[super addXml:addedXMLs];
	[self checkXMLOverridenSets];
}

-(void)removeXml:(NSSet*)removedXMLs
{
	[super removeXml:removedXMLs];
	//This can occur during a delete propogation, which appears to have KVO completely broken; workaround
	[SapphireMetaDataSupport setObjectForPendingDelete:self];
}

- (void)addXmlObject:(SapphireXMLData*)addedXML
{
	[super addXmlObject:addedXML];
	[self checkXMLOverridenSets];
}

- (void)removeXmlObject:(SapphireXMLData*)removedXML
{
	[super removeXmlObject:removedXML];
	//This can occur during a delete propogation, which appears to have KVO completely broken; workaround
	[SapphireMetaDataSupport setObjectForPendingDelete:self];
}

- (NSString *)title
{
	overrideWithXMLForKey(NSString, title);
	return super.title;
}

- (NSString *)movieSortTitle
{
	overrideWithXMLForKey(NSString, movieSortTitle);
	return self.title;
}

- (NSString *)plot
{
	overrideWithXMLForKey(NSString, summary);
	overrideWithXMLForKey(NSString, contentDescription);
	return super.plot;
}

- (NSString *)MPAARating
{
	overrideWithXMLForKey(NSString, MPAARating);
	return super.MPAARating;
}

- (NSNumber *)imdbRating
{
	overrideWithXMLForKey(NSNumber, imdbRating);
	return super.imdbRating;
}

- (BOOL)castMemberHasMajorRoleStatus:(SapphireCast *)cast
{
	NSArray *ordered = self.orderedCast;
	int i, count=[ordered count];
	if(count > 10)
		count = 10;
	for(i=0; i<count; i++)
	{
		if([ordered objectAtIndex:i] == cast)
			return YES;
	}
	return NO;
}

- (NSString *)path
{
	return [@"@MOVIES/Movie" stringByAppendingPathComponent:[self.imdbNumber stringValue]];
}

- (NSString *)coverArtPath
{
	return [NSString stringWithFormat:@"%@/@MOVIES/%@", [SapphireMetaDataSupport collectionArtPath], self.imdbNumber];
}

- (void)insertDisplayMetaData:(NSMutableDictionary *)dict
{
	id value = [self title];
	if(value != nil)
		[dict setObject:value forKey:META_MOVIE_TITLE_KEY];
	value = [self MPAARating];
	if(value != nil)
		[dict setObject:value forKey:META_MOVIE_MPAA_RATING_KEY];
	value = [self imdbRating];
	if(value != nil)
		[dict setObject:value forKey:META_MOVIE_IMDB_RATING_KEY];
	value = [self plot];
	if(value != nil)
		[dict setObject:value forKey:META_MOVIE_PLOT_KEY];
	value = [self releaseDate];
	if(value != nil)
		[dict setObject:value forKey:META_MOVIE_RELEASE_DATE_KEY];
	value = [self imdbTop250Ranking];
	if(value != nil)
		[dict setObject:value forKey:META_MOVIE_IMDB_250_KEY];
	value = [self oscarsWon];
	if(value != nil)
		[dict setObject:value forKey:META_MOVIE_OSCAR_KEY];
	value = [[self orderedDirectors] valueForKey:@"name"];
	if(value != nil)
		[dict setObject:value forKey:META_MOVIE_DIRECTOR_KEY];
	value = [[self orderedCast] valueForKey:@"name"];
	if(value != nil)
		[dict setObject:value forKey:META_MOVIE_CAST_KEY];
	value = [[self orderedGenres] valueForKey:@"name"];
	if(value != nil)
		[dict setObject:value forKey:META_MOVIE_GENRES_KEY];
}

//XXX
/*IS THIS EVER USED?
- (NSNumber *)watched
{
	NSSet *files = self.filesSet;
	if([files count] < 2)
		return [[files anyObject] watched];
	
	NSArray *remain = [[files allObjects] filteredArrayUsingPredicate:[SapphireApplianceController unwatchedPredicate]];
	if([remain count])
		return [NSNumber numberWithBool:YES];
	return [NSNumber numberWithBool:NO];
}

- (NSNumber *)favorite
{
	NSSet *files = self.filesSet;
	if([files count] < 2)
		return [[files anyObject] favorite];
	
	NSArray *remain = [[files allObjects] filteredArrayUsingPredicate:[SapphireApplianceController favoritePredicate]];
	if([remain count])
		return [NSNumber numberWithBool:YES];
	return [NSNumber numberWithBool:NO];
}*/

- (void)clearPredicateCache
{
	[self.orderedGenres makeObjectsPerformSelector:@selector(clearPredicateCache)];
	[self.orderedDirectors makeObjectsPerformSelector:@selector(clearPredicateCache)];
	[self.orderedCast makeObjectsPerformSelector:@selector(clearPredicateCache)];
	[[NSNotificationCenter defaultCenter] postNotificationName:MOVIE_DID_CHANGE_PREDICATE_MATCHING object:self];
}

- (void)addFiles:(NSSet*)addedFiles
{
	[super addFiles:addedFiles];
	[self clearPredicateCache];
}

- (BOOL)shouldDelete
{
	if([self.filesSet count] == 0)
		return YES;
	
	[self checkXMLOverridenSets];
	return NO;
}

-(void)removeFiles:(NSSet*)removeFiles
{
	[super removeFiles:removeFiles];
	if([self.filesSet count] == 0)
		[SapphireMetaDataSupport setObjectForPendingDelete:self];
	else
		[self clearPredicateCache];
}

- (void)addFilesObject:(SapphireFileMetaData *)addedFile
{
	[super addFilesObject:addedFile];
	[self clearPredicateCache];
}

- (void)removeFilesObject:(SapphireFileMetaData *)removeFile
{
	[super removeFilesObject:removeFile];
	if([self.filesSet count] == 0)
		[SapphireMetaDataSupport setObjectForPendingDelete:self];
	else
		[self clearPredicateCache];
}

@end
