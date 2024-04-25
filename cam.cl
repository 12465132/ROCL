struct RTI rayTriangleIntersect(struct Camera cam,float3 v0, float3 v1, float3 v2){
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
    
    return intersectT(B.z*v0+B.y*v1+(1-B.z-B.y)*v2);
    #else
    // compute plane's normal
    float3 v0v1 = v1 - v0;
    float3 v0v2 = v2 - v0;
    // no need to normalize
    float3 N = cross(v0v1,v0v2); // N //TODO! possably bugged
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

    return intersectT(B.z*v0+B.y*v1+(1-B.z-B.y)*v2); // this ray hits the triangle
    #endif
    }