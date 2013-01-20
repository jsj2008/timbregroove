//
//  FullScreenTouch.fsh
//  created with Shaderific
//


uniform mediump vec2 touchCoordinates[10];

varying mediump vec2 textureCoordinate;

const mediump float radius = 0.05;


void main(void)
{

    mediump vec2 pixelCoordinate = textureCoordinate;


    mediump vec3 color;

    if (distance(touchCoordinates[0], pixelCoordinate) < radius) {
    
        color = vec3(1.0, 0.0, 0.0);
        
    } else if (distance(touchCoordinates[1], pixelCoordinate) < radius) {
    
        color = vec3(0.0, 1.0, 0.0);
        
    } else if (distance(touchCoordinates[2], pixelCoordinate) < radius) {
    
        color = vec3(0.0, 0.0, 1.0);
        
    } else if (distance(touchCoordinates[3], pixelCoordinate) < radius) {
    
        color = vec3(1.0, 1.0, 0.0);
        
    } else if (distance(touchCoordinates[4], pixelCoordinate) < radius) {
    
        color = vec3(1.0, 0.0, 1.0);
        
    } else if (distance(touchCoordinates[5], pixelCoordinate) < radius) {
    
        color = vec3(0.0, 1.0, 1.0);

    } else if (distance(touchCoordinates[6], pixelCoordinate) < radius) {
    
        color = vec3(1.0, 0.5, 0.0);
        
    } else if (distance(touchCoordinates[7], pixelCoordinate) < radius) {
    
        color = vec3(0.3, 0.0, 0.3);

    } else if (distance(touchCoordinates[8], pixelCoordinate) < radius) {
    
        color = vec3(0.67, 0.47, 0.26);
        
    } else if (distance(touchCoordinates[9], pixelCoordinate) < radius) {
    
        color = vec3(1.0, 1.0, 1.0);
        
    } else {
           
        color = vec3(0.0, 0.0, 0.0);
              
    }
    
    gl_FragColor = vec4(color, 1.0);
    
}