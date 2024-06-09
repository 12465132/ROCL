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
	float3  color;	        // diffuse color
	bool    isLight,        //is light object
            isRefractive,   //is the object refractive
            isThin,         //is a thin film object like paper
            b3,     
            b4,     
            b5,     
            b6,     
            b7;     
	float n;		        // refraction index
	float roughness;        // difuse to speecular
	float oid;		        // object id
	float density;          // fraction of reflectance to transmitince
    };
struct triangle{
    float3 p1;    
    float3 p2;
    float3 p3;
    struct L L;    
    };
    