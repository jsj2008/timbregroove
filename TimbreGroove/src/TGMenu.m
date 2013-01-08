//
//  TGMenu.m
//  TG1
//
//  Created by victor on 12/8/12.
//
//

#import "TG.h"
#import "TGMenu.h"
#import "TGMenuItem.h"

@interface TGMenu() {
@protected
    NSDictionary * m_meta;
    NSString * m_internalName;
    
    TGMenu * m_showingSubmenu;
    TGMenu * m_subMenuOf;
}

@end
@implementation TGMenu

- (id) initWithName: (NSString *)name
{	
	if ((self = [super init])) {
        
        m_internalName = name;
        [self initCameraAndScene];
        
	}
	
	return self;
}

- (id) initWithMeta:(NSDictionary *)meta
{
    if( (self = [super init])) {
        m_meta = meta;
        [self initCameraAndScene];
        [self getMenuItems];
    }
    
    return self;
}

- (void)initCameraAndScene
{
    [self.camera setPerspectiveProjection: 30
                                     near: 1
                                      far: 400
                              orientation: self.deviceViewOrientation];
    
    self.camera.position = iv3(0, 0, TG_BUTTON_CAMERA_Z);
    
    self.scene.isVisible = false;
}

- (void) setLevel:(unsigned int)level
{
    _level = level;
    CGRect rc = self.viewport;
    rc.size.width = (level+1) * TG_MENU_WIDTH;
    rc.origin.x = level * TG_MENU_WIDTH;
    self.viewport = rc;
}

- (NSDictionary *)readMenuMeta:(NSString *)name
{
	NSString * menuPath = [[NSBundle mainBundle] pathForResource:@"menus"
                                                                 ofType:@"plist" ];
	NSDictionary * rootMenu = [NSDictionary dictionaryWithContentsOfFile:menuPath];
	
	m_meta = [rootMenu objectForKey:name];
    
    return m_meta;
}

- (void)getMenuItems
{
    if( !m_meta )
        [self readMenuMeta:m_internalName];
    
    [self createBackground];
    
    NSString * key;
    
    NSUInteger count = [m_meta count];
    
    // default pos is at 0, middle of the screen
    CGFloat y = (TG_BUTTON_EDGE*(count/2.0f));
    
    for( key in m_meta )
    {
        NSDictionary * menuItem = [m_meta objectForKey:key];
        NSString * imageName    = [menuItem objectForKey:@"icon"];
        NSString * renderClass  = [menuItem objectForKey:@"renderClass"];
        Class klass = NSClassFromString(renderClass);
        
        TGMenuItem * mi = [klass imageName:imageName
                                    target:self
                                   selector:@selector(menuItemSelect:) ];
        
        Isgl3dVector3 position = { 0, y, TG_BUTTON_Z };
        mi.position = position;

        mi.meta         = menuItem;
        mi.subMenuMeta  = [menuItem objectForKey:@"items"];

        [self.scene addChild:mi];
        
        y -= (TG_BUTTON_EDGE * 1.01f);
    }

}

- (void)createBackground
{
    Isgl3dTextureMaterial * mat = [Isgl3dTextureMaterial materialWithTextureFile:@"faded.png"
                                                                       shininess:0.9
                                                                       precision:Isgl3dTexturePrecisionMedium
                                                                         repeatX:YES
                                                                         repeatY:YES];
    
    Isgl3dPlane           * pln = [[Isgl3dPlane alloc] initWithGeometry:1000 height:1000 nx:4 ny:4];
    Isgl3dMeshNode        * nod = [self.scene createNodeWithMesh:pln andMaterial:mat];
    
    nod.y = 0;
    nod.z = TG_BUTTON_Z - 0.00001f;
    
}

- (void)menuItemSelect:(id)sender
{
    TGMenuItem * mi = ((Isgl3dEvent3D *)sender).object;

    if( mi.subMenuMeta )
    {
        TGMenu * subMenu = [[TGMenu alloc] initWithMeta:mi.subMenuMeta];
        subMenu.level = self.level + 1;
        [[Isgl3dDirector sharedInstance] addView:subMenu];
        mi.subMenu = subMenu;
        mi.subMenuMeta = nil;
    }
    
    if( mi.subMenu )
    {
        m_showingSubmenu = mi.subMenu;
        mi.subMenu->m_subMenuOf = self;
        [mi.subMenu showMenu];
    }
    else
    {
        if( !mi.target )
        {
            NSString * className = [mi.meta objectForKey:@"handler"];
            Class klass = NSClassFromString(className);
            mi.target = [klass new];
        }
        
        [[self findTop] hideMenu];
        [mi.target invoke];
    }
}

- (TGMenu *)findTop
{
    TGMenu * top = self;
    
    while( top.level > 0 )
        top = top->m_subMenuOf;
    
    return top;
}

- (void)showMenu
{
    if( !m_meta )
        [self getMenuItems];

    self.x = -self.width;
    self.scene.isVisible = true;
    
    [self animateProp:"x" targetVal:(_level*TG_MENU_WIDTH) hide:false];
}

- (void)hideMenu
{
    if( m_showingSubmenu != nil )
    {
       [m_showingSubmenu hideMenu];
        m_showingSubmenu = nil;
    }
    
    m_subMenuOf = nil;

    [self animateProp:"x" targetVal:-self.width hide:true];
}

- (void)toggleShowHide
{
    if( self.scene.isVisible )
       [self hideMenu];
    else
        [self showMenu];
}
@end
