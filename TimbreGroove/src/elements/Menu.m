//
//  TGMenu.m
//  TimbreGroove
//
//  Created by victor on 12/15/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#import "Camera.h"
#import "Menu.h"
#import "MenuItem.h"
#import "MenuView.h"
#import "GridPlane.h"
#import "Generic.h"
#import "GenericShader.h"
#import "Texture.h"
#import "MeshBuffer.h"
#import "Tweener.h"

#define MENU_SHADER_NAME "menu"

const char * _menuShaderVars[] = {
    "a_position",
    "a_uv",
    "u_pvm",
    "u_shadowDraw",
    "u_shadowStrength",
    "u_lightDir"
};

typedef enum MenuShaderVars {
    msv_pos,
    msv_uv,
    MSV_LAST_ATTR = msv_uv,
    msv_pvm,
    msv_shadowDraw,
    msv_shadowStrength,
    msv_lightDir,
    MSV_NUM_NAMES
} MenuShaderVars;

@interface MenuShader : Shader
@property (nonatomic) GLKVector3 lightDir;
@property (nonatomic) bool shadowDraw;
@property (nonatomic) float shadowStrength;
@end

@implementation MenuShader

-(id)init
{
    return [super initWithVertex:MENU_SHADER_NAME
                     andFragment:MENU_SHADER_NAME
                     andVarNames:_menuShaderVars
                     andNumNames:MSV_NUM_NAMES
                     andLastAttr:MSV_LAST_ATTR
                      andHeaders:nil];
}

-(void)setLightDir:(GLKVector3)lightDir
{
    _lightDir = lightDir;
    [self writeToLocation:msv_lightDir type:TG_VECTOR3 data:lightDir.v];
}
-(void)setShadowDraw:(bool)shadowDraw
{
    _shadowDraw = shadowDraw;
    [self writeToLocation:msv_shadowDraw type:TG_BOOL data:&shadowDraw];
}
-(void)setShadowStrength:(float)shadowStrength
{
    _shadowStrength = shadowStrength;
    [self writeToLocation:msv_shadowStrength type:TG_FLOAT data:&shadowStrength];
}

@end

@interface Menu() {

    Menu * _showingSubmenu;
    Menu * _subMenuOf;
    
    MenuShader * _shader;
}
@property (nonatomic) float lightFactor;
@end


@implementation Menu

-(id)wireUp
{
    [super wireUp];
    
    NSArray * indices = @[@(msv_pos),@(msv_uv)];
    
    _buffer = [GridPlane gridWithIndicesIntoNames:indices
                                         andDoUVs:true
                                     andDoNormals:false];
    
    _shader = [MenuShader new];
    
    [_buffer getLocations:_shader];
    
    [self getMenuItems];
    return self;
}

-(void)willBecomeVisible
{
    _lightFactor = 1.0;
    
    NSDictionary * params = @{
TWEEN_DURATION: @0.8f,
TWEEN_TRANSITION: TWEEN_FUNC_EASEINSINE,
    @"lightFactor": @(-1.0f)
    };
    [Tweener addTween:self withParameters:params];
}

-(void)isInFullView
{
//    _lightFactor = -1.0;
}

-(void)render:(NSUInteger)w h:(NSUInteger)h
{
    GLboolean dpTest = glIsEnabled(GL_DEPTH_TEST);
    glDisable(GL_DEPTH_TEST);
    
    [_shader use];
    [_buffer bind];

    for( MenuItem * mi in self.children )
    {
        bool disabled = mi.disabled;
        
        GLKMatrix4 mv = mi.modelView;
        [mi.texture bind:0];
        
        if( !disabled )
        {
            float ss = (1.0 - ((_lightFactor * 0.5) + 0.5)) * 0.8;
            _shader.shadowStrength = ss;
            _shader.shadowDraw = true;
            GLKMatrix4 m = GLKMatrix4Rotate(mv, GLKMathDegreesToRadians(65), 1, 0, 0);
            m = GLKMatrix4Translate(m, 0, -1.0, 0);
            [_shader writeToLocation:msv_pvm type:TG_MATRIX4 data:m.m];
            [_buffer draw];
        }
        
        _shader.shadowDraw = false;
        float lightFactor = disabled ? 1.0 : _lightFactor;
        _shader.lightDir = (GLKVector3){ lightFactor, 0, -1 };
        [_shader writeToLocation:msv_pvm type:TG_MATRIX4 data:mv.m];
        [_buffer draw];
        
        
        [mi.texture unbind];
    }
    [_buffer unbind];
    
    if( dpTest )
        glEnable(GL_DEPTH_TEST);    
}

- (NSDictionary *)readMenuMeta:(NSString *)name
{
	NSString * menuPath = [[NSBundle mainBundle] pathForResource:@"menus"
                                                          ofType:@"plist" ];
	NSDictionary * rootMenu = [NSDictionary dictionaryWithContentsOfFile:menuPath];
	
	_meta = [rootMenu objectForKey:name];
    
    return _meta;
}

-(MenuView *)menuView
{
    return (MenuView *)self.view;
}

- (void)getMenuItems
{
    if( !_meta )
        [self readMenuMeta:@"main"];
    
    NSDictionary *placementKeys = @{ @"top": @(mp_top), @"bottom": @(mp_bottom) };
    
    NSArray *sortedKeys = [_meta
                           keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2)
                        {
                            return [(NSNumber *)obj1[@"order"] compare:obj2[@"order"]];
                        }];
    
    
    GLint textureLocation = [_shader location:gv_sampler];
    
    for( NSString *key in sortedKeys )
    {
        NSDictionary * menuItem = _meta[key];
        NSString * imageName    = menuItem[@"icon"];
        NSString * renderClass  = menuItem[@"renderClass"];
        NSString * placementKey = menuItem[@"placement"];
        Class klass             = NSClassFromString(renderClass);
        
        MenuItem * mi = [[klass alloc] init];
        
        mi.placement       = placementKey ? [placementKeys[placementKey] intValue] : mp_top;
        mi.meta            = menuItem;
        mi.name            = key;
        mi.texture         = [[Texture alloc] initWithFileName:imageName];

        mi.texture.uLocation = textureLocation;
        
        [mi wireUp];
        [self appendChild:mi];
    }

    [self repositionItems];
}

-(void)repositionItems
{
    CGSize screenSz = self.view.frame.size;
    float px = 1.0 / screenSz.width;
    float py = 1.0 / screenSz.height;
    float szX = MENU_ITEM_SIZE * px;
    float szY = MENU_ITEM_SIZE * py;
    float paddingY = 10 * py;
    
    float topY    = 1.0 - (2.0*szY);
    float bottomY = -topY;
 
    for( MenuItem * mi in self.children )
    {
        if( mi.placement == mp_top )
        {
            mi.position = (GLKVector3){ 0, topY, 0 };
            topY -= (2.0*szY + paddingY);
        }
        else if( mi.placement == mp_bottom )
        {
            mi.position = (GLKVector3){ 0, bottomY, 0 };
            bottomY += (2.0*szY + paddingY);
        }
        mi.scale    = (GLKVector3){ szX, szY, 0 };
    }
}
@end
