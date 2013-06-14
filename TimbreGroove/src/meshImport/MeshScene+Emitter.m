//
//  MeshScene+Emitter.m
//  TimbreGroove
//
//  Created by victor on 4/4/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "MeshScene.h"
#import "Log.h"
#import "Painter.h"
#import "Material.h"

NSString * stringFromMat(GLKMatrix4 m)
{
    return [NSString stringWithFormat:@"{ %G, %G, %G, %G,   %G, %G, %G, %G,   %G, %G, %G, %G,   %G, %G, %G, %G }",
            m.m[0], m.m[1], m.m[2],  m.m[3],  m.m[4],  m.m[5],  m.m[6],  m.m[7],
            m.m[8], m.m[9], m.m[10], m.m[11], m.m[12], m.m[13], m.m[14], m.m[15] ];
}

NSString * stringFromColor(GLKVector4 c)
{
    return [NSString stringWithFormat:@"{ %.4f, %4f, %.4f, %.4f }", c.r, c.g, c.b, c.a];
}

@implementation MeshScene (Emitter)

-(void)emit
{
    NSString * baseName = self.fileName;

    TGLogp(LLMeshImporter, @"//\n// Imported COLLADA: %@//\n",baseName);
    TGLogp(LLMeshImporter, @"#ifndef  %@_import_geo_included",baseName);
    TGLogp(LLMeshImporter, @"#define  %@_import_geo_included\n",baseName);


    NSRegularExpression * regex = [[NSRegularExpression alloc] initWithPattern:@"[^a-zA-Z0-9]" options:0 error:nil];
    
    NSString * (^cleanName)(NSString *) = ^NSString *(NSString * name)
    {
        return [regex stringByReplacingMatchesInString:name options:0 range:(NSRange){0,[name length]} withTemplate:@"_"];
        
    };
    
    printf("#pragma mark GEOMETRY \n\n");

    static const char * gvs[] = {
        "pos", "normal", "uv", "color", "boneIndex", "boneWeights"
    };
    
    NSArray * elemTypes = @[ @"GLKVector3", @"GLKVector3", @"GLKVector2", @"GLKVector4",
                             @"GLKVector4", @"GLKVector4" ];
    
    __block int nCount = 0;
    __block int meshCount = 0;
    [_meshes each:^(MeshSceneMeshNode * meshNode) {

        [meshNode->_geometries each:^(MeshGeometry *mg) {
            
            NSString * meshName = cleanName(mg->_name);
            NSString * typeName = [NSString stringWithFormat:@"%@_%@_strides_%d", baseName, meshName, meshCount];
            
            
            TGLogp(LLMeshImporter, @"typedef struct _%@ { ", typeName);
            for( int i = 0; i < mg->_numStrides; i++ )
            {
                VertexStride * vs = &mg->_strides[ i ];
                TGLogp(LLMeshImporter, @"  %@   %s;", elemTypes[vs->indexIntoShaderNames], gvs[vs->indexIntoShaderNames] );
            }
            TGLogp(LLMeshImporter, @"} %@;\n", typeName);

            
            TGLogp(LLMeshImporter, @"%@ _%@_%@_buffer_%d[] = { ",typeName, baseName, meshName, meshCount);
            float * p = mg->_buffer;
            for( int v = 0; v < mg->_numVertices; v++ )
            {
                printf("{ ");
                for( int i = 0; i < mg->_numStrides; i++ )
                {
                    VertexStride * vs = &mg->_strides[ i ];
                    for( int s = 0; s < vs->numbersPerElement; s++ )
                    {
                        if( s )
                            printf( ", " );
                        printf( "%G", *p++ );                        
                    }
                    printf("  ");
                }
                const char comma = v == mg->_numVertices - 1 ? ' ' : ',';
                printf("}%c\n",comma);
            }
            printf( "  };\n");
            ++meshCount;
        }];
    }];

    TGLogp(LLMeshImporter, @"\n#endif // %@_import_geo_included\n\n-----------------------\n\n",baseName);
    

    TGLogp(LLMeshImporter, @"//\n// Imported COLLADA: %@//\n",baseName);
    TGLogp(LLMeshImporter, @"#ifndef  %@_import_included",baseName);
    TGLogp(LLMeshImporter, @"#define  %@_import_included\n",baseName);
    
    printf("#ifndef  _import_structs_defined\n");
    printf("#define  _import_structs_defined\n");
    printf("typedef struct _Joint {\n  const char *name;\n  const char *parent;\n  GLKVector3 startingPos;\n  GLKMatrix4 transform;\n  GLKMatrix4 invBind;\n  GLKMatrix4 world;\n  struct _Joint *_parent;\n} Joint;\n\n");
    printf("typedef struct _MaterialDesc {\n  GLKVector4 ambient, diffuse, specular, emission;\n  float shininess;\n  bool doSpecular;\n  const char *textureFileName;\n} MaterialDesc;\n\n");
    printf("typedef struct _Animation {\n GLKMatrix4* transforms;\n float *keyFrames;\n Joint *target;\n unsigned int numFrames;\n} Animation;\n\n");
    printf("#endif\n\n");
    
    
    nCount = 0;
    meshCount = 0;
    [_meshes each:^(MeshSceneMeshNode * meshNode) {
        
        NSString * meshName = cleanName(meshNode->_name);
        
        if( meshNode->_materials )
        {
            [meshNode->_materials each:^(NSString * name, NSArray * mats) {
                TGLogp(LLMeshImporter, @"MaterialDesc %@_%@_%@_materials[] = { ", baseName, meshName, name);
                int matCount = [mats count];
                __block int matCounter = 0;
                [mats each:^(NSObject * obj) {
                    if( [obj isKindOfClass:[Material class]] )
                    {
                        Material * mat = (Material *)obj;
                        MaterialColors mc = mat.colors;
                        TGLogp(LLMeshImporter,
                               @"   { .ambient = %@, .diffuse = %@,\n    .specular = %@, .emission = %@,\n    .shininess = %f, .doSpecular = %s }%s",
                               stringFromColor(mc.ambient),  stringFromColor(mc.diffuse),
                               stringFromColor(mc.specular), stringFromColor(mc.emission),
                               mat.shininess, mat.doSpecular ? "true" : "false", ++matCounter == matCount ? "" : "," );
                    }
                    else if( [obj isKindOfClass:[Texture class]] )
                    {
                        Texture * tex = (Texture *)obj;
                        TGLogp(LLMeshImporter, @" { .textureFileName = \"%s\" }%s", tex.fileName, ++matCounter == matCount ? "" : ",");
                    }
                }];
                TGLogp(LLMeshImporter, @"};\n");
            }];
        }
        else
        {
            //TGLogp(LLMeshImporter, @"MaterialDesc %@_%@_%@_materials[] = {};\n", baseName, msmn->_name, name);
        }
    }];
    
    NSMutableArray * allJointNames = [NSMutableArray new];
    
    static void (^dumpBones)(id,MeshSceneArmatureNode *) = nil;
    
    dumpBones = ^(id key, MeshSceneArmatureNode * node) {
        
        NSString * name = cleanName(node->_name);
        [allJointNames addObject:name];
        
        GLKVector3 vec3 = POSITION_FROM_MAT(node->_world);
        TGLogp(LLMeshImporter, @"Joint %@_%@_joint = {", baseName, name);
        TGLogp(LLMeshImporter, @"  \"%@\",", name);
        TGLogp(LLMeshImporter, @"  \"%@\",", node->_parent ? cleanName(node->_parent->_name) : @"" );
        TGLogp(LLMeshImporter, @"  %@,", NSStringFromGLKVector3(vec3));
        
        TGLogp(LLMeshImporter, @"  %@,", stringFromMat(node->_transform));
        TGLogp(LLMeshImporter, @"  %@,", stringFromMat(node->_invBindMatrix));
        TGLogp(LLMeshImporter, @"  %@",  stringFromMat(node->_world));
        
        TGLogp(LLMeshImporter, @"};\n");
        
        if( node->_children )
            [node->_children each:dumpBones];
    };
    
    printf("#pragma mark BONES\n\n");
    
    [_allJoints each:^(id sender) { dumpBones(nil,sender); }];
    
    dumpBones = nil;
    
    
    nCount = 0;
    [_meshes each:^(MeshSceneMeshNode * meshNode) {

        if( meshNode->_influencingJoints )
        {
            NSString * meshName = cleanName(meshNode->_name);
            NSUInteger inflJointCount = [meshNode->_influencingJoints count];
            nCount = 0;
            TGLogp(LLMeshImporter, @"Joint * %@_%@_influencingJoints[%d] = { ", baseName, meshName, inflJointCount);
            [meshNode->_influencingJoints each:^(MeshSceneArmatureNode *jnode) {
                TGLogp(LLMeshImporter, @"  &%@_%@_joint%s  // %d", baseName,jnode->_name,++nCount == inflJointCount ? "" : ",", nCount);
            }];
            TGLogp(LLMeshImporter, @"};\n");
        }
    }];
    
    if( _animations )
    {
        printf("#pragma mark ANIMATION\n\n");
        
        int count = 0;
        int acount = 0;
        for( MeshAnimation * animation in _animations )
        {
            NSString * name = cleanName(animation->_target->_name);
            TGLogp(LLMeshImporter,@"GLKMatrix4 %@_%@_animationFrames[] = { ", baseName, name);
            for( int i = 0; i < animation->_numFrames; i++ )
            {
                TGLogp(LLMeshImporter,@"%@%s // Frame[%d] at %fsec",
                       stringFromMat(animation->_transforms[i]),
                       i + 1 < animation->_numFrames ? "," : "",
                       i, animation->_keyFrames[i] );
            }
            TGLogp(LLMeshImporter,@"\n}; // end %@_%@_animationFrames\n", baseName, name);
            ++count;
            
            TGLogp(LLMeshImporter,@"float %@_%@_animationKeyFrames[] = { ", baseName, name);
            for( int i = 0; i < animation->_numFrames; i++ )
            {
                TGLogp(LLMeshImporter,@"%f%s // Frame[%d]",
                       animation->_keyFrames[i],
                       i + 1 < animation->_numFrames ? "," : "",
                       i  );
            }
            TGLogp(LLMeshImporter,@"\n}; // end %@_%@_animationKeyFrames\n", baseName, name);
            
        };
        
        TGLogp(LLMeshImporter, @"GLKMatrix4 * %@_animation[] = { \n", baseName);
        for( MeshAnimation * animation in _animations )
        {
            NSString * name = cleanName(animation->_target->_name);
            ++acount;
            TGLogp(LLMeshImporter,@"   %@_%@_animationFrames%s", baseName, name, acount == count ? "" : ",");
        }
        TGLogp(LLMeshImporter, @"};\n");
        
        for( MeshAnimation * animation in _animations )
        {
            NSString * tn = cleanName(animation->_target->_name);
            TGLogp(LLMeshImporter, @"Animation %@_%@_animation = {\n  .transforms = %@_%@_animationFrames,\n  .keyFrames = %@_%@_animationKeyFrames,\n  .numFrames = %d,\n  .target = &%@_%@_joint\n};\n",
                   baseName, tn, baseName, tn, baseName, tn, animation->_numFrames, baseName, tn );
        }
        
        acount = 0;
        TGLogp(LLMeshImporter, @"Animation * %@_animations[%d] = { \n", baseName, count);
        for( MeshAnimation * animation in _animations )
        {
            NSString * tn = cleanName(animation->_target->_name);
            TGLogp(LLMeshImporter,@"   &%@_%@_animation%s", baseName, tn, ++acount == count ? "" : ",");
        }
        TGLogp(LLMeshImporter, @"};\n");
    }
    
    
    TGLogp(LLMeshImporter, @"\n#endif // %@_import_included\n\n",baseName);
    
    cleanName = nil;
    regex = nil;
    
}
@end
