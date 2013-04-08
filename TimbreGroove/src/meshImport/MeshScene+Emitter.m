//
//  MeshScene+Emitter.m
//  TimbreGroove
//
//  Created by victor on 4/4/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "MeshScene.h"
#import "Log.h"
#import "Generic.h"

static void dumpMatrix(GLKMatrix4 m)
{
    TGLogp(LLMeshImporter, NSStringFromGLKMatrix4(m));
    /*
    printf("{ %+.4G, %+.4G, %+.4G, %+.4G, \n  %+.4G, %+.4G, %+.4G, %+.4G, \n  %+.4G, %+.4G, %+.4G, %+.4G, \n  %+.4G, %+.4G, %+.4G, %+.4G }",
           m.m00, m.m01, m.m02, m.m03,
           m.m10, m.m11, m.m12, m.m13,
           m.m20, m.m21, m.m22, m.m23,
           m.m30, m.m31, m.m32, m.m33 );
    */
}

@implementation MeshScene (Emitter)

-(void)emitSkin:(MeshSkinning *)skin
{
    unsigned int   currPos  = 0;
    int            ji       = 0;
    int            wi;
    float          weight;
    
    NSArray * jointNames = [skin->_influencingJoints map:^id(MeshSceneArmatureNode * joint) {
        return joint->_name;
    }];
    
    TGLogp(LLMeshImporter, @" { ");
    
    for( int i = 0; i < skin->_numInfluencingJointCounts; i++ )
    {
        int numberOfJointsApplied = skin->_influencingJointCounts[ i ];
        
        for( unsigned int n = 0; n < numberOfJointsApplied; n++  )
        {
            ji = skin->_packedWeightIndices[ currPos + skin->_jointWOffset ];
            wi = skin->_packedWeightIndices[ currPos + skin->_weightFOffset];
            currPos += 2;
            weight = skin->_weights[ wi ];
            char comma = (i+1 == skin->_numInfluencingJointCounts) && (n+1 == numberOfJointsApplied) ? ' ' : ',';
            TGLogp(LLMeshImporter, @"  %.4f%c // [%02d][%d] %@", weight, comma, i, n, jointNames[ji]);
        }
    }
    TGLogp(LLMeshImporter, @" };\n");
    
}
-(void)emit
{
    NSString * baseName = self.fileName;

    TGLogp(LLMeshImporter, @"// Imported COLLADA: %@",baseName);
    TGLogp(LLMeshImporter, @"#ifndef  %@_import_included",baseName);
    TGLogp(LLMeshImporter, @"#define  %@_import_included\n\n",baseName);

    MeshSkinning * skin = _mesh->_skin;
    if( skin )
    {
        TGLogp(LLMeshImporter, @"GLKMatrix4 %@_bindShapeMatrix = (GLKMatrix4)",baseName);
        dumpMatrix(skin->_bindShapeMatrix); printf(";\n\n");
        TGLogp(LLMeshImporter, @"float %@_weights[] = ",baseName);
        [self emitSkin:skin];
    }
    
    if( _animations )
    {
        for( MeshAnimation * animation in _animations )
        {
            TGLogp(LLMeshImporter,@"GLKMatrix4 %@_%@_animationFrames[] = { ", baseName, animation->_target->_name);
            
            for( int i = 0; i < animation->_numFrames; i++ )
            {
                TGLogp(LLMeshImporter,@"\n// Frame[%d] at %fsec ", i, animation->_keyFrames[i]);
                dumpMatrix(animation->_transforms[i]);
                if( i + 1 < animation->_numFrames )
                    printf(",\n");
            }
            TGLogp(LLMeshImporter,@"\n}; // end %@_%@_animationFrames", baseName, animation->_target->_name);
            
        };
    }
    
    static void (^dumpBones)(id,MeshSceneArmatureNode *) = nil;
    
    dumpBones = ^(id key, MeshSceneArmatureNode * node) {
        
        NSString * parentName = node->_parent ? node->_parent->_name : @"none";
        GLKVector4 vec4 = GLKMatrix4GetRow(node->_world, 3);
        TGLogp(LLMeshImporter, @"\n//-------------\"%@\" joint at {%.4f, %.4f, %.4f} parent: %@\n",
               node->_name, vec4.x, vec4.y, vec4.z, parentName );
        TGLogp(LLMeshImporter, @"GLKMatrix4 %@_%@_transform = (GLKMatrix4)",baseName, node->_name);
        dumpMatrix(node->_transform);
        TGLogp(LLMeshImporter, @";\n\nGLKMatrix4 %@_%@_world = (GLKMatrix4)",baseName, node->_name);
        dumpMatrix(node->_world);
        TGLogp(LLMeshImporter, @";\n\nGLKMatrix4 %@_%@_invBindPose = (GLKMatrix4)",baseName, node->_name);
        dumpMatrix(node->_invBindPoseMatrix);
        TGLogp(LLMeshImporter, @";\n");
        if( node->_children )
            [node->_children each:dumpBones];
    };
    
    dumpBones(nil, _armatureTree);
    
    static char * varname[] = {
        "gv_pos",
        "gv_normal",
        "gv_uv",
        "gv_acolor",
        "gv_boneIndex",
        "gv_boneWeights"
    };
    
    static GenericVariables indexIntoNamesMap[kNumMeshSemanticKeys] = {
        gv_pos,         // MSKPosition
        gv_normal,      // MSKNormal
        gv_uv,          // MSKUV
        gv_acolor,      // MSKColor
        gv_boneIndex,   // MSKBoneIndex,
        gv_boneWeights, // MSKBoneWeights,
        
    };
    
    MeshGeometry * geometry = _mesh->_geometry;
    if( !geometry )
        geometry = _mesh->_skin->_geometry;
    
    for( int b = 0; b < 3; b ++ )
    {
        MeshGeometryBuffer * bufferInfo = geometry->_buffers + b;
        if( !bufferInfo->data )
            continue;
        
        TGLogp(LLMeshImporter, @"GLKVector3 %@_%s[%d] = {",
               baseName,
               varname[indexIntoNamesMap[b]],
               bufferInfo->numFloats/bufferInfo->stride);
        
        float *p = bufferInfo->data;
        int count = bufferInfo->numFloats;
        for( int i = 0; i < count;  )
        {
            for( int r = 0; r < 3 && i < count; r++  )
            {
                printf("{");
                char * comma = "";
                for( int s = 0; s < bufferInfo->stride; s++ )
                { printf( "%s %+.3f ",comma, p[i++]); comma = ","; }
                if( i + 1 < count )
                    printf("}, ");
                else
                    printf("}");
            }
            printf("\n");
        }
        printf("};\n");
        
        if( bufferInfo->indexData )
        {
            TGLogp(LLMeshImporter, @"unsigned int %@_%s_index[%d] = {",
                   baseName,
                   varname[indexIntoNamesMap[b]],
                   bufferInfo->numIndices );
            
            unsigned int *p = bufferInfo->indexData;
            int count = bufferInfo->numIndices;
            int i;
            for( i = 0; i < count;  )
            {
                for( int r = 0; r < 3 && i < count; r++  )
                {
                    printf(" ");
                    char * comma = "";
                    for( int s = 0; s < 3; s++ )
                    {
                        printf( "%s %d",comma,p[i++]);
                        comma = ",";
                    }
                    if( i + 1 < count )
                        printf(", ");
                }
                printf("\n");
            }
            printf("};\n");
            
#ifdef EMIT_FLATTENED_INDEX
            TGLogp(LLMeshImporter, @"GLKVector3 %@_%s_flat[%d] = {",
                   baseName,
                   varname[indexIntoNamesMap[b]],
                   bufferInfo->numIndices );
            {
                
                MeshGeometryBuffer * b = bufferInfo;
                unsigned int elementSize = b->stride;
                float * old = b->data;
                unsigned int * idx = b->indexData;
                int i;
                for( int x = 0; x < b->numIndices; x++ )
                {
                    i = *idx++ * elementSize;
                    printf(" { ");
                    char *comma = "";
                    for( int e = 0; e < elementSize; e++ )
                    {
                        float f = old[i + e];
                        printf( "%s %+.3f", comma, f );
                        comma = ",";
                    }
                    printf(" },");
                    if( (x+1) % 3 == 0 )
                        printf("\n");
                }
                printf("};\n");
            }
#endif
        }
    }
    TGLogp(LLMeshImporter, @"#endif // %@_import_included",baseName);
    
}
@end
