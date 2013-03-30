
#import "TG3dObject.h"
#import "SkinnedPVR.h"
#import "Scene.h"
#import "Config.h"
#import "Photo.h"

@interface MeshImporter : TG3dObject

@end

@interface MeshImporter () {
    PVR_SKINNER _skinnerThingy;
    float _rotation;
@public
    NSTimeInterval _runningTime;
}
@property (nonatomic,strong) NSString * meshName;
@property (nonatomic) float scalingFactor;
@end

@implementation MeshImporter

-(void)dealloc
{
    Skinner_Destroy(_skinnerThingy);
}

-(id)wireUp
{
    TGLog(LLMeshImporter, @"Loading mesh: %@",self.meshName);
    NSDictionary * podInfo = [[Config sharedInstance] getModel:self.meshName];
    int numTextures = [podInfo count];
    char * name = (char *)[_meshName UTF8String];
    char **textureFiles = (char **)malloc(sizeof(char*)*numTextures);
    char **textureNames = (char **)malloc(sizeof(char*)*numTextures);
    
    int count = 0;
    for( NSString * textureName in podInfo )
    {
        textureFiles[count] = (char *)[podInfo[textureName] UTF8String];
        textureNames[count] = (char *)[textureName UTF8String];
        ++count;
    }
    
    _skinnerThingy = Skinner_Get(name, textureFiles, textureNames, numTextures,(__bridge void *)self);
    
    free(textureFiles);
    free(textureNames);
    
    [super wireUp];
    
    Photo * photo = [[Photo alloc] init];
    [self appendChild:[photo wireUp]];
    photo.position = (GLKVector3){0,0,-12};
    
    self.position = (GLKVector3){0.0,-0.5,0.0};
    
    if( self.scalingFactor )
    {
        self.scaleXYZ = self.scalingFactor;
    }
    return self;
}

-(void)getParameters:(NSMutableDictionary *)putHere
{
    [super getParameters:putHere];
    
    putHere[@"Zoom"] = [Parameter withBlock:^(float f) {
        TG3dObject * obj = _kids[0];
        
        GLKVector3 pos = obj.position;
        pos.z += f;
        obj.position = pos;

        GLKVector3 mpos = self.position;
        mpos.z += f;
        self.position = mpos;
        
        TGLog(LLMeshImporter, @"Zpos: obj:%f  mesh:%f", pos.z, mpos.z);
    }];
    putHere[@"FixZoom"] = [Parameter withBlock:^(CGPoint pt) {
        TG3dObject * obj = _kids[0];
        obj.position = (GLKVector3){0,0,-12};
        self.position = (GLKVector3){0,0,0};
    }];
    
    putHere[@"Ping!"] = [Parameter withBlock:^(float f) {
        _runningTime += f * 0.05;
        _rotation += f * 3.0;
    }];
}
-(void)update:(NSTimeInterval)dt
{
    float deg = GLKMathDegreesToRadians(_rotation);
    self.rotation = (GLKVector3){0, deg, 0};
    TG3dObject * obj = _kids[0];    
    obj.rotation = (GLKVector3){0, -deg, 0};
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    Skinner_Render(_skinnerThingy,self.modelView.m);
}

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

