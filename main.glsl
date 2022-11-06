#ifdef GL_ES
precision mediump float;
#endif

#define PI 3.141592653359
#define PI_2 1.5707963267

#define CAMERA_P vec3(0.0, 0.0, 5.0)
#define CENTER_P vec2(0.5, 0.5)


struct pool_ball {
    vec3 color;
    vec2 origin;

    bool striped;
    int number;
};


uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

vec4 blend_rgba (vec4 a, vec4 b) {
    float an = mix(b.w, 1.0, a.w);
    vec3 rgb = mix(b.w * b.xyz, a.xyz, a.w);
    float f = (an > 0.001 ? (1.0 / an) : 1.0);
    return vec4(f * rgb, an);
}

mat3 rotation3d(vec3 axis, float angle) {
  axis = normalize(axis);
  float s = sin(angle);
  float c = cos(angle);
  float oc = 1.0 - c;

  return mat3(
    oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
    oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
    oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c
  );
}

vec4 ball_color_at (vec3 sphere_pos, float r, float d, vec3 color, bool striped) {
    vec4 result = vec4(0.0);

    const vec3 highlight = vec3(0.9137, 0.898, 0.7608);
    const float edge = 0.005;

    float sr = r * 0.45;
    float h = 0.6 * r;
    vec2 circle_pos = sphere_pos.xy;

    result = blend_rgba(vec4(
        color, 
        1.0
        ), result);  // add ball default to result

    if (striped && abs(circle_pos.y) > h) {  // create stripe
        if (r - length(circle_pos) < edge && abs(circle_pos.y) > h + edge) {
            result = vec4(0);  // remove default if on edge
        }
        result = blend_rgba(vec4(
            highlight, 
            smoothstep(0.0, edge, abs(circle_pos.y) - h)
            ), result);  // add the stripe to result
    }

    if (length(circle_pos) < sr) {  // inside of inner circle
        result = blend_rgba(vec4(
            highlight, 
            smoothstep(0.0, edge, sr - length(circle_pos))
            ), result);  // add inner circle to ball
    }        

    result.a = smoothstep(0.0, edge, r - d);

    return result;
}

vec4 get_light (vec3 frag_pos, vec3 light_source) {

    // normal vector plesase
    vec3 light = vec3(1.0, 1.0, 1.0);
    
    float ambiance = 0.2;

    vec3 normal = normalize(frag_pos);
    vec3 light_dir = normalize(light_source - frag_pos);

    float diffuse = max(dot(normal, light_dir), 0.0);
    
    vec3 view_dir = normalize(CAMERA_P - frag_pos);
    vec3 reflection = reflect(-light_dir, normal);

    float specular = pow(max(dot(view_dir, reflection), 0.0), 2.0) * 0.4;


    return vec4(light * (ambiance + diffuse + specular), 1.0);

}

vec4 number (vec2 frag_pos) {

    vec2 circle_pos = frag_pos - vec2(0.5);
    
     

    return vec4(0.0);
}

void main () {  // display pool ball

    vec2 mouse = u_mouse/u_resolution - CENTER_P;
    vec3 light_source = vec3(mouse.xy*6.0,4.0);
    vec2 st = (gl_FragCoord.xy/u_resolution);

    vec4 background = vec4(0.0, 0.0, 0.0, 1.0);

    pool_ball balls[15];
    balls[0] = pool_ball(
            vec3(0.2549, 0.0941, 0.0),
            vec2(0.5),
            true,
            15
        );

    vec4 color;
    for (int i = 0; i < 1; i++) {  // generate pool balls
        float radius = 0.2;

        vec2 circle_pos = st - balls[i].origin;
        float d = length(circle_pos);
        if (d < radius) {

            float theta;
            if (abs(circle_pos.x) > 0.0) {
                theta = asin(circle_pos.x / (radius * cos(atan(circle_pos.y, circle_pos.x))));
            }
            else {
                theta = asin(circle_pos.y / radius);
            }
            vec3 sphere_pos = vec3(circle_pos.x, circle_pos.y, radius*cos(theta));

            vec4 fc = ball_color_at(
                sphere_pos * rotation3d(
                    vec3(1.0, 0.0, 1.0), u_time
                    ), 
                radius, d,
                balls[i].color, balls[i].striped);
            vec4 fl = get_light(sphere_pos, light_source);
        
            color = blend_rgba(color, fc * fl);
        }
    }

    gl_FragColor = vec4(blend_rgba(color, background ));

}