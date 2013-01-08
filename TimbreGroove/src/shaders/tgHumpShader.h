//
//  tgHumpShader.h
//  TG1
//
//  Created by victor on 11/10/12.
//
//

#import "Isgl3dCustomShader.h"

@interface tgHumpShader : Isgl3dCustomShader
+ (id) shaderWithKey:(NSString *)key;
- (id) initWithKey:(NSString *)key;
- (void)moveApexBy:(float)x y:(float)y z:(float)z;
- (Isgl3dGLTexture *)setTextureFile:(NSString *)fileName;
@property (nonatomic) float * apex;
@end
