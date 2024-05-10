inline float dot2( float3 v ) { return dot(v,v); }
inline int noise2(int x, int y)
    {
    int tmp = hash[(y + SEED) % 256];
    return hash[(tmp + x) % 256];
    }
inline int noise1(int x)
    {
    return hash[(SEED + x) % 256];
    }
inline float lin_inter(float x, float y, float s)
    {
    return x + s * (y-x);
    }

inline float smooth_inter(float x, float y, float s)
    {
    return lin_inter(x, y, s * s * (3-2*s));
    }

inline float noise2d(float x, float y)
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
inline float noise1d(float x)
    {
    int x_int = x;
    float x_frac = x - x_int;
    int s = noise1(x_int);
    int t = noise1(x_int+1);
    return smooth_inter(s, t, x_frac);
    }
inline float perlin2d(float x, float y, float freq, int depth)
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
inline float perlin1d(float x, float freq, int depth)
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
inline float hash21(float x,float y)
    {
	return perlin2d((x),(y),.1,6);;
    }
inline float frand( int seed )
    {
    int seed2 = 0x00269ec3 + (seed)*0x000343fd;
    int a = ((seed2)>>16) & 32767;
    return -1.0f + (2.0f/32767.0f)*(float)a;
    }
inline float3 spherical_to_cartesian(float3 v){
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
inline struct Data init(){
    struct Data OD;
    OD.intersectPoint = (float3)(100000000.);
    OD.index=-1;
    OD.isIntersect=false;
    return OD;}
inline struct RTI intersectF(){
    struct RTI T;
    T.isIntersect = false;
    T.P = (float3)(0.);
    return T;
    }
inline struct RTI intersectT(float3 B){
    struct RTI T;
    T.isIntersect = true;
    T.P = B;
    return T;
    }
inline float udTriangle( float3 p, float3 p1, float3 p2, float3 p3, float R){
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

inline struct RTI rayTriangleIntersect(
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
inline struct Data GlobalIntersect(sampler_t sampler_host, struct Camera cam, read_only image2d_t triangles){
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

inline float3 genNormal(sampler_t sampler_host, struct Data D,struct Camera C, read_only image2d_t triangles){
    float3 N = cross(
        read_imagef(triangles,sampler_host,(float2)(0.5/get_image_width(triangles),((float)D.index-.5)/get_image_height(triangles))).xyz-
        read_imagef(triangles,sampler_host,(float2)(1.5/get_image_width(triangles),((float)D.index-.5)/get_image_height(triangles))).xyz,
        read_imagef(triangles,sampler_host,(float2)(2.5/get_image_width(triangles),((float)D.index-.5)/get_image_height(triangles))).xyz-
        read_imagef(triangles,sampler_host,(float2)(0.5/get_image_width(triangles),((float)D.index-.5)/get_image_height(triangles))).xyz
        );
    return normalize(fabs(dot(N,C.V))==dot(N,C.V)?-N:N);
    }
inline float3 reflect(float3 N, float3 R){
    return R-2.*dot(N,R)*N;
    }
inline float3 camoffset (float3 v,float2 o){
    return 
        (v)+
        normalize((float3)(-(v.y),(v.x),0.))*o.x+
        normalize((float3)(-v.z*v.x,-v.z*v.y,v.x*v.x+v.y*v.y))*o.y;
    }
/* The state must be initialized to non-zero */
inline uint xorshift32(uint state)
{
	/* Algorithm "xor" from p. 4 of Marsaglia, "Xorshift RNGs" */
	uint x = state;
	x ^= x << 13;
	x ^= x >> 17;
	x ^= x << 5;
    return x;
}
inline float BSDF(float t,float A,float B){
    if(B == 0){return 1;}
    return powr((t-t*t)/(A*A*A*(1-t)*(1-t)+(1-A)*(1-A)*(1-A)*t*t),B);
}// 0<t<1 0<a<1 0<=range<=1  A is be dot(R,N)
inline float3 polar_along_reflect(float3 R, float3 N,float u,float v){
float3 Pt = R-dot(R,N)*N;
float3 Pl = dot(R,N)*N;
float3 Px = cross(R,N); 
return 
     Pt*(cos(u))/(sqrt(1-dot(R,N)*dot(R,N)))
    +Pl*(sin(u)*cos(v))/(dot(R,N))
    +Px*(sin(u)*sin(v))/(sqrt(1-dot(R,N)*dot(R,N)));
}//||R||==1 ||N||==1
float luminance(float3 v)
{
    return dot(v, (float3)(0.2126, 0.7152, 0.0722));
}

float3 change_luminance(float3 c_in, float l_out)
{
    float l_in = luminance(c_in);
    return c_in * (l_out / l_in);
}