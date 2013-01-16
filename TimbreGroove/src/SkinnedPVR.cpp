//
//  SkinnedPVR.cpp
//  TimbreGroove
//
//  Created by victor on 1/15/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#include "SkinnedPVR.h"
#include <string.h>
#include "OGLES2Tools.h"

// Camera constants used to generate the projection matrix
const float g_fCameraNear	= 4.0f;
const float g_fCameraFar	= 5000.0f;

const float g_fDemoFrameRate = 0.015f;

enum EVertexAttrib {
	VERTEX_ARRAY, NORMAL_ARRAY, TEXCOORD_ARRAY, BONEWEIGHT_ARRAY, BONEINDEX_ARRAY, eNumAttribs };
const char* g_aszAttribNames[] = {
	"inVertex", "inNormal", "inTexCoord", "inBoneWeight", "inBoneIndex" };

// shader uniforms
enum EUniform {
	eMVPMatrix, eViewProj, eLightDirModel, eLightDirWorld, eBoneCount, eBoneMatrices, eBoneMatricesIT, eNumUniforms };
const char* g_aszUniformNames[] = {
	"MVPMatrix", "ViewProjMatrix", "LightDirModel", "LightDirWorld", "BoneCount", "BoneMatrixArray[0]", "BoneMatrixArrayIT[0]" };


class OGLES2Skinning
{
	// 3D Model
	CPVRTModelPOD	m_Scene;
    // POD scene file name
    CPVRTString m_psSceneFile;
    
	// Model transformation variables
	PVRTMat4	m_Transform;
	float		m_fAngle;
	float		m_fDistance;
    
	GLuint	m_uiVertShader;
	GLuint	m_uiFragShader;
	GLuint*	m_puiVbo;
	GLuint*	m_puiIndexVbo;
    
	// Group shader programs and their uniform locations together
	struct
	{
		GLuint uiId;
		GLuint auiLoc[eNumUniforms];
	}
	m_ShaderProgram;
    
    
	unsigned long m_iTimePrev;
	float	m_fFrame;
    
    CPVRTString  m_psFragShaderSrcFile;
    CPVRTString m_psVertShaderSrcFile;
    
	GLuint * m_puiTextures;
	GLuint * m_uiTextures;
    CPVRTString * m_ppTextureFiles;
    CPVRTString * m_ppTextureNames;
    int m_numTextures;    
    
	bool InitApplication();
	bool ReleaseView();
	bool LoadTextures(CPVRTString* pErrorStr);
	bool LoadShaders(CPVRTString* pErrorStr);
	void LoadVbos();
    
	void DrawMesh(int i32NodeIndex);
    
    bool m_paused;
    
public:
    OGLES2Skinning( char *psSceneFile, char **ppTextureFiles, char **ppTextureName, int numTextures );
    ~OGLES2Skinning();
    bool RenderScene();
    void Pause() { m_paused = true; }
    void Resume() { m_paused = false; }
};

PVR_SKINNER Skinner_Get(char *psSceneFile, char **ppTextureFiles, char **ppTextureName, int numTextures )
{
    return (PVR_SKINNER) new OGLES2Skinning(psSceneFile,ppTextureFiles,ppTextureName,numTextures);
}

void Skinner_Render(PVR_SKINNER skinner)
{
    ((OGLES2Skinning *)skinner)->RenderScene();
}

void Skinner_Destroy(PVR_SKINNER skinner)
{
    delete ((OGLES2Skinning *)skinner);
}

void Skinner_Pause(PVR_SKINNER skinner)
{
   // ((OGLES2Skinning *)skinner)->Pause();
}

void Skinner_Resume(PVR_SKINNER skinner)
{
    ((OGLES2Skinning *)skinner)->Resume();
}

OGLES2Skinning::OGLES2Skinning( char *psSceneFile, char **ppTextureFiles, char **ppTextureName, int numTextures )
:   m_psSceneFile(psSceneFile),
    m_psFragShaderSrcFile("skinned.fsh"),
    m_psVertShaderSrcFile("skinned.vsh"),
    m_paused(false)
{
    m_numTextures = numTextures;
    if( numTextures )
    {
        m_ppTextureFiles = new CPVRTString[numTextures];
        m_ppTextureNames = new CPVRTString[numTextures];
        m_uiTextures      = new GLuint[numTextures];
        for( int i = 0; i < numTextures; i++ )
        {
            m_ppTextureFiles[i] = ppTextureFiles[i];
            m_ppTextureNames[i] = ppTextureName[i];
            m_uiTextures[i] = -1UL;
        }
    }
    else
    {
        m_uiTextures = NULL;
        m_ppTextureFiles = NULL;
    }

    InitApplication();
}

OGLES2Skinning::~OGLES2Skinning()
{
    ReleaseView();
    
	m_Scene.Destroy();
    
	delete [] m_puiVbo;
	delete [] m_puiIndexVbo;
    
    delete [] m_ppTextureFiles;
    delete [] m_ppTextureNames;
    delete [] m_uiTextures;
}


bool OGLES2Skinning::LoadTextures(CPVRTString* const pErrorStr)
{
    for( int i = 0; i < m_numTextures; i++)
    {
        if(PVRTTextureLoadFromPVR(m_ppTextureFiles[i].c_str(),m_uiTextures+i) != PVR_SUCCESS)
        {
            *pErrorStr = "ERROR: Failed to load texture.";
            return false;
        }
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }
        
	return true;
}

bool OGLES2Skinning::LoadShaders(CPVRTString* pErrorStr)
{
	if (PVRTShaderLoadFromFile(NULL, // no support for bin shaders on iOS
                               m_psVertShaderSrcFile.c_str(),
                               GL_VERTEX_SHADER,
                               GL_SGX_BINARY_IMG,
                               &m_uiVertShader,
                               pErrorStr) != PVR_SUCCESS)
	{
		return false;
	}
    
	if (PVRTShaderLoadFromFile(NULL,
                               m_psFragShaderSrcFile.c_str(),
                               GL_FRAGMENT_SHADER,
                               GL_SGX_BINARY_IMG,
                               &m_uiFragShader,
                               pErrorStr) != PVR_SUCCESS)
	{
		return false;
	}
    
	if (PVRTCreateProgram(&m_ShaderProgram.uiId, m_uiVertShader, m_uiFragShader, g_aszAttribNames, eNumAttribs, pErrorStr) != PVR_SUCCESS)
	{
		EnvExitMsg(  pErrorStr->c_str());
		return false;
	}
    
	for (int i = 0; i < eNumUniforms; ++i)
	{
		m_ShaderProgram.auiLoc[i] = glGetUniformLocation(m_ShaderProgram.uiId, g_aszUniformNames[i]);
	}
    
	return true;
}

void OGLES2Skinning::LoadVbos()
{
	if (!m_puiVbo)      m_puiVbo = new GLuint[m_Scene.nNumMesh];
	if (!m_puiIndexVbo) m_puiIndexVbo = new GLuint[m_Scene.nNumMesh];
    
	/*
     Load vertex data of all meshes in the scene into VBOs
     
     The meshes have been exported with the "Interleave Vectors" option,
     so all data is interleaved in the buffer at pMesh->pInterleaved.
     Interleaving data improves the memory access pattern and cache efficiency,
     thus it can be read faster by the hardware.
     */
    
	glGenBuffers(m_Scene.nNumMesh, m_puiVbo);
    
	for (unsigned int i = 0; i < m_Scene.nNumMesh; ++i)
	{
		// Load vertex data into buffer object
		SPODMesh& Mesh = m_Scene.pMesh[i];
		unsigned int uiSize = Mesh.nNumVertex * Mesh.sVertex.nStride;
        
		glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[i]);
		glBufferData(GL_ARRAY_BUFFER, uiSize, Mesh.pInterleaved, GL_STATIC_DRAW);
        
		// Load index data into buffer object if available
		m_puiIndexVbo[i] = 0;
        
		if (Mesh.sFaces.pData)
		{
			glGenBuffers(1, &m_puiIndexVbo[i]);
			uiSize = PVRTModelPODCountIndices(Mesh) * sizeof(GLshort);
			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[i]);
			glBufferData(GL_ELEMENT_ARRAY_BUFFER, uiSize, Mesh.sFaces.pData, GL_STATIC_DRAW);
		}
	}
    
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

bool OGLES2Skinning::InitApplication()
{
    CPVRTString ErrorStr;
    
	m_puiVbo = 0;
	m_puiIndexVbo = 0;
    
	CPVRTResourceFile::SetReadPath((char*)EnvGet(prefReadPath));
	CPVRTResourceFile::SetLoadReleaseFunctions(NULL,NULL);
    
	if (m_Scene.ReadFromFile(m_psSceneFile.c_str()) != PVR_SUCCESS)
	{
		EnvExitMsg(  "ERROR: Couldn't load the .pod file\n");
		return false;
	}
    
	// The cameras are stored in the file. We check it contains at least one.
#ifdef DEBUG
	if (m_Scene.nNumCamera == 0)
	{
		EnvExitMsg(  "ERROR: The scene does not contain a camera\n");
		return false;
	}
    
	// Check the scene contains at least one light
	if (m_Scene.nNumLight == 0)
	{
		EnvExitMsg(  "ERROR: The scene does not contain a light\n");
		return false;
	}
#endif
    
	m_fFrame = 0;
	m_iTimePrev = EnvGetTime();
	m_Transform = PVRTMat4::Identity();
	m_fAngle = 0.0f;
	m_fDistance = 0.0f;
    
    // the rest of this method was
    // moved from per-context-switch InitView() to
    // one-time only per instance.
    
	LoadVbos();

	if (!LoadTextures(&ErrorStr))
	{
		EnvExitMsg(  ErrorStr.c_str());
		return false;
	}

	if (!LoadShaders(&ErrorStr))
	{
		EnvExitMsg(  ErrorStr.c_str());
		return false;
	}
    
	glUniform1i(glGetUniformLocation(m_ShaderProgram.uiId, "sTexture"), 0);
    
	/*
     Initialise an array to lookup the textures
     for each material in the scene.
     */
	m_puiTextures = new GLuint[m_Scene.nNumMaterial];
    for( int i = 0; i < m_numTextures; i++ )
    {
		SPODMaterial* pMaterial = &m_Scene.pMaterial[i];
        
        for (int n = 0; n < m_numTextures; n++ )
        {
            if (m_ppTextureNames[n] == pMaterial->pszName)
            {
                m_puiTextures[i] = m_uiTextures[n];
                break;
            }
        }
        
    }
	return true;
}

bool OGLES2Skinning::ReleaseView()
{
    glDeleteTextures(m_numTextures, m_puiTextures);
	glDeleteProgram(m_ShaderProgram.uiId);
	glDeleteShader(m_uiVertShader);
	glDeleteShader(m_uiFragShader);
	glDeleteBuffers(m_Scene.nNumMesh, m_puiVbo);
	glDeleteBuffers(m_Scene.nNumMesh, m_puiIndexVbo);
	delete[] m_puiTextures;
        
	return true;
}

bool OGLES2Skinning::RenderScene()
{
    if( m_paused )
        return true;
    
    GLboolean isCullFace = glIsEnabled(GL_CULL_FACE);
	glCullFace(GL_BACK);
	glEnable(GL_CULL_FACE);
	glEnable(GL_DEPTH_TEST);
	glClearColor(0.6f, 0.8f, 0.6f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	glUseProgram(m_ShaderProgram.uiId);
	glActiveTexture(GL_TEXTURE0);
    
	/*
     Calculates the frame number to animate in a time-based manner.
     Uses the shell function EnvGetTime() to get the time in milliseconds.
     */
	unsigned long iTime = EnvGetTime();
    
    // This is all lame and coming out RSN
    // The model matrix will come from the
    // obj-c framework though (yet another)
    // C helper function:
    
	if(iTime > m_iTimePrev)
	{
		float fDelta = (float) (iTime - m_iTimePrev);
		m_fFrame += fDelta * g_fDemoFrameRate;
        
		bool bRebuildTransformation = false;
        
		if(EnvDidTouchHappen(EnvDirectionRIGHT))
		{
			m_fAngle -= 0.03f;
            
			if(m_fAngle < PVRT_TWO_PIf)
				m_fAngle += PVRT_TWO_PIf;
            
			bRebuildTransformation = true;
		}
        
		if(EnvDidTouchHappen(EnvDirectionLEFT))
		{
			m_fAngle += 0.03f;
            
			if(m_fAngle > PVRT_TWO_PIf)
				m_fAngle -= PVRT_TWO_PIf;
            
			bRebuildTransformation = true;
		}
        
		if(EnvDidTouchHappen(EnvDirectionUP))
		{
			m_fDistance -= 10.0f;
            
			if(m_fDistance < -500.0f)
				m_fDistance = -500.0f;
            
			bRebuildTransformation = true;
		}
        
		if(EnvDidTouchHappen(EnvDirectionDOWN))
		{
			m_fDistance += 10.0f;
            
			if(m_fDistance > 200.0f)
				m_fDistance = 200.0f;
            
			bRebuildTransformation = true;
		}
        
		if(bRebuildTransformation)
			m_Transform = PVRTMat4::Translation(0,0, m_fDistance) * PVRTMat4::RotationY(m_fAngle);
        
	}
    
	m_iTimePrev	= iTime;
    
	if(m_fFrame > m_Scene.nNumFrame - 1)
		m_fFrame = 0;
    
	// Set the scene animation to the current frame
	m_Scene.SetFrame(m_fFrame);
    
	/*
     Set up camera
     */
	PVRTVec3	vFrom, vTo, vUp(0, 1, 0);
	PVRTMat4 mView, mProjection;
	float fFOV;
    
	// We can get the camera position, target and field of view (fov) with GetCameraPos()
	fFOV = m_Scene.GetCamera(vFrom, vTo, vUp, 0);
    
	/*
     We can build the model view matrix from the camera position, target and an up vector.
     For this we use PVRTMat4::LookAtRH().
     */
	mView = PVRTMat4::LookAtRH(vFrom, vTo, vUp);
    
	// Calculate the projection matrix
	bool bRotate = false; // EnvGet(prefIsRotated) && EnvGet(prefFullScreen);
#define ASPC (float)EnvGeti(prefWidth)/(float)EnvGeti(prefHeight)
	mProjection = PVRTMat4::PerspectiveFovRH(fFOV, ASPC, g_fCameraNear, g_fCameraFar, PVRTMat4::OGL, bRotate);
    
	// Read the light direction from the scene
	PVRTVec4 vLightDirWorld = PVRTVec4( 0, 0, 0, 0 );
	vLightDirWorld = m_Scene.GetLightDirection(0);
	glUniform3fv(m_ShaderProgram.auiLoc[eLightDirWorld], 1, &vLightDirWorld.x);
    
	// Set up the View * Projection Matrix
	PVRTMat4 mViewProjection;
    
	mViewProjection = mProjection * mView;
	glUniformMatrix4fv(m_ShaderProgram.auiLoc[eViewProj], 1, GL_FALSE, mViewProjection.ptr());
    
	/*
     A scene is composed of nodes. There are 3 types of nodes:
     - MeshNodes :
     references a mesh in the pMesh[].
     These nodes are at the beginning of the pNode[] array.
     And there are nNumMeshNode number of them.
     This way the .pod format can instantiate several times the same mesh
     with different attributes.
     - lights
     - cameras
     To draw a scene, you must go through all the MeshNodes and draw the referenced meshes.
     */
	for (unsigned int i32NodeIndex = 0; i32NodeIndex < m_Scene.nNumMeshNode; ++i32NodeIndex)
	{
		SPODNode& Node = m_Scene.pNode[i32NodeIndex];
        
		// Get the node model matrix
		PVRTMat4 mWorld;
		mWorld = m_Scene.GetWorldMatrix(Node);
        
		// Set up shader uniforms
		PVRTMat4 mModelViewProj;
		mModelViewProj = mViewProjection * mWorld;
		glUniformMatrix4fv(m_ShaderProgram.auiLoc[eMVPMatrix], 1, GL_FALSE, mModelViewProj.ptr());
        
		PVRTVec4 vLightDirModel;
		vLightDirModel = mWorld.inverse() * vLightDirWorld;
		glUniform3fv(m_ShaderProgram.auiLoc[eLightDirModel], 1, &vLightDirModel.x);
        
		// Loads the correct texture using our texture lookup table
		if(Node.nIdxMaterial == -1)
			glBindTexture(GL_TEXTURE_2D, 0); // It has no pMaterial defined. Use blank texture (0)
		else
			glBindTexture(GL_TEXTURE_2D, m_puiTextures[Node.nIdxMaterial]);
        
		DrawMesh(i32NodeIndex);
	}
    
    if( !isCullFace )
        glDisable(GL_CULL_FACE);
    
	return true;
}

void OGLES2Skinning::DrawMesh(int i32NodeIndex)
{
	SPODNode& Node = m_Scene.pNode[i32NodeIndex];
	SPODMesh& Mesh = m_Scene.pMesh[Node.nIdx];
    
	glBindBuffer(GL_ARRAY_BUFFER, m_puiVbo[Node.nIdx]);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_puiIndexVbo[Node.nIdx]);
	glEnableVertexAttribArray(VERTEX_ARRAY);
	glEnableVertexAttribArray(NORMAL_ARRAY);
	glEnableVertexAttribArray(TEXCOORD_ARRAY);
	glVertexAttribPointer(VERTEX_ARRAY, 3, GL_FLOAT, GL_FALSE, Mesh.sVertex.nStride,  Mesh.sVertex.pData);
	glVertexAttribPointer(NORMAL_ARRAY, 3, GL_FLOAT, GL_FALSE, Mesh.sNormals.nStride, Mesh.sNormals.pData);
	glVertexAttribPointer(TEXCOORD_ARRAY, 2, GL_FLOAT, GL_FALSE, Mesh.psUVW[0].nStride, Mesh.psUVW[0].pData);
    
	/*
     If the current mesh has bone index and weight data then we need to
     set up some additional variables in the shaders.
     */
	if(Mesh.sBoneIdx.n && Mesh.sBoneWeight.n)
	{
		glEnableVertexAttribArray(BONEINDEX_ARRAY);
		glEnableVertexAttribArray(BONEWEIGHT_ARRAY);
        
		glVertexAttribPointer(BONEINDEX_ARRAY, Mesh.sBoneIdx.n, GL_UNSIGNED_BYTE, GL_FALSE, Mesh.sBoneIdx.nStride, Mesh.sBoneIdx.pData);
		glVertexAttribPointer(BONEWEIGHT_ARRAY, Mesh.sBoneWeight.n, GL_UNSIGNED_BYTE, GL_TRUE, Mesh.sBoneWeight.nStride, Mesh.sBoneWeight.pData);
        
		/*
         There is a limit to the number of bone matrices that you can pass to the shader so we have
         chosen to limit the number of bone matrices that affect a mesh to 8. However, this does
         not mean our character can only have a skeleton consisting of 8 bones. We can get around
         this by using bone batching where the character is split up into sub-meshes that are only
         affected by a sub set of the overal skeleton. This is why we have this for loop that
         iterates through the bone batches contained with the SPODMesh.
         */
		for (int i32Batch = 0; i32Batch < Mesh.sBoneBatches.nBatchCnt; ++i32Batch)
		{
			// Set the number of bones that will influence each vertex in the mesh
			glUniform1i(m_ShaderProgram.auiLoc[eBoneCount], Mesh.sBoneIdx.n);
            
			// Go through the bones for the current bone batch
			PVRTMat4 amBoneWorld[8];
			PVRTMat3 afBoneWorldIT[8], mBoneIT;
            
			int i32Count = Mesh.sBoneBatches.pnBatchBoneCnt[i32Batch];
            
			for(int i = 0; i < i32Count; ++i)
			{
				int i32NodeID = Mesh.sBoneBatches.pnBatches[i32Batch * Mesh.sBoneBatches.nBatchBoneMax + i];
				amBoneWorld[i] = m_Transform * m_Scene.GetBoneWorldMatrix(Node, m_Scene.pNode[i32NodeID]);
				afBoneWorldIT[i] = PVRTMat3(amBoneWorld[i]).inverse().transpose();
			}
            
			glUniformMatrix4fv(m_ShaderProgram.auiLoc[eBoneMatrices], i32Count, GL_FALSE, amBoneWorld[0].ptr());
			glUniformMatrix3fv(m_ShaderProgram.auiLoc[eBoneMatricesIT], i32Count, GL_FALSE, afBoneWorldIT[0].ptr());
            
			/*
             As we are using bone batching we don't want to draw all the faces contained within pMesh, we only want
             to draw the ones that are in the current batch. To do this we pass to the drawMesh function the offset
             to the start of the current batch of triangles (Mesh.sBoneBatches.pnBatchOffset[i32Batch]) and the
             total number of triangles to draw (i32Tris)
             */
			int i32Tris;
			if(i32Batch+1 < Mesh.sBoneBatches.nBatchCnt)
				i32Tris = Mesh.sBoneBatches.pnBatchOffset[i32Batch+1] - Mesh.sBoneBatches.pnBatchOffset[i32Batch];
			else
				i32Tris = Mesh.nNumFaces - Mesh.sBoneBatches.pnBatchOffset[i32Batch];
            
			size_t offset = sizeof(GLushort) * 3 * Mesh.sBoneBatches.pnBatchOffset[i32Batch];
			glDrawElements(GL_TRIANGLES, i32Tris * 3, GL_UNSIGNED_SHORT, (void*) offset);
		}
        
		glDisableVertexAttribArray(BONEINDEX_ARRAY);
		glDisableVertexAttribArray(BONEWEIGHT_ARRAY);
	}
	else
	{
		glUniform1i(m_ShaderProgram.auiLoc[eBoneCount], 0);
		glDrawElements(GL_TRIANGLES, Mesh.nNumFaces*3, GL_UNSIGNED_SHORT, 0);
	}
    
	glDisableVertexAttribArray(VERTEX_ARRAY);
	glDisableVertexAttribArray(NORMAL_ARRAY);
	glDisableVertexAttribArray(TEXCOORD_ARRAY);
    
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

