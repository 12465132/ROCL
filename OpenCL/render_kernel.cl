
// #define MOLLER_TRUMBORE
// #define CULLING
#pragma OPENCL EXTENSION cl_khr_3d_image_writes : enable
#pragma OPENCL 
__constant int //performace <-> precision
    RenderDistance 		= 100,
    Montycarlo 			= 1,
    bouncecount 		= 20,
    randomattempts 		= 5,
    extrapaths          = 5;

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
    float time,
    float Pos_x,
    float Pos_y,
    float Pos_z,
    float Vec_x,
    float Vec_y,
    float Vec_z
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
if(frameintg<2){
    pixel0 = 0;
    pixel1 = 0;
}

    // float4 pixel2 = read_imagef(dst_image,(int4)(coord,2.,1.));
    float4 pixelM2 = 0;
    float4 pixelSD = 0;
    float4 pixelMC = 0,RandomV1 = 0;
    float3 N = 0,lastN = 0,RandomV2 = 0,color = 0;
    float Fr = 0;
    float Fd = 1;    

    float n_new = 1;
    float n_old = 1;
    struct Camera cam;
    struct Data intersect;
    bool hasHitLight = false;
    bool hasHitObject = false;
    // bool hasHitObject = false;
    int numMiss =1;
    int badPath = 0;
    int randomn = 0;
    RandomV1 = ((float4)(   ((float)xorshift32(234422.+(14534122.+(2534422.*(time+1)))*(xorshift32(26345*get_global_id(1)*get_global_size(0)+23452*get_global_id(0))/4294967295.))/4294967295.),
                            ((float)xorshift32(654225.+(24534122.+(6554225.*(time+2)))*(xorshift32(92924*get_global_id(1)*get_global_size(0)+13452*get_global_id(0))/4294967295.))/4294967295.),
                            ((float)xorshift32(897643.+(34534122.+(8597643.*(time+3)))*(xorshift32(85345*get_global_id(1)*get_global_size(0)+12425*get_global_id(0))/4294967295.))/4294967295.),
                            ((float)xorshift32(234553.+(53234522.+(5523643.*(time+4)))*(xorshift32(34363*get_global_id(1)*get_global_size(0)+23457*get_global_id(0))/4294967295.))/4294967295.)));
    for(int montyC = 0;montyC < Montycarlo+badPath;montyC++){
    float roughness_new = 1;
    float roughness_old = 1;
    float fresnel_new = 1;
    float fresnel_old = 1;
    float density_new = 1;
    float density_old = 1;

    bool isSpecularRefracted = false;
    bool isSpecularReflected = false;
    bool isDiffuseRefracted  = false;
    bool isDiffuseReflected  = false;

    hasHitLight = false;
    intersect.isIntersect =false;

    // cam.P = (float3)(  3*sin(frameintg*.5+M_PI)+2.78,3*cos(frameintg*.5+M_PI)-8.00,2.73);
    // cam.V = -(cam.P-(float3)(2.75));
    // cam.V = normalize(camoffset(2.25*normalize(cam.V),-uv));
    // cam.P = (float3)(2.78,-8,2.78);
    // cam.V = (float3)(00,01,00);
    cam.P = (float3)(Pos_x,Pos_y,Pos_z);
    cam.V = (float3)(Vec_x,Vec_y,Vec_x);
    float3 temp1 = (camoffset(
        normalize(cam.V),
        (float2)(
            2.*hash21(RandomV1.x*10000.,RandomV1.y*10000.)-1.,
            2.*hash21(RandomV1.y*10000.,RandomV1.z*10000.)-1.
        )*(i+j)*1000.))-cam.V;;
    cam.V = (camoffset(
        2.8*normalize(cam.V),
        -uv+(float2)(
            2.*hash21(RandomV1.x*10000.,RandomV1.y*10000.)-1.,
            2.*hash21(RandomV1.y*10000.,RandomV1.z*10000.)-1.
        )*(i+j))/2.8);
    // float3 temp = cam.P+11.*cam.V;
    // cam.P += temp1;
    // cam.V = normalize(temp-cam.P);
    cam.C = (float3)(1.);
    lastN = cam.V;
    int stepn = 0;
    for(stepn = 0;stepn<bouncecount+badPath;stepn++){
    color = 0;
    intersect = GlobalIntersect(sampler_host,cam,triangles);
    if(!intersect.isIntersect){break;}
    N = genNormal(sampler_host,intersect,cam,triangles);
    N = (0.>dot(cam.V,N)?N:-N);
    color = read_imagef(triangles,sampler_host,(float2)(5.5/get_image_width(triangles),((float)intersect.index-.5)/get_image_height(triangles))).xyz;
    if(sqrt(3.)<fast_length(color))
    {hasHitLight = true;}
    if(hasHitLight&&stepn==0)
    {cam.C = read_imagef(triangles,sampler_host,(float2)(5.5/get_image_width(triangles),((float)intersect.index-.5)/get_image_height(triangles))).xyz;break;}

    // for(randomn = 0;randomn<randomattempts;randomn++){
    RandomV1 = (float4)(
    (float)(xorshift32(RandomV1.w*4294967295.)/4294967295.),
    (float)(xorshift32(RandomV1.x*4294967295.)/4294967295.),
    (float)(xorshift32(RandomV1.y*4294967295.)/4294967295.),
    (float)(xorshift32(RandomV1.z*4294967295.)/4294967295.));

    float booleanfloat = read_imagef(triangles,sampler_host,(float2)(3.5/get_image_width(triangles),((float)intersect.index-.5)/get_image_height(triangles))).z;
    bool b0 = (bool)((int)((booleanfloat)/  1)%2);
    bool b1 = (bool)((int)((booleanfloat)/  2)%2);
    bool b2 = (bool)((int)((booleanfloat)/  4)%2);
    bool b3 = (bool)((int)((booleanfloat)/  8)%2);
    bool b4 = (bool)((int)((booleanfloat)/ 16)%2);
    bool b5 = (bool)((int)((booleanfloat)/ 32)%2);
    bool b6 = (bool)((int)((booleanfloat)/ 64)%2);
    bool b7 = (bool)((int)((booleanfloat)/128)%2);

    roughness_old = roughness_new;
    fresnel_old = fresnel_new;
    density_old = density_new;
    n_old = n_new;

    roughness_new = clamp(read_imagef(triangles,sampler_host,(float2)(4.5/get_image_width(triangles),((float)intersect.index-.5)/get_image_height(triangles))).x,0.,1.);
    fresnel_new = clamp(read_imagef(triangles,sampler_host,(float2)(4.5/get_image_width(triangles),((float)intersect.index-.5)/get_image_height(triangles))).y,0.,1.);
    density_new = clamp(read_imagef(triangles,sampler_host,(float2)(4.5/get_image_width(triangles),((float)intersect.index-.5)/get_image_height(triangles))).z,0.,1.);
    n_new = clamp(read_imagef(triangles,sampler_host,(float2)(3.5/get_image_width(triangles),((float)intersect.index-.5)/get_image_height(triangles))).y,0.,1.);
    // ^ wrong need conditional fliping 
    if(n_old == n_new){
        n_new = 1.;
    }
    RandomV2 = ((float3)(
    2.*hash21(RandomV1.x*10000.,RandomV1.y*10000.)-1.,
    2.*hash21(RandomV1.y*10000.,RandomV1.z*10000.)-1.,
    2.*hash21(RandomV1.z*10000.,RandomV1.w*10000.)-1.));
    
    cam.C *= 
    // (rootn(fabs(dot((cam.V),(lastN))),5))* //effectivly a BRDF
    fabs(dot((normalize(cam.V)),normalize(lastN)))* //cos Contribution
    (Fr+color/M_PI) //Fr needs implementing
    /(1/(2.*M_PI)) //"correcting for effectively the BRDF"
    ;
    RandomV1 = (float4)(
    (float)(xorshift32(RandomV1.w*4294967295.)/4294967295.),
    (float)(xorshift32(RandomV1.x*4294967295.)/4294967295.),
    (float)(xorshift32(RandomV1.y*4294967295.)/4294967295.),
    (float)(xorshift32(RandomV1.z*4294967295.)/4294967295.));
    
    if(
        ((fast_length(cam.C.xyz))<hash21(RandomV1.x*10000.,RandomV1.y*10000.))
    ){
        cam.C=0;break;
    }
    pixelMC.xyz /= (fast_length(cam.C.xyz));
    if(hasHitLight){break;}
    RandomV1 = (float4)(
    (float)(xorshift32(RandomV1.w*4294967295.)/4294967295.),
    (float)(xorshift32(RandomV1.x*4294967295.)/4294967295.),
    (float)(xorshift32(RandomV1.y*4294967295.)/4294967295.),
    (float)(xorshift32(RandomV1.z*4294967295.)/4294967295.));
        if(n_old>n_new){//check if inside object thus total internal reflection possable
        //
        if(n_old*n_old*(1-dot(cam.V,N)*dot(cam.V,N))>1.){//total internal reflection n_old*n_old*(1-dot()*dot())>1.
            //    
            cam.V = (reflect(N,normalize(cam.V)));
            cam.P = intersect.intersectPoint-.00001*(N);
            cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V);
            //
        }else{//must be refraction if not internal reflection and inside object 
        //
        if(roughness_new<hash21(RandomV1.y*10000.,RandomV1.z*10000.)){
            //  
            cam.V =  (n_old/n_new)*cam.V + ((n_old/n_new)*dot(N,normalize(cam.V)) - sqrt(1.0 - (n_old/n_new)*(n_old/n_new)*(1.0 - dot(N,normalize(cam.V))*dot(N,normalize(cam.V)))))*N;
            // cam.V = (reflect(N,normalize(cam.V)));//refraction out of object specular
            cam.P = intersect.intersectPoint-.00001*(N);
            cam.V = (0.>dot(cam.V,N)?cam.V:-cam.V);
            //
        }else{
            //  
            cam.V = RandomV2;                       //refraction out of object diffuse           
            cam.P = intersect.intersectPoint-.00001*(N);
            cam.V = (0.>dot(cam.V,N)?cam.V:-cam.V);
            //
        }
        //
        }
        //
        }else{ //outside object 
        //
        // float dotRN = dot(N,normalize(cam.V));
        // float n_ratio = (n_old/n_new);
        // float sinT2 = n*n * (1.0 - dotRN * dotRN);
        // float cosT = sqrt(1.0 - (n_old/n_new)*(n_old/n_new)*(1.0 - dot(N,normalize(cam.V))*dot(N,normalize(cam.V))));
        //fresnel equations
        float r0 = (n_old-n_new)/(n_old+n_new);

        float frensel = r0*r0 +(1.-r0*r0)*pown(1.-dot(N,normalize(cam.V)),5);
        //
        // if(frensel<hash21(RandomV1.y*10000.,RandomV1.z*10000.)){//frensel effect dident happen
        if(0<hash21(RandomV1.y*10000.,RandomV1.z*10000.)){//frensel effect dident happen
        //
        if(density_new<hash21(RandomV1.x*10000.,RandomV1.y*10000.)){//refract into object
        //   
        if(roughness_new<hash21(RandomV1.y*10000.,RandomV1.z*10000.)){
            //
            cam.V =  (n_old/n_new)*cam.V + ((n_old/n_new)*dot(N,normalize(cam.V)) - sqrt(1.0 - (n_old/n_new)*(n_old/n_new)*(1.0 - dot(N,normalize(cam.V))*dot(N,normalize(cam.V)))))*N;
            // cam.V = (reflect(N,normalize(cam.V)));//refraction into object specular
            cam.P = intersect.intersectPoint-.00001*(N);
            cam.V = (0.>dot(cam.V,N)?cam.V:-cam.V);
            //
        }else{
            //
            cam.V = RandomV2;                     //refraction into object diffuse
            cam.P = intersect.intersectPoint-.00001*(N);
            cam.V = (0.>dot(cam.V,N)?cam.V:-cam.V);
            //
        }
        //
        }else{//refraction dident happen into object
        //
        if(roughness_new<hash21(RandomV1.y*10000.,RandomV1.z*10000.)){
            //
            cam.V = (reflect(N,normalize(cam.V)));//reflected specular of object
            cam.P = intersect.intersectPoint+.00001*(N);
            cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V);
            //
        }else{
            //
            cam.V = RandomV2;                     //reflected diffuse of object
            cam.P = intersect.intersectPoint+.00001*(N);
            cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V);
            //
        }
        }
        //
        }else{//frensel effect did happen thus must be specular
            //
            cam.V = (reflect(N,normalize(cam.V)));//reflected specular of object
            cam.P = intersect.intersectPoint+.00001*(N);
            cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V);
            //
        }
        }
    // cam.V = roughness_new*RandomV2+(1-roughness_new)*(reflect(N,normalize(cam.V)));
    // cam.P = intersect.intersectPoint+.00001*(N);
    // cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V);
    cam.V = normalize(cam.V);
    lastN = N;
    }
    
    if(!hasHitLight&&stepn!=bouncecount) {
        numMiss++;
        cam.C = 0;
        pixelMC += (float4)(0.,0.,0.,1.);
        pixelM2 += (float4)(0.,0.,0.,1.);
    }else if(!hasHitLight&&stepn==bouncecount){
    }else{
    pixelMC += (float4)(cam.C.xyz,1.);
    pixelM2 += (float4)(cam.C*cam.C,1.);
    }


    }
    pixel0 += pixelMC;
    pixel1 += pixelM2;

    write_imagef(dst_image, (int4)(coord,0,0),pixel0);
    write_imagef(dst_image, (int4)(coord,1,0),pixel1);
    
    // pixel0 = pixelMC/(pixelMC.a);
    pixel0 = pixel0/pixel0.a;
    // pixel0 = (float4)(numMiss/(Montycarlo*bouncecount),numMiss/(Montycarlo*bouncecount),numMiss/(Montycarlo*bouncecount),1);
    //post-processing
        // pixel0 = pow( pixel0, 0.40 );
    pixel0 = (pixel0)/(pixel0+1.);pixel0 = pow( pixel0, 0.45 );//IQ
    // pixel0 = (pixel0)/(luminance(pixel0.xyz)+1.);pixel0 = pow( pixel0, 0.45 );//IQ
        // RandomV2 = ((float3)(   ((float)xorshift32(234422.+(145341225.+(234422.*time))*(xorshift32(get_global_id(1)*get_global_size(0)+get_global_id(0))/4294967295.))/4294967295.),
        //                         ((float)xorshift32(654225.+(245341225.+(654225.*time))*(xorshift32(get_global_id(1)*get_global_size(0)+get_global_id(0))/4294967295.))/4294967295.),
        //                         ((float)xorshift32(897643.+(345341225.+(897643.*time))*(xorshift32(get_global_id(1)*get_global_size(0)+get_global_id(0))/4294967295.))/4294967295.)));
        // RandomV2 = (float3)((float)(xorshift32(RandomV2.z*4294967295.)/4294967295.),(float)(xorshift32(RandomV2.x*4294967295.)/4294967295.),(float)(xorshift32(RandomV2.y*4294967295.)/4294967295.));
    // pixel0 =(float4)(RandomV2,1.);
    write_imagef(framebuffer, coord,(float4)(pixel0.xyz,1.));
    }////    


