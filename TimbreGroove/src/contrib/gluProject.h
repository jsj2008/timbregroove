//
//  gluProject.h
//  TimbreGroove
//
//  Created by victor on 12/17/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//

#ifndef TimbreGroove_gluProject_h
#define TimbreGroove_gluProject_h

/* static */ GLboolean gluUnProject(GLfloat winx, GLfloat winy, GLfloat winz,
                                    const GLfloat model[16], const GLfloat proj[16],
                                    const GLint viewport[4],
                                    GLfloat * objx, GLfloat * objy, GLfloat * objz);

/* static */ GLboolean gluProject(GLfloat objx, GLfloat objy, GLfloat objz,
                                  const GLfloat model[16], const GLfloat proj[16],
                                  const GLint viewport[4],
                                  GLfloat * winx, GLfloat * winy, GLfloat * winz);

#endif
