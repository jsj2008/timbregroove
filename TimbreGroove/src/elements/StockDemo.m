//
//  TGPlane.m
//  
//
//  Created by victor on 12/15/12.
//
//

#import "StockDemo.h"
#import "SettingsVC.h"
#import "Texture.h"

#import "GridPlane.h"
#import "SphereOid.h"
#import "Torus.h"

#import "Fire.h"
#import "Cloud.h"
#import "Pool.h"

typedef enum shaderType {
    fire,
    cloud,
    pool,
    
    ALL_SHADER_TYPES
} shaderType;

@interface StockDemo () {
    float _rot;
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
    self.needsRewire = true;
}

-(void)setGeometryName:(NSString *)geometryName
{
    _geometryName = geometryName;
    self.needsRewire = true;
}

-(void)createShader
{
    Class klass = NSClassFromString(_shaderName);
    self.shader = [klass new];
}

-(void)update:(NSTimeInterval)dt
{
    _rot += 1;
    GLKVector3 rot = { GLKMathDegreesToRadians(_rot), 0, 0 };
    self.rotation = rot;
}

-(void)createTexture
{
    if( _shaderType == pool )
    {
        self.texture = [[Texture alloc] initWithFileName:@"pool.png"];
    }
}

-(void)getTextureLocations
{
    if( _shaderType == pool )
    {
        self.texture.uLocation = [self.shader location:pool_sampler];
    }
}

-(void)createBuffer
{
    MeshBuffer * buffer;
    NSArray * indicesIntoNames;
    bool UVs = false;
    
    if( _shaderType == fire )
        indicesIntoNames = @[@(fv_position),@(fv_normal)];
    else if( _shaderType == pool )
        indicesIntoNames = @[@(pool_position),@(pool_normal)];
    else if( _shaderType == cloud )
        indicesIntoNames = @[@(cld_position),@(cld_normal)];
    
    if( [_geometryName isEqualToString:@"GridPlane"] )
    {
        buffer = [GridPlane gridWithIndicesIntoNames:indicesIntoNames
                                            andDoUVs:UVs
                                        andDoNormals:true];
    }
    else if( [_geometryName isEqualToString:@"Torus"] )
    {
        buffer = [Torus torusWithIndicesIntoNames:indicesIntoNames
                                         andDoUVs:UVs
                                     andDoNormals:true];
    }
    else
    {
        buffer = [SphereOid sphereWithdIndicesIntoNames:indicesIntoNames
                                               andDoUVs:UVs
                                           andDoNormals:true];
    }
    
    [self addBuffer:buffer];    
}

-(NSArray *)getSettings
{
    NSArray * arr = [super getSettings];
    NSDictionary * shaders = @{ @"Cloud": @"Clouds", @"Fire":@"Fire", @"Pool": @"Pool" };    
    
    SettingsDescriptor * sd1;
    sd1 = [[SettingsDescriptor alloc] initWithControlType: SC_Picker
                                               memberName: @("shaderName")
                                                labelText: @"Effect"
                                                  options: @{@"values":shaders,
                                                    @"target":self, @"key":@"shaderName"}
                                             initialValue: _shaderName
                                                 priority: SHADER_SETTINGS];

    NSDictionary * shapes = @{ @"SphereOid": @"Ball", @"GridPlane":@"Board", @"Torus":@"Donut" };
    
    SettingsDescriptor * sd2;
    sd2 = [[SettingsDescriptor alloc] initWithControlType: SC_Picker
                                               memberName: @("shapeName")
                                                labelText: @"Shape"
                                                  options: @{@"values":shapes,
                                                    @"target":self, @"key":@"geometryName"}
                                             initialValue: _geometryName
                                                 priority: SHADER_SETTINGS];

    return [arr arrayByAddingObjectsFromArray:@[sd1,sd2]];
    
}

@end
