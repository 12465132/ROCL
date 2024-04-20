

__constant int SEED = 0;

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
__kernel void render(
    sampler_t sampler_host,
    read_only image2d_t src_image1,
    read_only image2d_t src_image2,
    write_only image2d_t dst_image,
    int xgroup,
    int ygroup,
    int width,
    int height,
    float time
) {
    int2 coord = (int2)(get_global_id(0),get_global_id(1));
    float2 uv = (float2)(((float)get_global_id(0)+.001)/(float)(width),((float)get_global_id(1)+.001)/(float)height);
    float2 i = (float2)(1.00/width,0/height);
    float2 j = (float2)(0/width,1.00/height);
    float2 pcoord = (float2)((float)get_global_id(0)+width*xgroup,(float)get_global_id(1)+height*ygroup);
    float loop_time = 10;
    // float time = fmod(t,loop_time); 
    float b = -1;
    float p = .5;
    float noise = 0;
    float4 pixels = 0;
    noise = clamp(round((.5+half_exp10(b))*hash11(perlin2d(time+get_global_id(0),time+get_global_id(1),.01,2))),0.,1.);
    if(noise>0.){
    pixels = 
         p*read_imagef(src_image1, sampler_host,uv)*noise+
     (1-p)*read_imagef(src_image2, sampler_host,uv);//lastframe
            
    }else{
    pixels = 
        read_imagef(src_image2, sampler_host,uv);//lastframe
     }
    // pixels = (float4)(pixels.xyz,1.);
    write_imagef(dst_image, coord,pixels);
}
__kernel void renderraw(
    sampler_t sampler_host,
    read_only image2d_t src_image1,
    read_only image2d_t src_image2,
    write_only image2d_t dst_image,
    int xgroup,
    int ygroup,
    int width,
    int height,
    float time
) {
    int2 coord = (int2)(get_global_id(0),get_global_id(1));
    float2 uv = (float2)(((float)get_global_id(0)+.001)/(float)(width),((float)get_global_id(1)+.001)/(float)height);
    float2 i = (float2)(1.00/width,0/height);
    float2 j = (float2)(0/width,1.00/height);
    float2 pcoord = (float2)((float)get_global_id(0)+width*xgroup,(float)get_global_id(1)+height*ygroup);
    float loop_time = 10;
    // float time = fmod(t,loop_time); 
    float b = -1.;
    float p = .5;
    float noise = 0;
    float4 pixels = 0;
    noise = clamp(round((.5+half_exp10(b))*hash11(perlin2d(time+get_global_id(0),time+get_global_id(1),.01,2))),0.,1.);
    pixels = read_imagef(src_image1, sampler_host,uv)*noise;
    //  (1-p)*read_imagef(src_image2, sampler_host,uv);//lastframe
    pixels *= (float4)(
        hash11(perlin2d(500.+time+get_global_id(0),100.+time+get_global_id(1),.01,2)),
        hash11(perlin2d(2.00+time+get_global_id(0),2.00+time+get_global_id(1),.01,2)),
        hash11(perlin2d(2.00+time+get_global_id(1),2.00+time+get_global_id(0),.01,2)),1.);
    pixels = (float4)(pixels.xyz,1.);
    write_imagef(dst_image, coord,pixels);
}
__kernel void add(
    sampler_t sampler_host,
    read_only image2d_t src_image1,
    read_only image2d_t src_image2,
    write_only image2d_t dst_image,
    int xgroup,
    int ygroup,
    int width,
    int height,
    float time
) 
{
    int2 coord = (int2)(get_global_id(0),get_global_id(1));
    float2 uv = (float2)(((float)get_global_id(0)+.001)/(float)(width),((float)get_global_id(1)+.001)/(float)height);
    float2 i = (float2)(1.00/width,0/height);
    float2 j = (float2)(0/width,1.00/height);
    float2 pcoord = (float2)((float)get_global_id(0)+width*xgroup,(float)get_global_id(1)+height*ygroup);
    float loop_time = 10;
    // float time = fmod(t,loop_time); 
    float b = 4.-time*.01;
    float p = .1;
    float noise = 0;
    float4 pixels = 0;
    noise = clamp(round((.5+half_exp10(b))*hash11(perlin2d(time+get_global_id(0),time+get_global_id(1),.01,2))),0.,1.);
    if(noise>0.){
    pixels = 
         p*read_imagef(src_image1, sampler_host,uv)*noise+
     (1-p)*read_imagef(src_image2, sampler_host,uv);//lastframe
    pixels *= (float4)(
        hash11(perlin2d(500.+time+get_global_id(0),100.+time+get_global_id(1),.01,2)),
        hash11(perlin2d(2.00+time+get_global_id(0),2.00+time+get_global_id(1),.01,2)),
        hash11(perlin2d(2.00+time+get_global_id(1),2.00+time+get_global_id(0),.01,2)),1.);
    
    }else{
    pixels = 
        read_imagef(src_image2, sampler_host,uv);//lastframe
     }
    pixels = (float4)(pixels.xyz,1.);
    write_imagef(dst_image, coord,pixels);
}////     // pixels = (float4)(pow(cos((sin(time)*100.+pcoord.y)*0.0628318530718),2.),pow(cos((sin(time)*100.+pcoord.x)*0.0628318530718),2.),0.,1.);////  noise = min(1.,round((.5+half_exp10(b))*hash11(perlin2d(time+get_global_id(0),time+get_global_id(1),.01,2))));////  if(noise > 0.){////  /// rendering//// //  pixels = read_imagef(src_image1, sampler_host,uv);//image render////     pixels = read_imagef(src_image2, sampler_host,uv);////     // pixels = (float4)(hash11(perlin2d(time+get_global_id(0),time+get_global_id(1),.01,20)),hash11(perlin2d(time+get_global_id(1),time+get_global_id(0),.01,20)),hash11(perlin2d(time+get_global_id(0),time+get_global_id(1),.02,20)),1.);//// //  pixels = renderimage();//image render//// //  pixels *= (float4)(noise);////  ///rendering//// pixels = ////      p*pixels+////  (1-p)*read_imagef(src_image2, sampler_host,uv);//lastframe////  }else{//// pixels = ////     read_imagef(src_image2, sampler_host,uv);//lastframe////  }//// //  pixels = read_imagef(src_image1, sampler_host,uv);//lastframe//// pixels = (float4)(pixels.xyz,1.);//// // pixels = (float4)(hash11(perlin2d(time+get_global_id(0),time+get_global_id(1),.01,20)),hash11(perlin2d(time+get_global_id(1),time+get_global_id(0),.01,20)),hash11(perlin2d(time+get_global_id(0),time+get_global_id(1),.02,20)),1.);//// // pixels = (float4)(//// //     min(1.,round((.5+half_exp10(b))*hash11(perlin2d(time+get_global_id(0),time+get_global_id(1),.01,2)))),//// //     min(1.,round((.5+half_exp10(b))*hash11(perlin2d(time+get_global_id(0),time+get_global_id(1),.01,2)))),//// //     min(1.,round((.5+half_exp10(b))*hash11(perlin2d(time+get_global_id(0),time+get_global_id(1),.01,2)))),//// //     1.);

__kernel void sobel_edge(
    sampler_t sampler_host,
    read_only image2d_t src_image1,
    read_only image2d_t src_image2,
    write_only image2d_t dst_image,
    int xgroup,
    int ygroup,
    int width,
    int height,
    float time
){
    int2 coord = (int2)(get_global_id(0),get_global_id(1));
    float2 uv = (float2)(((float)get_global_id(0)+.001)/(float)(width),((float)get_global_id(1)+.001)/(float)height);
    float2 i = (float2)(1.00/width,0/height);
    float2 j = (float2)(0/width,1.00/height);
    float2 pcoord = (float2)((float)get_global_id(0)+width*xgroup,(float)get_global_id(1)+height*ygroup);
    int kernel_rad1 = 7;
    // float4 pixel = (float4)(0.);
    float minval = .1;
    float3 GX = 0;
    float3 GY = 0; 
    for (int xs = -kernel_rad1; xs <= kernel_rad1; xs++)
    {
        for (int ys = -kernel_rad1; ys <= kernel_rad1; ys++)
        {
           GX += min(1.,(read_imagef(src_image1, sampler_host,uv+i*xs+j*ys).xyz*xs/(xs*xs+ys*ys)));
           GY += min(1.,(read_imagef(src_image1, sampler_host,uv+i*xs+j*ys).xyz*ys/(xs*xs+ys*ys)));
    }}
    float4 Go = (float4)((1-GX)*(1-GX)+(1-GY)*(1-GY),1.);
float mag = length(Go.xyz);
    float4 G =(float4)((float3)(mag),1.);
    if(length(Go.xyz)<minval){
        Go = (float4)(0,0,0,1);
    }
    write_imagef(dst_image, coord, Go);
}
__kernel void gauss_filter(
    sampler_t sampler_host,
    read_only image2d_t src_image1,
    read_only image2d_t src_image2,
    write_only image2d_t dst_image,
    int xgroup,
    int ygroup,
    int width,
    int height,
    float time
){
    int2 coord = (int2)(get_global_id(0),get_global_id(1));
    float2 uv = (float2)(((float)get_global_id(0)+.001)/(float)(width),((float)get_global_id(1)+.001)/(float)height);
    float2 i = (float2)(1.00/width,0/height);
    float2 j = (float2)(0/width,1.00/height);
    int kernel_rad  = 8;
    float sigma = 9;
    float sum_gauss = 0.; 
    float4 pixel = (float4)(0.);
    if (sigma==0){
        pixel = read_imagef(src_image1, sampler_host,uv);
    }else{
        for (int xs = -kernel_rad; xs <= kernel_rad; xs++)
    {
        for (int ys = -kernel_rad; ys <= kernel_rad; ys++)
        {
            
            float gh = exp(-(float)(xs*xs+ys*ys)*half_recip(sigma*sigma)*0.5)*.1591*half_recip(sigma*sigma);
            sum_gauss += gh;
            pixel += read_imagef(src_image1, sampler_host,uv+i*xs+j*ys)*gh;
        }
    }
    pixel *= half_recip(sum_gauss);
    }


    write_imagef(dst_image, coord, pixel);
}
__kernel void dyn_gauss(
    sampler_t sampler_host,
    read_only image2d_t src_image1,
    read_only image2d_t src_image2,
    write_only image2d_t dst_image,
    int xgroup,
    int ygroup,
    int width,
    int height,
    float time
){
    int2 coord = (int2)(get_global_id(0),get_global_id(1));
    float2 uv = (float2)(((float)get_global_id(0)+.001)/(float)(width),((float)get_global_id(1)+.001)/(float)height);
    float2 i = (float2)(1.00/width,0/height);
    float2 j = (float2)(0/width,1.00/height);
    float2 pcoord = (float2)((float)get_global_id(0)+width*xgroup,(float)get_global_id(1)+height*ygroup);
    float const_blur = 0.01;
    // int kernel_rad1 = 5;
    // float sigma = 1;
    float sum_gauss = 0.; 
    float4 pixel = (float4)(0.);
    float4 Go = read_imagef(src_image2, sampler_host,uv);
    float mag = length(Go.xyz);
    mag = mag*1.414;
    float kr = 5;
    int kernel_rad  = half_recip(mag+half_recip(kr));

    // float4 G =(float4)((float3)(mag),1.);
    if(1==0){
        pixel += read_imagef(src_image1, sampler_host,uv);
    }else{
        for (int xs = -kernel_rad; xs <= kernel_rad; xs++)
        {
        for (int ys = -kernel_rad; ys <= kernel_rad; ys++)
        {
            float4 kernel_pixel = read_imagef(src_image1, sampler_host,uv+i*xs+j*ys);
            float gh = exp(-(float)(xs*xs+ys*ys)*(mag+const_blur)*0.5)*.1591*(mag+const_blur)*kernel_pixel.w;
            sum_gauss += gh;
            pixel += kernel_pixel*gh;
        }
        }
    pixel *= half_recip(sum_gauss);
    }

    // // pixel /= (2*kernel_rad+1)*(2*kernel_rad+1);
    // float4 pixels = read_imagef(src_image, sampler_host,uv);//passthrough
    pixel = (float4)(pixel.xyz,1.);
    // pixel = (float4)(Go.xyz,1.);
    write_imagef(dst_image, coord, pixel);
}
__kernel void sharpen(
    sampler_t sampler_host,
    read_only image2d_t src_image1,
    read_only image2d_t src_image2,
    write_only image2d_t dst_image,
    int xgroup,
    int ygroup,
    int width,
    int height,
    float time
){
    int2 coord = (int2)(get_global_id(0),get_global_id(1));
    float2 uv = (float2)(((float)get_global_id(0)+.001)/(float)(width),((float)get_global_id(1)+.001)/(float)height);
    float2 i = (float2)(1.00/width,0/height);
    float2 j = (float2)(0/width,1.00/height);
    float a = 0;
    float4 pixel = 
    // -1*read_imagef(src_image1, sampler_host,uv+i*-1+j*-1)+
    -1*read_imagef(src_image1, sampler_host,uv+i*-1+j*0.)+
    // -1*read_imagef(src_image1, sampler_host,uv+i*-1+j*1.)+
    -1*read_imagef(src_image1, sampler_host,uv+i*0.+j*-1)+
    5*read_imagef(src_image1, sampler_host,uv+i*0.+j*0.)+
    -1*read_imagef(src_image1, sampler_host,uv+i*0.+j*1.)+
    // -1*read_imagef(src_image1, sampler_host,uv+i*1.+j*-1)+
    -1*read_imagef(src_image1, sampler_host,uv+i*1.+j*0.)
    // -1*read_imagef(src_image1, sampler_host,uv+i*1.+j*1.)
    ;
    // pixel /= 9;
    pixel = (float4)(pixel.xyz,1.);
    // pixel = (float4)(hash(get_global_id(0)+width*get_global_id(1)),1.);
   write_imagef(dst_image, coord, pixel); 
}