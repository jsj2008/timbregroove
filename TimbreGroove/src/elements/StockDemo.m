//
//  TGPlane.m
//  
//
//  Created by victor on 12/15/12.
//
//

#import "Painter.h"

#import "SettingsVC.h"
#import "Material.h"

#import "GridPlane.h"
#import "SphereOid.h"
#import "Torus.h"
#import "Cube.h"

#import "Fire.h"
#import "Cloud.h"
#import "Pool.h"



@interface StockDemo : Painter
@property (nonatomic,strong) NSString * shaderName;
@property (nonatomic,strong) NSString * geometryName;
@end

typedef enum shaderType {
    fire,
    cloud,
    pool,
    
    ALL_SHADER_TYPES
} shaderType;

@interface StockDemo () {
    float _rot;
    bool _rotateY;
    shaderType _shaderType;
}

@end
@implementation StockDemo

-(id)wireUp
{
    if( !_geometryName )
        _geometryName = @"SphereOid";
    if( !_shaderName )
        _shaderName = @"Fire";
    
    if( [_shaderName isEqualToString:@("Pool")] )
        _shaderType = pool;
    else if( [_shaderName isEqualToString:@("Cloud")] )
        _shaderType = cloud;
    else if( [_shaderName isEqualToString:@("Fire")] )
        _shaderType = fire;
    
    return [super wireUp];
}

-(void)setShaderName:(NSString *)shaderName
{
    _shaderName = shaderName;
    self.settingsAreDirty = true;
}

-(void)setGeometryName:(NSString *)geometryName
{
    _geometryName = geometryName;
    _rotateY = ![geometryName isEqualToString:@"Torus"];
    self.settingsAreDirty = true;
}

-(void)update:(NSTimeInterval)dt
{
    _rot += 1;
    float rads = GLKMathDegreesToRadians(_rot);
    self.rotation = (GLKVector3){ _rotateY ? 0 : rads, _rotateY ? rads : 0, 0 };
    if( _shaderType == pool )
        ((Pool*)self.shader).time = (float)dt;
}

-(void)createShader
{
    Texture * texture = nil;
    if( _shaderType == pool )
    {
        texture = [[Texture alloc] initWithFileName:@"pool.png"];
        [self addShaderFeature:texture];
    }
    Class klass = NSClassFromString(_shaderName);
    self.shader = [klass new];
    if( texture )
        texture.uLocation = [self.shader location:pool_sampler];
}

-(void)createBuffer
{
    MeshBuffer * buffer;
    NSArray * indicesIntoNames;
    
    if( _shaderType == fire )
    {
        indicesIntoNames = @[@(fv_position),@(fv_normal)];
    }
    else if( _shaderType == cloud )
    {
        indicesIntoNames = @[@(cld_position),@(cld_normal)];
    }
    else if( _shaderType == pool )
    {
        indicesIntoNames = @[@(pool_position),@(pool_uv),@(pool_normal)];
    }
    
    if( [_geometryName isEqualToString:@"GridPlane"] )
    {
        buffer = [GridPlane gridWithWidth:2
                                 andGrids:10
                      andIndicesIntoNames:indicesIntoNames];
    }
    else if( [_geometryName isEqualToString:@"Torus"] )
    {
        buffer = [Torus torusWithIndicesIntoNames:indicesIntoNames];
    }
    else if( [_geometryName isEqualToString:@"Cube"] )
    {
        buffer = [Cube cubeWithIndicesIntoNames:indicesIntoNames];
    }
    else
    {
        buffer = [SphereOid sphereWithdIndicesIntoNames:indicesIntoNames];
    }
    
    [self addBuffer:buffer];    
}

- (void)getSettings:(NSMutableArray *)arr
{
    NSDictionary * shaders = @{ @"Cloud": @"Clouds", @"Fire":@"Fire", @"Pool": @"Pool" };    
    
    SettingsDescriptor * sd1;
    sd1 = [[SettingsDescriptor alloc] initWithControlType: SC_Picker
                                               memberName: @("shaderName")
                                                labelText: @"Effect"
                                                  options: @{@"values":shaders,
                                                    @"target":self, @"key":@"shaderName"}
                                             initialValue: _shaderName
                                                 priority: SHADER_SETTINGS];

    NSDictionary * shapes = @{ @"SphereOid": @"Ball", @"GridPlane":@"Board",
                                @"Torus":@"Donut", @"Cube":@"Box" };
    
    SettingsDescriptor * sd2;
    sd2 = [[SettingsDescriptor alloc] initWithControlType: SC_Picker
                                               memberName: @("shapeName")
                                                labelText: @"Shape"
                                                  options: @{@"values":shapes,
                                                    @"target":self, @"key":@"geometryName"}
                                             initialValue: _geometryName
                                                 priority: SHADER_SETTINGS];

    [arr addObject:sd1];
    [arr addObject:sd2];
    
}

@end
