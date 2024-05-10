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