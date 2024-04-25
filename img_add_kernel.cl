
// #define MOLLER_TRUMBORE
// #define CULLING

__constant int SEED = 0;
__constant float ERR =.00000001;
__constant int //performace <-> precision
    RenderDistance 		= 100,
    stepcount 			= 70,
    bouncecount 		= 4;

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
struct Camera{
    float3 P,V,C;//point, cam.Cection, color
    };
struct Data{
    float3 intersectPoint;
    int index;
    bool isIntersect;
    };
struct RTI{
    bool isIntersect;
    float3 P;
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
    struct L L;    
    };

float dot2( float3 v ) { return dot(v,v); }
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
float hash11(float q)
    {
    float3 p = (float3)(q);
  	p = (float3)( dot(p,(float3)(127.1,311.7, 74.7)),
			  dot(p,(float3)(269.5,183.3,246.1)),
			  dot(p,(float3)(113.5,271.9,124.6)));
    float3 a = 0;
	return fract(sin(p)*43758.5453123,&a).x;
  
    }
//comments
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
struct Data init(){
    struct Data OD;
    OD.intersectPoint = (float3)(100000000.);
    OD.index=-1;
    OD.isIntersect=false;
    return OD;}
struct RTI intersectF(){
    struct RTI T;
    T.isIntersect = false;
    T.P = (float3)(-1.);
    return T;
    }
struct RTI intersectT(float3 B){
    struct RTI T;
    T.isIntersect = true;
    T.P = B;
    return T;
    }
float udTriangle( float3 p, float3 p1, float3 p2, float3 p3, float R){
  float3 ba = p2 - p1; 
  float3 cb = p3 - p2;
  if(fabs(ba.x)<=ERR&&fabs(ba.y)<=ERR&&fabs(ba.z)<=ERR&&fabs(cb.x)<=ERR&&fabs(cb.y)<=ERR&&fabs(cb.z)<=ERR){
    return distance(p,p1)-R;
  }
  float3 ac = p1 - p3;   
  float3 pa = p - p1;
  float3 pb = p - p2;
  float3 pc = p - p3;
  float3 nor = cross( ba, ac );
  return sqrt(
    (sign(dot(cross(ba,nor),pa)) +
     sign(dot(cross(cb,nor),pb)) +
     sign(dot(cross(ac,nor),pc))<2.0)
     ?
     min( min(
     dot2(ba*clamp(dot(ba,pa)/dot2(ba),0.0,1.0)-pa),
     dot2(cb*clamp(dot(cb,pb)/dot2(cb),0.0,1.0)-pb) ),
     dot2(ac*clamp(dot(ac,pc)/dot2(ac),0.0,1.0)-pc) )-R
     :
     dot(nor,pa)*dot(nor,pa)/dot2(nor) )-R;
    }

struct RTI rayTriangleIntersect(
    struct Camera cam,float3 v0, float3 v1, float3 v2
    ){
    float3 B;
    #ifdef MOLLER_TRUMBORE
    float3 v0v1 = v1 - v0;
    float3 v0v2 = v2 - v0;
    float3 pvec = cross( cam.V ,v0v2);
    float det = dot(v0v1,pvec);
    #ifdef CULLING
    // if the determinant is negative the triangle is backfacing
    // if the determinant is close to 0, the ray misses the triangle
    if (det < ERR) return intersectF();
    #else
    // ray and triangle are parallel if det is close to 0
    if (fabs(det) < ERR) return intersectF();
    #endif
    float invDet = 1 / det;

    float3 tvec =  cam.P  - v0;
    B.y = dot(tvec,pvec) * invDet;
    if (B.y < 0 || B.y > 1) return intersectF();

    float3 qvec = cross(tvec,v0v1);
    B.z = dot( cam.V ,qvec) * invDet;
    if (B.z < 0 || B.y + B.z > 1) return intersectF();
    
    B.x = dot(v0v2,qvec) * invDet;
    
    return intersectT((1-B.y-B.z)*v0+B.y*v1+B.z*v2);
    #else
    // compute plane's normal
    float3 v0v1 = v1 - v0;
    float3 v0v2 = v2 - v0;
    // no need to normalize
    float3 N = cross(v0v1,v0v2); // N 
    float denom = dot(N,N);
    
    // Step 1: finding P
    
    // check if ray and plane are parallel ?
    float NdotRayDirection = dot(N, cam.V );

    if (fabs(NdotRayDirection) < ERR) // almost 0
        return intersectF(); // they are parallel so they don't intersect ! 

    // compute d parameter using equation 2
    float d = dot(-N,v0);
    
    // compute t (equation 3)
    B.x = -(dot(N, cam.P ) + d) / NdotRayDirection;
    
    // check if the triangle is in behind the ray
    if (B.x < 0) return intersectF(); // the triangle is behind
 
    // compute the intersection point using equation 1
    float3 P =  cam.P  + B.x *  cam.V ;
 
    // Step 2: inside-outside test
    float3 C; // vector perpendicular to triangle's plane
 
    // edge 0
    float3 edge0 = v1 - v0; 
    float3 vp0 = P - v0;
    C = cross(edge0,vp0);//TODO! possably bugged
    if (dot(N,C) < 0) return intersectF(); // P is on the right side//TODO! possably bugged
 
    // edge 1
    float3 edge1 = v2 - v1; 
    float3 vp1 = P - v1;
    C = cross(edge1,vp1);//TODO! possably bugged
    if ((B.y = dot(N,C)) < 0)  return intersectF(); // P is on the right side//TODO! possably bugged
 
    // edge 2
    float3 edge2 = v0 - v2; 
    float3 vp2 = P - v2;
    C = cross(edge2,vp2);//TODO! possably bugged
    if ((B.z = dot(N,C)) < 0) return intersectF(); // P is on the right side;//TODO! possably bugged

    B.y /= denom;
    B.z /= denom;

    return intersectT(P); // this ray hits the triangle
    #endif
    }
struct Data GlobalIntersect(sampler_t sampler_host, struct Camera cam, read_only image2d_t triangles){
    struct Data D = init();
    for(int i = 1;i<=get_image_height(triangles)+1;i++){
        struct RTI intersect = rayTriangleIntersect(cam,
        read_imagef(triangles,sampler_host,(float2)(0.5/(float)get_image_width(triangles),((float)i-.999)/(float)get_image_height(triangles))).xyz,
        read_imagef(triangles,sampler_host,(float2)(1.5/(float)get_image_width(triangles),((float)i-.999)/(float)get_image_height(triangles))).xyz,
        read_imagef(triangles,sampler_host,(float2)(2.5/(float)get_image_width(triangles),((float)i-.999)/(float)get_image_height(triangles))).xyz
        );
        if(intersect.isIntersect){
            if(D.isIntersect){
                if(fabs(distance(cam.P,intersect.P))<fabs(distance(cam.P,D.intersectPoint))){
                    D.isIntersect = true;
                    D.index = i;
                    D.intersectPoint = intersect.P;                
                }          
            }else {
                D.isIntersect = true;
                D.index = i;
                D.intersectPoint = intersect.P;

            }
        }
        // D.isIntersect = true;
    }
    // D.isIntersect = true;
    return D;
    }

float3 genNormal(sampler_t sampler_host, struct Data D,struct Camera C, read_only image2d_t triangles){
    float3 N = cross(
        read_imagef(triangles,sampler_host,(float2)(0.5/get_image_width(triangles),((float)D.index-.5)/get_image_height(triangles))).xyz-
        read_imagef(triangles,sampler_host,(float2)(1.5/get_image_width(triangles),((float)D.index-.5)/get_image_height(triangles))).xyz,
        read_imagef(triangles,sampler_host,(float2)(2.5/get_image_width(triangles),((float)D.index-.5)/get_image_height(triangles))).xyz-
        read_imagef(triangles,sampler_host,(float2)(0.5/get_image_width(triangles),((float)D.index-.5)/get_image_height(triangles))).xyz
        );
    return fabs(dot(N,C.V))==dot(N,C.V)?-N:N;
    }
float3 reflect(float3 N, float3 R){
    return R-2.*dot(N,R)*N;
    }
float3 camoffset (float3 v,float2 o){
    return normalize(
        (float3)(v.x,v.y,v.z))+
        normalize((float3)(-(v.y),(v.x),0.))*
        o.x+normalize((float3)(-v.z*v.x,-v.z*v.y,v.x*v.x+v.y*v.y))*o.y;
    }

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
    //h(6)=color
    read_only image2d_t src_image1,
    read_only image2d_t src_image2,
    write_only image2d_t dst_image1,
    write_only image2d_t dst_image2,
    int frameintg,
    float time
){
    int2 coord = (int2)(get_global_id(0),get_global_id(1));
    float2 uvi = (float2)(((float)get_global_id(0)+.001)/(float)(get_global_size(0)),((float)get_global_id(1)+.001)/(float)get_global_size(0));
    float2 uv = 2*uvi-1.;
    float2 i = (float2)(1.00/get_global_size(0),0/get_global_size(1));
    float2 j = (float2)(0/get_global_size(0),1.00/get_global_size(1));
    float b = .25;///increse for stronger gpu
    float p = 1.;
    float4 pixel;// = read_imagef(src_image2, sampler_host,uv);//lastframe
    // float noise = clamp(round((.5+half_exp(3-b*time))*hash11(perlin2d(time+get_group_id(0),time+get_group_id(1),.01,2))),0.,1.);
        // if(noise<0.){return;}
            // pixel *= frameintg/(frameintg+p);   
        // float4 noisyimage = read_imagef(src_image1, sampler_host,uv)
        // +noisefactor*(float4)(
        //     (hash11(perlin2d(500.+time+get_global_id(0),100.+time+get_global_id(1),.01,20))-.5),
        //     (hash11(perlin2d(2.00+time+get_global_id(0),2.00+time+get_global_id(1),.01,20))-.5),
        //     (hash11(perlin2d(2.00+time+get_global_id(1),2.00+time+get_global_id(0),.01,20))-.5),1.
        // );
    // pixel += noisyimage*p/(frameintg+p);
    struct Camera cam;
    cam.P = (float3)(sin(.5*time),cos(.5*time),-1)*15.;
    cam.V = (float3)(-sin(.5*time),-cos(.5*time),2);
    cam.C = (float3)(0.,0.,0.);
    cam.V = normalize(camoffset(normalize(cam.V),uv));
    struct Data intersect;
    for(int step = 0;step<bouncecount;step++){
    intersect = GlobalIntersect(sampler_host,cam,triangles);
    if(intersect.isIntersect){
    cam.P = intersect.intersectPoint;
    cam.P += .0000001*genNormal(sampler_host,intersect,cam,triangles);
    cam.V = reflect(normalize(genNormal(sampler_host,intersect,cam,triangles)),normalize(cam.V));
    pixel = (float4)((cam.V.xyz+1.)*.5,1.);
    // pixel = (float4)(distance(cam.P.xyz,intersect.intersectPoint)/100.);
    }else{
    pixel = (float4)((cam.V.xyz+1.)*.5,1.);
    break;
    }
    }

//

    // int inde = (int)((float)(time)/3.);
        // struct RTI test = rayTriangleIntersect(
        // cam,
        // read_imagef(triangles,sampler_host,(float2)(0.5/get_image_width(triangles),((float)inde-.5)/get_image_height(triangles))).xyz,
        // read_imagef(triangles,sampler_host,(float2)(1.5/get_image_width(triangles),((float)inde-.5)/get_image_height(triangles))).xyz,
        // read_imagef(triangles,sampler_host,(float2)(2.5/get_image_width(triangles),((float)inde-.5)/get_image_height(triangles))).xyz
        // );
        // if(test.isIntersect){
        // pixel = read_imagef(triangles,sampler_host,(float2)(5.5/get_image_width(triangles),((float)inde-.5)/get_image_height(triangles)));
        // }else{
        // pixel = (float4)((cam.V.xyz),1.);
        // // pixel = (float4)((cam.V.xyz+1)*.5,1.);
        // }
    // pixel = noise;
    // pixel = read_imagef(triangles,sampler_host,uvi.xy);
    pixel = (float4)(pixel.xyz,1.);
    write_imagef(dst_image1, coord,pixel);
    }////    