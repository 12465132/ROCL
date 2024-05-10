

// //#define MOTIONBLUR
// //#define DEPTHOFFIELD

// #define CUBEMAPSIZE 32

// #define SAMPLES 8
// #define PATHDEPTH 4
// #define TARGETFPS 60.

// #define FOCUSDISTANCE 17.
// #define FOCUSBLUR 0.25

// #define RAYCASTSTEPS 10
// #define RAYCASTSTEPSRECURSIVE 2

// #define EPSILON 0.1
// #define MAXDISTANCE 50.
// #define GRIDSIZE 4.
// #define GRIDSIZESMALL 2.
// #define MAXHEIGHT 10.
// #define SPEED 2.

// //
// // math functions
// //

// float hash( const float n ) {
//      float a;
//      fract(sin(n)*43758.54554213,&a);
// 	return a;
// }
// float2 hash2( const float n ) {
//          float a;
// 	 fract(sin((float2)(n,n+1.))*(float2)(43758.5453123),&a);
//     	return a;
// }
// float2 hash22( const float2 n ) {
//          float a;
// 	 fract(sin((float2)( n.x*n.y, n.x+n.y))*(float2)(25.1459123,312.3490423),&a);
//     	return a;
// }
// float3 hash3( const float2 n ) {
//          float a;
// 	 fract(sin((float3)(n.x, n.y, n.x*n.y+2.0))*(float3)(36.5453123,43.1459123,11234.3490423),&a);
//     	return a;
// }
// //
// // intersection functions
// //

// float intersectPlane( const float3 ro, const float3 rd, const float height) {	
// 	if (rd.y==0.0) return 500.;	
// 	float d = -(ro.y - height)/rd.y;
// 	if( d > 0. ) {
// 		return d;
// 	}
// 	return 500.;
// }

// float intersectUnitSphere ( const float3 ro, const float3 rd, const float3 sph ) {
// 	float3  ds = ro - sph;
// 	float bs = dot( rd, ds );
// 	float cs = dot( ds, ds ) - 1.0;
// 	float ts = bs*bs - cs;

// 	if( ts > 0.0 ) {
// 		ts = -bs - sqrt( ts );
// 		if( ts > 0. ) {
// 			return ts;
// 		}
// 	}
// 	return 500.;
// }

// //
// // Scene
// //

// void getSphereOffset( const float2 grid, float2 *center ) {
// 	*center = (hash22( grid+(float2)(43.12,1.23) ) - (float2)(0.5))*(float2)(GRIDSIZESMALL);
// }
// void getMovingSpherePosition( const float2 grid, const float2 sphereOffset, float3 *center ) {
// 	// falling?
// 	float s = 0.1+hash( grid.x*1.23114+5.342+74.324231*grid.y );
// 	float t;
// 	fract(14.*s + time/s*.3,&t);
	
// 	float y =  s * MAXHEIGHT * abs( 4.*t*(1.-t) );
// 	float2 offset = grid + sphereOffset;
	
// 	*center = (float3)( offset.x, y, offset.y ) + 0.5*(float3)( GRIDSIZE, 2., GRIDSIZE );
// }
// void getSpherePosition( const float2 grid, const float2 sphereOffset, out float3 center ) {
// 	(float2) offset = grid + sphereOffset;
// 	center = (float3)( offset.x, 0., offset.y ) + 0.5*(float3)( GRIDSIZE, 2., GRIDSIZE );
// }
// (float3) getSphereColor( const float2 grid ) {
// 	(float3) col = hash3( grid+(float2)(43.12*grid.y,12.23*grid.x) );
//     return mix(col,col*col,.8);
// }

// (float3) getBackgroundColor( const float3 ro, const float3 rd ) {	
// 	return 1.4*mix((float3)(.5),(float3)(.7,.9,1), .5+.5*rd.y);
// }

// (float3) trace(const float3 ro, const float3 rd, out float3 intersection, out float3 normal, 
//            out float dist, out int material, const int steps) {
// 	dist = MAXDISTANCE;
// 	float distcheck;
	
// 	(float3) sphereCenter, col, normalcheck;
	
// 	material = 0;
// 	col = getBackgroundColor(ro, rd);
	
// 	if( (distcheck = intersectPlane( ro,  rd, 0.)) < MAXDISTANCE ) {
// 		dist = distcheck;
// 		material = 1;
// 		normal = (float3)( 0., 1., 0. );
// 		col = (float3)(.7);
// 	} 
	
// 	// trace grid
// 	(float3) pos = floor(ro/GRIDSIZE)*GRIDSIZE;
// 	(float3) ri = 1.0/rd;
// 	(float3) rs = sign(rd) * GRIDSIZE;
// 	(float3) dis = (pos-ro + 0.5  * GRIDSIZE + rs*0.5) * ri;
// 	(float3) mm = (float3)(0.0);
// 	(float2) offset;
		
// 	for( int i=0; i<steps; i++ )	{
// 		if( material == 2 ||  distance( ro.xz, pos.xz ) > dist+GRIDSIZE ) break; {
// 			getSphereOffset( pos.xz, offset );
			
// 			getMovingSpherePosition( pos.xz, -offset, sphereCenter );			
// 			if( (distcheck = intersectUnitSphere( ro, rd, sphereCenter )) < dist ) {
// 				dist = distcheck;
// 				normal = normalize((ro+rd*dist)-sphereCenter);
// 				col = getSphereColor(pos.xz);
// 				material = 2;
// 			}
			
// 			getSpherePosition( pos.xz, offset, sphereCenter );
// 			if( (distcheck = intersectUnitSphere( ro, rd, sphereCenter )) < dist ) {
// 				dist = distcheck;
// 				normal = normalize((ro+rd*dist)-sphereCenter);
// 				col = getSphereColor(pos.xz+(float2)(1.,2.));
// 				material = 2;
// 			}		
// 			mm = step(dis.xyz, dis.zyx);
// 			dis += mm * rs * ri;
// 			pos += mm * rs;		
// 		}
// 	}
	
// 	intersection = ro+rd*dist;
	
// 	return col;
// }

// (float2) rv2;

// float3 cosWeightedRandomHemisphereDirection2( const float3 n ) {
// 	(float3)  uu = normalize( cross( n, (float3)(0.0,1.0,1.0) ) );
// 	(float3)  vv = cross( uu, n );
	
// 	float ra = sqrt(rv2.y);
// 	float rx = ra*cos(6.2831*rv2.x); 
// 	float ry = ra*sin(6.2831*rv2.x);
// 	float rz = sqrt( 1.0-rv2.y );
// 	(float3)  rr = (float3)( rx*uu + ry*vv + rz*n );

//     return normalize( rr );
// }

// __kernel void add(
//     sampler_t sampler_host,
//     read_only image2d_t src_image,
//     write_only image2d_t dst_image,
//     int xgroup,
//     int ygroup,
//     int width,
//     int height,
//     float time
// ) 
// {
//     int2 coord = (int2)(get_global_id(0),get_global_id(1));
//     float2 pcoord = (float2)((float)get_global_id(0)+width*xgroup,(float)get_global_id(1)+height*ygroup);
//     float4 pixel = read_imagef(src_image, sampler_host, coord);
//     // for(int i=0;i<2;i++){
//     //     if(i%3==0){
//     //     pixel += (float4)(
//     //     hash((i*3.+pcoord.x+width*pcoord.y)),
//     //     hash((i*3.+pcoord.y+width*pcoord.x)),
//     //     hash((i*3.+width*pcoord.y*pcoord.x)),
//     //     1.
//     // );
//     //     }else if (i%2==0){
//     //     pixel += (float4)(
//     //     hash((i*3.+pcoord.x+width*pcoord.y)),
//     //     hash((i*3.+pcoord.y+width*pcoord.x)),
//     //     hash((i*3.+width*pcoord.y*pcoord.x)),
//     //     1.
//     // );   
//     //     } else {
//     //     pixel += (float4)(
//     //     hash((i*3.+pcoord.x+width*pcoord.y)),
//     //     hash((i*3.+pcoord.y+width*pcoord.x)),
//     //     hash((i*3.+width*pcoord.y*pcoord.x)),
//     //     1.
//     // );
//     //     }

//     // }
//     // pixel /= 11.;
//     // pixel *= 0.;
//     pixel = (float4)(pow(cos((time*100.+pcoord.y)*0.0628318530718),2.),pow(cos((time*111.+pcoord.x)*0.0628318530718),2.),0.,.5);
//     // pixel = (float4)((float)pcoord.x,(float)pcoord.y,1.,1.);
//     write_imagef(dst_image, coord, pixel);
//     //int i = get_global_id(0)%2==0?1:2;
//     //buffer[get_global_id(0)] += sqrt((float)get_global_id(0))/(scalar+(float)get_global_id(0));
//     //buffer[get_global_id(0)] += i;
// }

// __kernel void videorender(
//     sampler_t sampler_host,
//     read_only image2d_t src_image,
//     write_only image2d_t dst_image,
//     int xgroup,
//     int ygroup,
//     int width,
//     int height,
//     float time
// ) 
// {
//     int2 coord = (int2)(get_global_id(0),get_global_id(1));
//     float2 pcoord = (float2)((float)get_global_id(0)+width*xgroup,(float)get_global_id(1)+height*ygroup);
//     float4 pixel = read_imagef(src_image, sampler_host, coord);
//     float2 q = fragCoord.xy/iResolution.xy;
// 	float2 p = -1.0+2.0*q;
// 	p.x *= iResolution.x/iResolution.y;
	
// 	float3 col = (float3)( 0. );
	
// 	// raytrace
// 	int material;
// 	float3 normal, intersection;
// 	float dist;
// 	float seed = time+(p.x+iResolution.x*p.y)*1.51269341231;
	
// 	for( int j=0; j<SAMPLES + min(0,iFrame); j++ ) {
// 		float fj = (float)(j);
		
// #ifdef MOTIONBLUR
// 		time = iTime + fj/(float(SAMPLES)*TARGETFPS);
// #endif
		
// 		rv2 = hash2( 24.4316544311*fj+time+seed );
		
// 		float2 pt = p+rv2/(0.5*iResolution.xy);
				
// 		// camera	
// 		float3 ro = (float3)( cos( 0.232*time) * 10., 6.+3.*cos(0.3*time), GRIDSIZE*(time/SPEED) );
// 		float3 ta = ro + (float3)( -sin( 0.232*time) * 10., -2.0+cos(0.23*time), 10.0 );
		
// 		float roll = -0.15*sin(0.5*time);
		
// 		// camera tx
// 		float3 cw = normalize( ta-ro );
// 		float3 cp = (float3)( sin(roll), cos(roll),0.0 );
// 		float3 cu = normalize( cross(cw,cp) );
// 		float3 cv = normalize( cross(cu,cw) );
	
// #ifdef DEPTHOFFIELD
//     // create ray with depth of field
// 		const float fov = 3.0;
		
//         float3 er = normalize( (float3)( pt.xy, fov ) );
//         float3 rd = er.x*cu + er.y*cv + er.z*cw;

//         float3 go = FOCUSBLUR*(float3)( (rv2-(float2)(0.5))*2., 0.0 );
//         float3 gd = normalize( er*FOCUSDISTANCE - go );
		
//         ro += go.x*cu + go.y*cv;
//         rd += gd.x*cu + gd.y*cv;
// 		rd = normalize(rd);
// #else
// 		float3 rd = normalize( pt.x*cu + pt.y*cv + 1.5*cw );		
// #endif			
// 		float3 colsample = (float3)( 1. );
		
// 		// first hit
// 		rv2 = hash2( (rv2.x*2.4543263+rv2.y)*(time+1.) );
// 		colsample *= trace(ro, rd, intersection, normal, dist, material, RAYCASTSTEPS);

// 		// bounces
// 		for( int i=0; i<(PATHDEPTH-1); i++ ) {
// 			if( material != 0 ) {
// 				rd = cosWeightedRandomHemisphereDirection2( normal );
// 				ro = intersection + EPSILON*rd;
						
// 				rv2 = hash2( (rv2.x*2.4543263+rv2.y)*(time+1.)+(float(i+1)*.23) );
						
// 				colsample *= trace(ro, rd, intersection, normal, dist, material, RAYCASTSTEPSRECURSIVE);
// 			}
// 		}	
// 		colsample = sqrt(clamp(colsample, 0., 1.));
// 		if( material == 0 ) {			
// 			col += colsample;	
// 		}
// 	}
// 	col  /= (float)(SAMPLES);
	
// 	fragColor = (float4)( col,1.0);
// }
//     write_imagef(dst_image, coord, pixel);
//     //int i = get_global_id(0)%2==0?1:2;
//     //buffer[get_global_id(0)] += sqrt((float)get_global_id(0))/(scalar+(float)get_global_id(0));
//     //buffer[get_global_id(0)] += i;
// }