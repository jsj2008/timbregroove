
#include "MeshImporter.h"
#include "SkinnedPVR.h"
#include <mach/mach_time.h>

@interface MeshImporter () {
    PVR_SKINNER _skinnerThingy;
    float _rotation;
    NSTimeInterval _time;
}
@property (nonatomic,readonly,getter = getPods) NSDictionary * pods;
@property (nonatomic,weak) NSDictionary * podInfo;
@end

@implementation MeshImporter

-(NSDictionary *)getPods
{
    NSDictionary * dict = [self valueForKey:@"knownPODs"];
    return dict;
}

-(id)wireUp
{
    NSDictionary * dict = self.getPods;
    for( NSString * name in dict )
    {
        if( !_meshName || ([name isEqualToString:_meshName]) )
        {
            _meshName = name;
            _podInfo = dict[name];
            break;
        }
    }
    
    int numTextures = [_podInfo count];
    char * name = (char *)[_meshName UTF8String];
    char **textureFiles = (char **)malloc(sizeof(char*)*numTextures);
    char **textureNames = (char **)malloc(sizeof(char*)*numTextures);
    
    int count = 0;
    for( NSString * textureName in _podInfo )
    {
        textureFiles[count] = (char *)[_podInfo[textureName] UTF8String];
        textureNames[count] = (char *)[textureName UTF8String];
        ++count;
    }
    
    _skinnerThingy = Skinner_Get(name, textureFiles, textureNames, numTextures);
    return [super wireUp];
}

-(void)update:(NSTimeInterval)dt
{
    _time += dt;
    if( _time > 0.3f )
    {
        _rotation += 1.0;
        _time = 0;
    }
    self.rotation = GLKVector3Make(0, GLKMathDegreesToRadians(_rotation), 0);
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    Skinner_Render(_skinnerThingy,self.modelView.m);
}

-(void)setViewIsHidden:(NSNumber *)viewIsHidden
{
    if( [viewIsHidden boolValue] )
        Skinner_Pause(_skinnerThingy);
    else
        Skinner_Resume(_skinnerThingy);
    
    [super setViewIsObscured:viewIsHidden];
}

@end
void EnvExitMsg( const char * msg )
{
    NSLog(@"%s",msg);
    exit(-1);
}

int EnvGeti(int pref)
{
    CGSize sz = [[UIScreen mainScreen] bounds].size;
    if( pref == prefWidth )
        return sz.width;
    if( pref == prefHeight )
        return sz.height;
    return 0;
}

void * EnvGet(int param)
{
    // readpath
    
    return (void *)[[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/"] UTF8String];
}

static mach_timebase_info_data_t _s_sTimeBaseInfo;
static bool _s_mach_time_installed = false;

unsigned long EnvGetTime()
{
    if( !_s_mach_time_installed )
        mach_timebase_info(&_s_sTimeBaseInfo);        
	uint64_t time = mach_absolute_time();
	uint64_t millis = (time * (_s_sTimeBaseInfo.numer/_s_sTimeBaseInfo.denom))/1000000.0;
	return millis;
}

