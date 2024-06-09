
// #define MOLLER_TRUMBORE
// #define CULLING
#pragma OPENCL EXTENSION cl_khr_3d_image_writes : enable
#pragma OPENCL 
__constant int //performace <-> precision
    RenderDistance 		= 100,
    Montycarlo 			= 1,
    bouncecount 		= 4,
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
if(frameintg<1){
    pixel0 = 0;
    pixel1 = 0;
}

    // float4 pixel2 = read_imagef(dst_image,(int4)(coord,2.,1.));
    float4 pixelM2 = 0;
    float4 pixelSD = 0;
    float4 pixelMC = 0,RandomV1 = 0;
    float3 N = 0,lastN = 0,RandomV2 = 0,
    color = 1,
    throughput = 1;
    float Fr = 0;
    float Fd = 1; 


    struct Camera cam;
    struct Data intersect;
    bool hasHitLight = false;
    bool hasHitObject = false;
    // bool hasHitObject = false;
    int numMiss = 1;
    int badPath = 0;
    int randomn = 0;
    RandomV1 = ((float4)(   ((float)xorshift32(234422.+(14534122.+(2534422.*(time+1)))*(xorshift32(26345*get_global_id(1)*get_global_size(0)+23452*get_global_id(0))/4294967295.))/4294967295.),
                            ((float)xorshift32(654225.+(24534122.+(6554225.*(time+2)))*(xorshift32(92924*get_global_id(1)*get_global_size(0)+13452*get_global_id(0))/4294967295.))/4294967295.),
                            ((float)xorshift32(897643.+(34534122.+(8597643.*(time+3)))*(xorshift32(85345*get_global_id(1)*get_global_size(0)+12425*get_global_id(0))/4294967295.))/4294967295.),
                            ((float)xorshift32(234553.+(53234522.+(5523643.*(time+4)))*(xorshift32(34363*get_global_id(1)*get_global_size(0)+23457*get_global_id(0))/4294967295.))/4294967295.)));
    for(int montyC = 0;montyC < Montycarlo+badPath;montyC++){
struct L L_old,L_new;
    L_old = air();
    L_new = air();
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
    color = (float3)(1.);
    throughput = (float3)(1.);
    lastN = cam.V;
    int stepn = 0;
    for(stepn = 0;stepn<bouncecount+badPath;stepn++){
    intersect = GlobalIntersect(sampler_host,cam,triangles);
    N = genNormal(sampler_host,intersect,cam,triangles);
    N = (0.>dot(cam.V,N)?N:-N);
    RandomV1 = (float4)(
    (float)(xorshift32(RandomV1.w*4294967295.)/4294967295.),
    (float)(xorshift32(RandomV1.x*4294967295.)/4294967295.),
    (float)(xorshift32(RandomV1.y*4294967295.)/4294967295.),
    (float)(xorshift32(RandomV1.z*4294967295.)/4294967295.));
    L_old=L_new;
    L_new = load(intersect.index,sampler_host,triangles);
    RandomV2 = ((float3)(
    2.*hash21(RandomV1.x*10000.,RandomV1.y*10000.)-1.,
    2.*hash21(RandomV1.y*10000.,RandomV1.z*10000.)-1.,
    2.*hash21(RandomV1.z*10000.,RandomV1.w*10000.)-1.));
    if(!intersect.isIntersect){break;}
    if(sqrt(3.)<fast_length(L_new.color))
    {hasHitLight = true;}
    if(hasHitLight&&stepn==0)
    {cam.C = L_new.color.xyz;break;}

    throughput *= 
    // (rootn(fabs(dot((cam.V),(lastN))),5))* //effectivly a BRDF
    fabs(dot((normalize(cam.V)),normalize(lastN)))* //cos Contribution
    // *4. //"correcting for effectively the BRDF"
    // (2)* //"correcting for effectively the BRDF"
    1.;
    color *= (L_new.color); //Fr needs implementing

    RandomV1 = (float4)(
    (float)(xorshift32(RandomV1.w*4294967295.)/4294967295.),
    (float)(xorshift32(RandomV1.x*4294967295.)/4294967295.),
    (float)(xorshift32(RandomV1.y*4294967295.)/4294967295.),
    (float)(xorshift32(RandomV1.z*4294967295.)/4294967295.));
    
    // if((frameintg>100)){
        // if(
        //     (((pixel1.z)/(pixel1.z+1))<hash21(RandomV1.x*10000.,RandomV1.y*10000.))
        // ){
        //     cam.C=0;break;
        // }
        // pixel0.xyz /= ((pixel1.z)/(pixel1.z+1));
    // }
    if(hasHitLight){break;}
    RandomV1 = (float4)(
    (float)(xorshift32(RandomV1.w*4294967295.)/4294967295.),
    (float)(xorshift32(RandomV1.x*4294967295.)/4294967295.),
    (float)(xorshift32(RandomV1.y*4294967295.)/4294967295.),
    (float)(xorshift32(RandomV1.z*4294967295.)/4294967295.));

        /////////////////////////////////////
    
        // if(L_new.n>L_new.n){//check if inside object thus total internal reflection possable
        // // if(n_old*n_old*sqrt(1-dot(cam.V,N)*dot(cam.V,N))>1.){//total internal reflection n_old*n_old*(1-dot()*dot())>1.
        // if(1==0){//total internal reflection n_old*n_old*(1-dot()*dot())>1.
        //     cam.V = (reflect(N,normalize(cam.V)));
        //     cam.P = intersect.intersectPoint+.00001*(N);
        //     cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V);
        // }else{//must be refraction if not internal reflection and inside object 
        // if(L_new.roughness<hash21(RandomV1.y*10000.,RandomV1.z*10000.)){
        //     // cam.V =  (n_old/n_new)*cam.V + ((n_old/n_new)*dot(N,normalize(cam.V)) - sqrt(1.0 - (n_old/n_new)*(n_old/n_new)*(1.0 - dot(N,normalize(cam.V))*dot(N,normalize(cam.V)))))*N;
        //     // N = (0.<dot(cam.V,N)?N:-N);
        //     cam.V =  refract(normalize(N),normalize(cam.V),L_new.n,L_old.n);
        //     // cam.V = (reflect(N,normalize(cam.V)));//refraction out of object specular
        //     cam.P = intersect.intersectPoint-.00001*(N);
        //     // cam.V = (0.>dot(cam.V,N)?cam.V:-cam.V);
        // }else{
        //     cam.V = RandomV2;                       //refraction out of object diffuse           
        //     cam.P = intersect.intersectPoint-.00001*(N);
        //     cam.V = (0.>dot(cam.V,N)?cam.V:-cam.V);
        // }
        // }
        // }else{ //outside object 
        // float r0 = (L_old.n-L_new.n)/(L_new.n+L_old.n);
        // float frensel = r0*r0 +(1.-r0*r0)*pown(1.+dot(N,normalize(cam.V)),5);
        // // if(frensel<hash21(RandomV1.y*10000.,RandomV1.z*10000.)){//frensel effect dident happen
        // if(frensel<hash21(RandomV1.y*10000.,RandomV1.z*10000.)){//frensel effect dident happen
        // if(L_new.density<hash21(RandomV1.x*10000.,RandomV1.y*10000.)){//refract into object
        // if(L_new.roughness<hash21(RandomV1.y*10000.,RandomV1.z*10000.)){
        //     // cam.V =  (n_old/n_new)*cam.V + ((n_old/n_new)*dot(N,normalize(cam.V)) - sqrt(1.0 - (n_old/n_new)*(n_old/n_new)*(1.0 - dot(N,normalize(cam.V))*dot(N,normalize(cam.V)))))*N;
        //     // N = (0.<dot(cam.V,N)?N:-N);
        //     cam.V =  refract(normalize(N),normalize(cam.V),L_new.n,L_old.n);
        //     cam.P = intersect.intersectPoint-.00001*(N);
        //     // cam.V = (0.>dot(cam.V,N)?cam.V:-cam.V);
        // }else{
        //     cam.V = RandomV2;                     //refraction into object diffuse
        //     cam.P = intersect.intersectPoint-.00001*(N);
        //     cam.V = (0.>dot(cam.V,N)?cam.V:-cam.V);
        // }
        // }else{//refraction dident happen into object
        // if(L_new.roughness<hash21(RandomV1.y*10000.,RandomV1.z*10000.)){
        //     cam.V = (reflect(N,normalize(cam.V)));//reflected specular of object
        //     cam.P = intersect.intersectPoint+.00001*(N);
        //     cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V);
        // }else{
        //     cam.V = RandomV2;                     //reflected diffuse of object
        //     cam.P = intersect.intersectPoint+.00001*(N);
        //     cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V);
        // }
        // }
        // }else{//frensel effect did happen thus must be specular
        //     cam.V = (reflect(N,normalize(cam.V)));//reflected specular of object
        //     cam.P = intersect.intersectPoint-.00001*(N);
        //     cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V);
        // }
        // }

        ///////////////////////////////

        // if(
        //    b2_new 
        // ){
        // if(b0_new){
        //     //reflected specular of object
        //     cam.V = (reflect(N,normalize(cam.V)));
        //     cam.P = intersect.intersectPoint+.00001*(N);
        //     cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V);  
        // }else{
        //     //reflected specular of object
        //     cam.V = (reflect(N,normalize(cam.V)));
        //     cam.P = intersect.intersectPoint+.00001*(N);
        //     cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V);        
        // }
        // }else if(
        //     oid_old == -1&&
        //     n_old == 1&&
        //     oid_new > -1&&
        //     b0_new
        // ){
        //     cam.V = (reflect(N,normalize(cam.V)));
        //     cam.P = intersect.intersectPoint+.00001*(N);
        //     cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V); 
        // }else if(
        //     oid_old > -1&&
        //     !b0_new&&
        //     b0_old&&
        //     oid_new != oid_old
        // ){
        //     cam.V = (reflect(N,normalize(cam.V)));
        //     cam.P = intersect.intersectPoint+.00001*(N);
        //     cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V); 
        // }else if(
        //     oid_old > -1&&
        //     oid_new > -1&&
        //     b0_new&&
        //     b0_old&&
        //     // oid_new == oid_old&&
        //     n_old*sqrt(1-dot(cam.V,N)*dot(cam.V,N))/(oid_new == oid_old?1:n_new) < 1
        // ){
        //     cam.V = (reflect(N,normalize(cam.V)));
        //     cam.P = intersect.intersectPoint+.00001*(N);
        //     cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V); 
        // }else if(
        //     oid_old > -1&&
        //     oid_new > -1&&
        //     b0_new&&
        //     b0_old&&
        //     // oid_new == oid_old&&
        //     n_old*sqrt(1-dot(cam.V,N)*dot(cam.V,N))/(oid_new == oid_old?1:n_new) >= 1
        // ){
        //     cam.V = (reflect(N,normalize(cam.V)));
        //     cam.P = intersect.intersectPoint+.00001*(N);
        //     cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V); 
        // }else if(
        //     oid_old == -1&&
        //     !b0_new
        // ){
        //     //Set Oid_new == oid_old (...)
        //     cam.V = (reflect(N,normalize(cam.V)));
        //     cam.P = intersect.intersectPoint+.00001*(N);
        //     cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V); 
        // }else if(
        //     1==1
        // ){
        //     //Set Oid_new == oid_old (...)
        //     cam.V = (reflect(N,normalize(cam.V)));
        //     cam.P = intersect.intersectPoint+.00001*(N);
        //     cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V); 
        // }else{
        //     //idk what to do if everything failed
        //     cam.V = (reflect(N,normalize(cam.V)));
        //     cam.P = intersect.intersectPoint+.00001*(N);
        //     cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V); 
        // }

    ///////////////////////////

        if(L_new.isThin){    
            if(L_new.isRefractive){
                //reflected specular of object
                cam.V = RandomV2;
                cam.P = intersect.intersectPoint+.00001*(N);
                cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V);  
            }else{
                //reflected specular of object
                cam.V = RandomV2;
                cam.P = intersect.intersectPoint+.00001*(N);
                cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V);        
            }
        }
        if(L_old.oid > -1&&L_new.oid > -1){
            if(L_new.oid != L_old.oid){
                cam.V = RandomV2;
                cam.P = intersect.intersectPoint+.00001*(N);
                cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V);   
            }else{
                cam.V = RandomV2;
                cam.P = intersect.intersectPoint+.00001*(N);
                cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V);   
            }
        }else if(L_new.oid > -1){
                cam.V = RandomV2;
                cam.P = intersect.intersectPoint+.00001*(N);
                cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V);   
        }else if(L_old.oid > -1){
                cam.V = RandomV2;
                cam.P = intersect.intersectPoint+.00001*(N);
                cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V);   
        }else{
                cam.V = RandomV2;
                cam.P = intersect.intersectPoint+.00001*(N);
                cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V);   
        }

    ////////////////////////////////

    // cam.V = roughness_new*RandomV2+(1-roughness_new)*(reflect(N,normalize(cam.V)));
    // cam.P = intersect.intersectPoint+.00001*(N);
    // cam.V = (0.>dot(cam.V,N)?-cam.V:cam.V);

    cam.V = normalize(cam.V);
    lastN = N;
    }
    cam.C = color;
    RandomV1 = (float4)(
    (float)(xorshift32(RandomV1.w*4294967295.)/4294967295.),
    (float)(xorshift32(RandomV1.x*4294967295.)/4294967295.),
    (float)(xorshift32(RandomV1.y*4294967295.)/4294967295.),
    (float)(xorshift32(RandomV1.z*4294967295.)/4294967295.));
    if(!hasHitLight&&stepn<bouncecount) {
        numMiss++;
        cam.C = 0;
        // pixel0.xyz /=  ((pixel0.a+Montycarlo)/pixel0.a);
        // pixel1.xyz /=  ((pixel1.a+Montycarlo)/pixel1.a);
        // pixel1.xyz /=  ((pixel1.a+Montycarlo)/pixel1.a);
        pixelMC += (float4)(0.,0.,0.,0.);
        pixelM2 += (float4)(0.,0.,0.,0.);
        // pixelMC += (float4)(.1*cam.C.xyz,1.);
        // pixelM2 += (float4)(.1*cam.C*cam.C,1.);
    }else if(!hasHitLight&&stepn>=bouncecount){
    //    pixel0.xyz *=  ((pixel0.a+Montycarlo)/pixel0.a);
    //    pixel1.xyz *=  ((pixel1.a+Montycarlo)/pixel1.a);
    //    pixel1.xyz /=  ((pixel1.a+Montycarlo)/pixel1.a);
        // pixel0.a = (pixel0.a+Montycarlo);
        // pixel1.a = (pixel1.a+Montycarlo);
        // pixel1.a = (pixel1.a+Montycarlo);       
        pixelMC += (float4)(0.0);
        pixelM2 += (float4)(0.0);
        // pixel0 = pixelMC;
        // pixel1 = pixelM2;
        // if((1-1/(pixel0.a+1))<hash21(RandomV1.x*10000.,RandomV1.y*10000.)){
        // pixel0 += pixelMC;
        // pixel1 += pixelM2;
        // }
    }else{
        pixelMC += (float4)(cam.C.xyz,1.);
        pixelM2 += (float4)(throughput,1.);
        // if(.5<hash21(RandomV1.x*10000.,RandomV1.y*10000.)){
            // pixel0 += pixelMC;
            // pixel1 += pixelM2;
        // }

    }

    }

    pixel0 += pixelMC;
    pixel1 += pixelM2;

    write_imagef(dst_image, (int4)(coord,0,0),pixel0);
    write_imagef(dst_image, (int4)(coord,1,0),pixel1);
    
    // pixel0 = pixelMC/(pixelMC.a);
    pixel0 = pixel0/pixel0.a;
    pixel1 = pixel1/pixel1.a;
    // pixel1 = (pixel1)/(pixel1+1.);
    pixel0 = (pixel0)/(pixel1+1.);
    // pixel0 = pixel0*pixel1;
    // pixel0 = (float4)(numMiss/(Montycarlo*bouncecount),numMiss/(Montycarlo*bouncecount),numMiss/(Montycarlo*bouncecount),1);
    //post-processing
        // pixel0 = pow( pixel0, 0.40 );
    // pixel0 = (pixel0)/(pixel0+1.);
    // pixel0 = pow( pixel0, 0.45 );//IQ
    // pixel0 = pow( pixel0, 0.33 );
    // pixel0 = (pixel0)/(luminance(pixel0.xyz)+1.);pixel0 = pow( pixel0, 0.45 );//IQ
        // RandomV2 = ((float3)(   ((float)xorshift32(234422.+(145341225.+(234422.*time))*(xorshift32(get_global_id(1)*get_global_size(0)+get_global_id(0))/4294967295.))/4294967295.),
        //                         ((float)xorshift32(654225.+(245341225.+(654225.*time))*(xorshift32(get_global_id(1)*get_global_size(0)+get_global_id(0))/4294967295.))/4294967295.),
        //                         ((float)xorshift32(897643.+(345341225.+(897643.*time))*(xorshift32(get_global_id(1)*get_global_size(0)+get_global_id(0))/4294967295.))/4294967295.)));
        // RandomV2 = (float3)((float)(xorshift32(RandomV2.z*4294967295.)/4294967295.),(float)(xorshift32(RandomV2.x*4294967295.)/4294967295.),(float)(xorshift32(RandomV2.y*4294967295.)/4294967295.));
    // pixel0 =(float4)(RandomV2,1.);
    write_imagef(framebuffer, coord,(float4)(pixel0.xyz,1.));
    }////    


