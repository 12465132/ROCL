

__constant int SEED = 0;
__constant float ERR =.0000001;
__constant int hash[] = {208,34,231,213,32,248,233,56,161,78,24,140,71,48,140,254,245,255,247,247,40,
                     185,248,251,245,28,124,204,204,76,36,1,107,28,234,163,202,224,245,128,167,204,
                     9,92,217,54,239,174,173,102,193,189,190,121,100,108,167,44,43,77,180,204,8,81,
                     70,223,11,38,24,254,210,210,177,32,81,195,243,125,8,169,112,32,97,53,195,13,
                     203,9,47,104,125,117,114,124,165,203,181,235,193,206,70,180,174,0,167,181,41,
                     164,30,116,127,198,245,146,87,224,149,206,57,4,192,210,65,210,129,240,178,105,
                     228,108,245,148,140,40,35,195,38,58,65,207,215,253,65,85,208,76,62,3,237,55,89,
                     232,50,217,64,244,157,199,121,252,90,17,212,203,149,152,140,187,234,177,73,174,
                     193,100,192,143,97,53,145,135,19,103,13,90,135,151,199,91,239,247,33,39,145,
                     101,120,99,3,186,86,99,41,237,203,111,79,220,135,158,42,30,154,120,67,87,167,
                     135,176,183,191,253,115,184,21,233,58,129,233,142,39,128,211,118,137,139,255,
                     114,20,218,113,154,27,127,246,250,1,8,198,250,209,92,222,173,21,88,102,219};
float dot2( float3 v ) { return dot(v,v); }
struct Data{
float minSDFDist;
int index;
};
struct L {
	float3  color;		// diffuse color
	bool reflection;	// has reflection 
	bool refraction;	// has refraction
	float n;			// refraction index
	float roughness;	// Cook-Torrance roughness
	float fresnel;		// Cook-Torrance fresnel reflectance
	float density;		// Cook-Torrance color density i.e. fraction of diffuse reflection

};

struct triangle{
    float3 p1;    
    float3 p2;
    float3 p3;
    float R;
    struct L L;    
};
float udTriangle( float3 p, struct triangle t )
{
  float3 ba = t.p2 - t.p1; 
  float3 cb = t.p3 - t.p2;
  if(fabs(ba.x)<=ERR&&fabs(ba.y)<=ERR&&fabs(ba.z)<=ERR&&fabs(cb.x)<=ERR&&fabs(cb.y)<=ERR&&fabs(cb.z)<=ERR){
    return distance(p,t.p1)-t.R;
  }
  float3 ac = t.p1 - t.p3;   
  float3 pa = p - t.p1;
  float3 pb = p - t.p2;
  float3 pc = p - t.p3;
  float3 nor = cross( ba, ac );
  return sqrt(
    (sign(dot(cross(ba,nor),pa)) +
     sign(dot(cross(cb,nor),pb)) +
     sign(dot(cross(ac,nor),pc))<2.0)
     ?
     min( min(
     dot2(ba*clamp(dot(ba,pa)/dot2(ba),0.0,1.0)-pa),
     dot2(cb*clamp(dot(cb,pb)/dot2(cb),0.0,1.0)-pb) ),
     dot2(ac*clamp(dot(ac,pc)/dot2(ac),0.0,1.0)-pc) )-t.R
     :
     dot(nor,pa)*dot(nor,pa)/dot2(nor) )-t.R;
}

int noise2(int x, int y)
{
    int tmp = hash[(y + SEED) % 256];
    return hash[(tmp + x) % 256];
}

float lin_inter(float x, float y, float s)
{
    return x + s * (y-x);
}

float smooth_inter(float x, float y, float s)
{
    return lin_inter(x, y, s * s * (3-2*s));
}

float noise2d(float x, float y)
{
    int x_int = x;
    int y_int = y;
    float x_frac = x - x_int;
    float y_frac = y - y_int;
    int s = noise2(x_int, y_int);
    int t = noise2(x_int+1, y_int);
    int u = noise2(x_int, y_int+1);
    int v = noise2(x_int+1, y_int+1);
    float low = smooth_inter(s, t, x_frac);
    float high = smooth_inter(u, v, x_frac);
    return smooth_inter(low, high, y_frac);
}

float perlin2d(float x, float y, float freq, int depth)
{
    float xa = x*freq;
    float ya = y*freq;
    float amp = 1.0;
    float fin = 0;
    float div = 0.0;

    int i;
    for(i=0; i<depth; i++)
    {
        div += 256 * amp;
        fin += noise2d(xa, ya) * amp;
        amp /= 2;
        xa *= 2;
        ya *= 2;
    }

    return fin/div;
}

float3 hash33( float3 p )      // this hash is not production ready, please
{                        // replace this by something better
	p = (float3)( dot(p,(float3)(127.1,311.7, 74.7)),
			  dot(p,(float3)(269.5,183.3,246.1)),
			  dot(p,(float3)(113.5,271.9,124.6)));
    float3 a = 0;
	return -1.0 + 2.0*fract(sin(p)*43758.5453123,&a);
}
float hash11(float q){
    float3 p = (float3)(q);
  	p = (float3)( dot(p,(float3)(127.1,311.7, 74.7)),
			  dot(p,(float3)(269.5,183.3,246.1)),
			  dot(p,(float3)(113.5,271.9,124.6)));
    float3 a = 0;
	return fract(sin(p)*43758.5453123,&a).x;
  
}
// struct L {
// 	float3  color;		// diffuse color
// 	bool reflection;	// has reflection 
// 	bool refraction;	// has refraction
// 	float n;			// refraction index
// 	float roughness;	// Cook-Torrance roughness
// 	float fresnel;		// Cook-Torrance fresnel reflectance
// 	float density;		// Cook-Torrance color density i.e. fraction of diffuse reflection

// };
// struct triangle{
//     float3 p1;    
//     float3 p2;
//     float3 p3;
//     float R;
//     struct L L;    
// };

genNormal()
Data SDFGlobal(float3 p, read_only image2d_t triangles){
    
}
vec3 camoffset (vec3 v,vec2 o){
    return normalize(
        vec3(v.x,v.y,v.z))+
        normalize(vec3(-(v.y),(v.x),0.))*
        o.x+normalize(vec3(-v.z*v.x,-v.z*v.y,v.x*v.x+v.y*v.y))*o.y;
        }
Data init(){Data OD;OD.SDFDist = 10000000.,OD.typeindex=-1,OD.index=-1;return OD;}
struct Camera{vec3 V,C;}C;
struct Light{vec3 C,S;}L;
const float 
distOutFCCAM 		= 40.f,
GlowValue 			= 1000.,
Glowscale 			= 5.,
GlowValue2 			= 100.,
Glowscale2 			= 1.,
GlowMult2 			= .0,
reflection			= .8;
const int //performace <-> precision
RenderDistance 		= 100,
stepcount 			= 70,
bouncecount 		= 4;
__kernel void render(
    sampler_t sampler_host,
    read_only image2d_t triangles, //float3 
    //h(1)=p1
    //h(2)=p2
    //h(3)=p3
    //h(4).x=radius
    //h(4).y=n
    //h(4).z=conditional
    //when (h(4).z==1) : ((reflection==false) &&(refraction==false))
    //when (h(4).z==2) : ((reflection==false) &&(refraction==true ))
    //when (h(4).z==3) : ((reflection==true ) &&(refraction==false))
    //when (h(4).z==4) : ((reflection==true ) &&(refraction==true ))
    //h(5).x=roughness
    //h(5).y=fresnel
    //h(5).z=density
    read_only image2d_t src_image1,
    read_only image2d_t src_image2,
    write_only image2d_t dst_image1,
    write_only image2d_t dst_image2,
    int frameintg,
    float time
) 
{
    
    int2 coord = (int2)(get_global_id(0),get_global_id(1));
    float2 uv = (float2)(((float)get_global_id(0)+.001)/(float)(get_global_size(0)),((float)get_global_id(1)+.001)/(float)get_global_size(1));
    float2 i = (float2)(1.00/get_global_size(0),0/get_global_size(1));
    float2 j = (float2)(0/get_global_size(0),1.00/get_global_size(1));
    float loop_time = 10;
    // float time = fmod(t,loop_time); 
    float b = .25;///increse for stronger gpu
    float p = 5.;
    float4 pixel = read_imagef(src_image2, sampler_host,uv);//lastframe
    float noise = clamp(round((.5+half_exp(3-b*time))*hash11(perlin2d(time+get_group_id(0),time+get_group_id(1),.01,2))),0.,1.);
    float noisefactor = 1;
    if(noise>0.){
    pixel *= frameintg/(frameintg+p);
    float4 noisyimage = read_imagef(src_image1, sampler_host,uv)
    +noisefactor*(float4)(
        (hash11(perlin2d(500.+time+get_global_id(0),100.+time+get_global_id(1),.01,20))-.5),
        (hash11(perlin2d(2.00+time+get_global_id(0),2.00+time+get_global_id(1),.01,20))-.5),
        (hash11(perlin2d(2.00+time+get_global_id(1),2.00+time+get_global_id(0),.01,20))-.5),1.
    );
    pixel += noisyimage*p/(frameintg+p);
    }
    // pixel = read_imagef(src_image1, sampler_host,uv)
    // +noisefactor*(float4)(
    //     (hash11(perlin2d(500.+time+get_global_id(0),100.+time+get_global_id(1),.01,20))-.5),
    //     (hash11(perlin2d(2.00+time+get_global_id(0),2.00+time+get_global_id(1),.01,20))-.5),
    //     (hash11(perlin2d(2.00+time+get_global_id(1),2.00+time+get_global_id(0),.01,20))-.5),1.
    // );
    // pixel = noise;
    pixel = (float4)(pixel.xyz,1.);
    write_imagef(dst_image1, coord,pixel);
}////    