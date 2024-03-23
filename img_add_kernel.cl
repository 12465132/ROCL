float hash(float a){
    return sin(pow(a,(float)5.))*pow(a,(float)4.)*pow((float)3.14,a);
}

__kernel void add(
    sampler_t sampler_host,
    read_only image2d_t src_image,
    write_only image2d_t dst_image,
    int xgroup,
    int ygroup,
    int width,
    int height,
    float time
) 
{
    int2 coord = (int2)(get_global_id(0),get_global_id(1));
    float2 pcoord = (float2)((float)get_global_id(0)+width*xgroup,(float)get_global_id(1)+height*ygroup);
    float4 pixel = read_imagef(src_image, sampler_host, coord);
    pixel += (float4)(
        hash((pcoord.x+width*pcoord.y))*pow(cos(pcoord.y*0.0628318530718),2.),
        hash((pcoord.y+width*pcoord.x))*pow(cos(pcoord.x*0.0628318530718),2.),
        hash((pcoord.y*pcoord.x)),
        1.
    );
    pixel = (float4)(pow(cos((time*100.+pcoord.y)*0.0628318530718),2.),pow(cos((time*100.+pcoord.x)*0.0628318530718),2.),0.,1.);
    // pixel = (float4)((float)pcoord.x,(float)pcoord.y,1.,1.);
    write_imagef(dst_image, coord, pixel);
    //int i = get_global_id(0)%2==0?1:2;
    //buffer[get_global_id(0)] += sqrt((float)get_global_id(0))/(scalar+(float)get_global_id(0));
    //buffer[get_global_id(0)] += i;
}