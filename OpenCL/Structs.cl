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
	uint oid;		        // object id
	float density;          // fraction of reflectance to transmitince
    };
    struct SMaterialInfo
{
    // Note: diffuse chance is 1.0f - (specularChance+refractionChance)
    vec3  albedo;              // the color used for diffuse lighting
    vec3  emissive;            // how much the surface glows
    float specularChance;      // percentage chance of doing a specular reflection
    float specularRoughness;   // how rough the specular reflections are
    vec3  specularColor;       // the color tint of specular reflections
    float IOR;                 // index of refraction. used by fresnel and refraction.
    float refractionChance;    // percent chance of doing a refractive transmission
    float refractionRoughness; // how rough the refractive transmissions are
    vec3  refractionColor;     // absorption for beer's law    
};
struct triangle{
    float3 p1;    
    float3 p2;
    float3 p3;
    struct L L;    
    };
    