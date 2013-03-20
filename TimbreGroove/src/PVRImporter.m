
#include "PVRImporter.h"
#include "SkinnedPVR.h"
#include "Scene.h"

@class View;

@interface MeshImporter () {
    PVR_SKINNER _skinnerThingy;
    float _rotation;
@public
    NSTimeInterval _runningTime;
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
    
    _skinnerThingy = Skinner_Get(name, textureFiles, textureNames, numTextures,(__bridge void *)self);
    
    free(textureFiles);
    free(textureNames);
    
    return [super wireUp];
}

-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];
    
    putHere[@"Ping!"] = [Parameter withBlock:^(float f) {
        _runningTime += f * 0.05;
        _rotation += f * 3.0;
    }];
}
-(void)update:(NSTimeInterval)dt
{
    self.rotation = GLKVector3Make(0, GLKMathDegreesToRadians(_rotation), 0);
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    Skinner_Render(_skinnerThingy,self.modelView.m);
}

/*
-(void)tgViewIsFullyVisible:(View *)view
{
    Skinner_Resume(_skinnerThingy);
}

-(void)tgViewWillDisappear:(View *)view
{
    Skinner_Pause(_skinnerThingy);
}
 */
@end

void EnvExitMsg( const char * msg )
{
    TGLog(LLShitsOnFire, @"%s",msg);
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

unsigned long EnvGetTime(void * context)
{
    MeshImporter * mi = (__bridge MeshImporter *)context;
//    return (unsigned long)( /*floor*/(CACurrentMediaTime()*1000.0) );
    
    return (unsigned long)( /*floor*/(mi->_runningTime*1000.0) );
    
}

