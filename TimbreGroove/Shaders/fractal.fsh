//
//  Created by victor on 11/20/12.
//  Copyright (c) 2012 Ass Over Tea Kettle. All rights reserved.
//
precision highp float;

uniform vec2 u_complexConstant;
uniform float u_viewportSize;
uniform float u_blend;
uniform vec4  u_backColor;

void main(void)
{
    const int nMaxIter = 128;
    
    float R = 3.5 * (gl_FragCoord.x - u_viewportSize / 2.0)  / u_viewportSize - 0.25;
    float I = 3.5 * (gl_FragCoord.y - u_viewportSize / 2.0)  / u_viewportSize;
    
    float Real0 = R;
    float Imag0 = I;
    
    int LastIter;
    float fRealConstant = u_blend * u_complexConstant.x + (1.0 - u_blend ) * Real0;
    float fImagConstant = u_blend * u_complexConstant.y + (1.0 - u_blend ) * Imag0;
    
    float R2 = R*R;
    float I2 = I*I;
    
    for(int iter = 0; iter < nMaxIter; iter ++)
    {
		I=(R+R)*I + fImagConstant;
		R=R2-I2 + fRealConstant;
        
		R2=R*R;
		I2=I*I;
		
		LastIter = iter ;
        
		if( R2+I2 > 4.0 )
			break;
	}
	
    if (LastIter  == nMaxIter-1)
    {
		gl_FragColor = u_backColor;
    }
    else
    {
        float fValue = mod(float(LastIter),2.0);
        float angle = 2.0 * 3.14 * float(LastIter) / float(nMaxIter) ;
        gl_FragColor = vec4(1.0 - (0.5+0.5*cos(angle*2.0)),
                            1.0 - (0.5+0.5*cos(angle*3.0)),
                            1.0 - (0.5+0.5*cos(angle*5.0)),
                            0.7);
        vec3 x = gl_FragColor.rgb;
        if( x.r < 0.1 && x.g < 0.1 ) //  && x.b < 0.1 )
//        if( gl_FragColor.rgb == vec3(0.0))
        {
            gl_FragColor = u_backColor; // vec4(0.5);
        }
    }
}
