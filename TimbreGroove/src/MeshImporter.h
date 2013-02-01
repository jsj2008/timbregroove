#import "TG3dObject.h"
#import "View.h"

@interface MeshImporter : TG3dObject<ViewDelegate>

@property (nonatomic,strong) NSString * meshName;
@end