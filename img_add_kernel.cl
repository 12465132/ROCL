
// #define MOLLER_TRUMBORE
// #define CULLING
#pragma OPENCL EXTENSION cl_khr_3d_image_writes : enable
#pragma OPENCL 
__constant int SEED = 0;
__constant float ERR =.000001;
__constant int //performace <-> precision
    RenderDistance 		= 100,
    Montycarlo 			= 2,
    bouncecount 		= 5,
    randomattempts 		= 5,
    extrapaths          = 5;
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
int noise1(int x)
    {
    return hash[(SEED + x) % 256];
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
float noise1d(float x)
    {
    int x_int = x;
    float x_frac = x - x_int;
    int s = noise1(x_int);
    int t = noise1(x_int+1);
    return smooth_inter(s, t, x_frac);
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
float perlin1d(float x, float freq, int depth)
    {
    float xa = x*freq;
    float amp = 1.0;
    float fin = 0;
    float div = 0.0;

    int i;
    for(i=0; i<depth; i++)
    {
        div += 256 * amp;
        fin += noise1d(xa) * amp;
        amp /= 2;
        xa *= 2;
    }

    return fin/div;
    }
// float3 hash33( float3 p )      // this hash is not production ready, please
    //     {                        // replace this by something better
float hash21(float x,float y)
    {
	return perlin2d((x),(y),.1,6);;
    }
float frand( int seed )
    {
    int seed2 = 0x00269ec3 + (seed)*0x000343fd;
    int a = ((seed2)>>16) & 32767;
    return -1.0f + (2.0f/32767.0f)*(float)a;
    }
float3 spherical_to_cartesian(float3 v){
    return (float3)(v.x*cos(v.y)*sin(v.z),v.x*sin(v.y)*sin(v.z),v.x*cos(v.z)) ;
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
    T.P = (float3)(0.);
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
    return normalize(fabs(dot(N,C.V))==dot(N,C.V)?-N:N);
    }
float3 reflect(float3 N, float3 R){
    return R-2.*dot(N,R)*N;
    }
float3 camoffset (float3 v,float2 o){
    return 
        (v)+
        normalize((float3)(-(v.y),(v.x),0.))*o.x+
        normalize((float3)(-v.z*v.x,-v.z*v.y,v.x*v.x+v.y*v.y))*o.y;
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
    read_write image3d_t dst_image,
    write_only image2d_t framebuffer,
    int frameintg,
    float time
){

    int2 coord =       (int2)(  get_global_id(0),  get_global_id(1));
    float2 fcoord =  (float2)(  get_global_id(0),  get_global_id(1));
    float2 fcoordT = (float2)(get_global_size(0),get_global_size(1));
    float2 uvinput = (float2)(((float)get_global_id(0)+.001)/(float)(get_global_size(0)),((float)get_global_id(1)+.001)/(float)get_global_size(1));
    float2 uvi = (float2)((fcoord.x)/fcoordT.x,(fcoord.y)/fcoordT.x);
    float2 uv = (float2)(2.*uvi.x-1,2.*uvi.y-fcoordT.y/fcoordT.x);
    // float2 uv = (2.*uvi-1);
    float2 i = (float2)(1.00/get_global_size(0),0/get_global_size(1));
    float2 j = (float2)(0/get_global_size(0),1.00/get_global_size(1));
    // float b = 50;///increse for stronger gpu
    float p = .5;
    float ps = .9;

    float4 pixel0 = read_imagef(dst_image,(int4)(coord,0.,0.));//raw image
    float4 pixel1 = read_imagef(dst_image,(int4)(coord,1.,1.));//SD  image
    // if(time<1){
    // write_imagef(dst_image, (int)(coord,0),(0,0,0,0));
    // write_imagef(dst_image, (int)(coord,1),(0,0,0,0));
    // write_imagef(framebuffer, coord,(0,0,0,0));  
    // return;
    // }
    // write_imagef(dst_image, (int)(coord,0),(0,0,0,0));
    // write_imagef(dst_image, (int)(coord,1),(0,0,0,0));  
    float4 pixelM2 = 0;
    float4 pixelSD = 0;
    float4 pixelMC = 0;
    float3 N = 0,lastN = 0,RandomV2 = 0;
    // float noise = 0;
    struct Camera cam;
    struct Data intersect;
    bool hasHitLight = false;
    bool hasHitObject = false;
    int badPath = 0;
    for(int montyC = 0;montyC < Montycarlo+badPath;montyC++){
    hasHitLight = false;
    intersect.isIntersect =false;
    // noise = (.5+half_exp(3-b*time))*frand((int)(1000*perlin2d(time+get_global_id(0)+montyC,time+get_global_id(1)-montyC,.01,2)));
    // noise = frand(noise);

    cam.P = (float3)(  3*sin(time+M_PI)+2.78,
                       3*cos(time+M_PI)-8.00,
                       2.73);
    cam.V = -(cam.P-(float3)(2.75));
    cam.V = normalize(camoffset(2.25*normalize(cam.V),-uv));
    // cam.P = (float3)(2.78,-8,2.78);
    // cam.V = (float3)(00,01,00);
    // cam.V = normalize(camoffset(2.8*normalize(cam.V),-uv));

    // cam.C = cam.V;
    cam.C = (float3)(1.);
    int stepn = 0;
    for(stepn = 0;stepn<bouncecount+badPath;stepn++){
    intersect = GlobalIntersect(sampler_host,cam,triangles);
    if(!intersect.isIntersect){break;}
    // intersect.isIntersect =false;
    for(int randomn = 0;randomn<randomattempts;randomn++){
    RandomV2 = ((float3)(
        2.*hash21( 100.*(100.*(cos(time+1+stepn+(bouncecount+extrapaths)*montyC+cbrt(time))+1+1)+get_global_id(1)),100.*(100.*(sin(time+1+stepn+(bouncecount+extrapaths)*montyC+cbrt(time))+1+2)+get_global_id(0)))-1.,
        2.*hash21( 100.*(100.*(cos(time+1+stepn+(bouncecount+extrapaths)*montyC+cbrt(time))+1+3)+get_global_id(1)),100.*(100.*(sin(time+1+stepn+(bouncecount+extrapaths)*montyC+cbrt(time))+1+4)+get_global_id(0)))-1.,
        2.*hash21( 100.*(100.*(cos(time+1+stepn+(bouncecount+extrapaths)*montyC+cbrt(time))+1+5)+get_global_id(1)),100.*(100.*(sin(time+1+stepn+(bouncecount+extrapaths)*montyC+cbrt(time))+1+6)+get_global_id(0)))-1.));
    if (length(RandomV2)<=1){break;}
    }
    // RandomV2 = ((float3)(
    // 2.*hash21( 100.*(100.*(cos(time+1+stepn+(bouncecount+extrapaths)*montyC+cbrt(time))+1+1)+get_global_id(1)),100.*(100.*(sin(time+1+stepn+(bouncecount+extrapaths)*montyC+cbrt(time))+1+2)+get_global_id(0)))-1.,
    // 2.*hash21( 100.*(100.*(cos(time+1+stepn+(bouncecount+extrapaths)*montyC+cbrt(time))+1+3)+get_global_id(1)),100.*(100.*(sin(time+1+stepn+(bouncecount+extrapaths)*montyC+cbrt(time))+1+4)+get_global_id(0)))-1.,
    // 2.*hash21( 100.*(100.*(cos(time+1+stepn+(bouncecount+extrapaths)*montyC+cbrt(time))+1+5)+get_global_id(1)),100.*(100.*(sin(time+1+stepn+(bouncecount+extrapaths)*montyC+cbrt(time))+1+6)+get_global_id(0)))-1.));
    
    // RandomV2 = fast_normalize(RandomV2);
        // spherical_to_cartesian((float3)(
        // 2.*M_1_PI*hash21( 1000.*(1000.*(cos(time*M_PI)+1+step+100)+get_global_id(1)),1000.*(1000.*(sin(time*M_PI)+1+step+200)+get_global_id(0)))-1.*M_1_PI,
        // 2.*M_1_PI*hash21( 1000.*(1000.*(cos(time*M_PI)+1+step+300)+get_global_id(1)),1000.*(1000.*(sin(time*M_PI)+1+step+400)+get_global_id(0)))-1.*M_1_PI,
        // 1.));;
    // RandomV2 = 0;
    lastN = N;
    N = genNormal(sampler_host,intersect,cam,triangles);
    // N = (0.<=dot(-N,cam.V))?N:-N;
    if(sqrt(3.)<fast_length(read_imagef(triangles,sampler_host,(float2)(5.5/get_image_width(triangles),((float)intersect.index-.5)/get_image_height(triangles))).xyz))
    {hasHitLight = true;}
    if(hasHitLight&&stepn==0){cam.C = read_imagef(triangles,sampler_host,(float2)(5.5/get_image_width(triangles),((float)intersect.index-.5)/get_image_height(triangles))).xyz;break;}
    cam.C *= 
    // (stepn+1)*
    // ((fast_length(lastN)<.5)?1:dot(normalize(intersect.intersectPoint-cam.P),normalize(lastN)))*
    // (!hasHitLight?1:dot((cam.V),(    N)))*
    // (!hasHitLight?1:dot((cam.V),(lastN)))*    
    // (stepn==0?1:dot((cam.V),(    N)))*
    // powr((stepn==0?1:dot((cam.V),(lastN))),2)*
    (hasHitLight?stepn==0?1:dot(cam.V,lastN):1)*
    // (hasHitLight?stepn==0?1:dot(cam.V,lastN) :1)*
    // ((1-dot((-cam.V),(stepn!=0?(N    ):cam.V))))*
    // ((1-dot((cam.V),(stepn!=0?(lastN):cam.V))))*
    // (hasHitLight*dot((cam.V),(stepn!=0?(N):cam.V))+(1-hasHitLight))*
    (read_imagef(triangles,sampler_host,(float2)(5.5/get_image_width(triangles),((float)intersect.index-.5)/get_image_height(triangles))).xyz)
    // *dot(-normalize(intersect.intersectPoint-cam.P),N)
    // *(stepn==0?1:(float)min(1.,native_recip(powr(.1*distance(cam.P,intersect.intersectPoint),2))))
    ;
    if(3.>read_imagef(triangles,sampler_host,(float2)(3.5/get_image_width(triangles),((float)intersect.index-.5)/get_image_height(triangles))).z){break;}
    // N = genNormal(sampler_host,intersect,cam,triangles);
    // N = (0.<=dot(-N,cam.V))?N:-N;
    float reflectance = clamp(read_imagef(triangles,sampler_host,(float2)(4.5/get_image_width(triangles),((float)intersect.index-.5)/get_image_height(triangles))).x,0.,1.);
    cam.V = (RandomV2);//+(1-reflectance)*(reflect(N,normalize(cam.V)));
    // cam.V = 0.
    // +(dot(RandomV2,N)>0?RandomV2:-RandomV2)
    // +.00001*(N)
    // +(1.-reflectance)
        // *(reflect(N,normalize(cam.V)));
        // cam.V = (cam.V);
    cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V);
    cam.V = normalize(cam.V);
    // cam.V = normalize(cam.V);
    cam.P = intersect.intersectPoint+.00001*(N);
    // cam.P += ;

    }
    // cam.C *= 2*M_PI;
    // if((!intersect.isIntersect)&&bouncecount>stepn) 
    // {cam.C=0;}else{cam.C=1;}
    // if((intersect.isIntersect)) 
    // {cam.C=0;}else{cam.C=1;}
    // if(bouncecount>stepn) 
    // {cam.C=0;}else{cam.C=1;}
    if(!hasHitLight) {cam.C=0;}
    // if(Montycarlo<(montyC+2)){
    // pixelSD = (float4)((fabs(pixelM2.xyz/pixelM2.a-(pixelMC.xyz/pixelMC.a)*(pixelMC.xyz/pixelMC.a))),1.);
    // }
    // if(
    //     // intersect.isIntersect&&
    //     Montycarlo<(montyC+2)&&
    //     badPath<extrapaths&&
    //     pixelSD.x<fabs(pixelMC.x/pixelMC.a-cam.C.x)&&
    //     pixelSD.y<fabs(pixelMC.y/pixelMC.a-cam.C.y)&&
    //     pixelSD.z<fabs(pixelMC.z/pixelMC.a-cam.C.z)&&
    //     1==1
    // ) 
    // {

    //     // pixel2 = 1;
    //     badPath++;
    //     continue;
    // }
    pixelMC += (float4)(cam.C.xyz,1.);
    pixelM2 += (float4)(cam.C*cam.C,1.);
    }
    // pixelMC /= pixelM2.a;
    // if(intersect.isIntersect==true) {pixel *= (float)frameintg/((float)frameintg+p);pixel += (float4)(pixelMC.xyz,1.)*p/((float)frameintg+p);}
    // {pixel *= (float)frameintg/((float)frameintg+p);pixel += (float4)(pixelMC.xyz,1.)*p/((float)frameintg+p);}
    // if(length(sqrt(pixelSD))<=50.00)
    // {pixel2 = (float4)(pow( pixelMC.xyz, 0.45 ),1.);;}
    // {}else
    // {pixel1 *= (float)frameintg/((float)frameintg+p);pixel1 += (float4)(pow( pixelMC.xyz, 0.45 ),1.)*p/((float)frameintg+p);}
    // {pixel2 *= (float)frameintg/((float)frameintg+p);pixel2 += (float4)(pow( pixelMC.xyz, 0.45 ),1.)*p/((float)frameintg+p);}

    // if(intersect.isIntersect==true){pixel *= (1-p);pixel += (float4)(pixelMC.xyz,1.)*p;}
    // {pixel2 = (float4)(pow( pixelMC.xyz, 0.45 ),1.);}
    // else{pixel2 = 0;}
    pixel0 += pixelMC/max(1.,pixelMC.a);
    pixel1 += pixelM2/max(1.,pixelM2.a);
    // pixel1 = (float4)(1.);
    // write_imagef(dst_image1, coord,pixel1);

    // read_imagef(dst_image,(int)(coord,0));
    write_imagef(dst_image, (int4)(coord,0,0),pixel0);
    write_imagef(dst_image, (int4)(coord,1,0),pixel1);
    pixel0 = pixelMC/max(1.,pixelMC.a);
    // pixel0 = pixel0/pixel0.a;
    //post-processing
    // pixel0 = pow( pixel0, 0.40 );
    pixel0 = (1.*pixel0)/(1.*pixel0+1.);
    // pixel0 = pow( pixel0, 0.45 );    
    // pixel0 = pow( pixel0, 2 );
    pixel0 = pow( pixel0, 0.45 );//IQ
    write_imagef(framebuffer, coord,(float4)(pixel0.xyz,1.));
    }////    