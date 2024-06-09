extern crate ocl;
extern crate pixels;
extern crate std;
use std::{fs::File, io::{Read, Write}};

use clap::builder::Str;

#[derive(Clone)]
pub struct L {
	pub color:[f32;3],	// diffuse color
	pub isLight:bool,	// has reflection 
	pub refraction:bool,	// has refraction
	pub n:f32,			// refraction index
	pub roughness:f32,	// Cook-Torrance roughness
	pub objectid:f32,		// Cook-Torrance fresnel reflectance
	pub RorTp:f32,		// Cook-Torrance color RorTp i.e. fraction of diffuse reflection
    pub isObjectBoundry:bool,
}
impl Copy for L {}

#[derive(Clone)]
pub struct triangle{
    pub p1:[f32;3],
    pub p2:[f32;3],    
    pub p3:[f32;3],  
    pub R:f32,  
    pub L:L,
}
impl Copy for triangle {}

pub struct MyApp {
    pub pro_que:ocl::ProQue,
    pub time:std::time::Instant,
    pub triangles:ocl::Image<f32>,
    pub dst_img:ocl::Image<f32>,
    pub framebuffer:ocl::Image<u8>,
    // pub src_img1:ocl::Image<f32>,
    // pub src_img2:ocl::Image<f32>,
    pub pixels:pixels::Pixels,
    pub raw_img:image::DynamicImage,
    pub frameintg:i32,
    pub CamPos:[f32;3],
    pub CamVec:[f32;3]
}
impl MyApp {
    pub fn new(
    pixels:pixels::Pixels,
    xtotal:usize,
    ytotal:usize,
    layers:usize,
    triangleslength:usize
    ) -> MyApp{
        let mut src:String = Default::default();
        File::open(std::path::PathBuf::from("OpenCL/mathConstants.cl")).expect("mathConstants.cl read not work").read_to_string(&mut src).unwrap();
        File::open(std::path::PathBuf::from("OpenCL/Structs.cl")      ).expect("mathConstants.cl read not work").read_to_string(&mut src).unwrap();
        File::open(std::path::PathBuf::from("OpenCL/mathFunctions.cl")).expect("mathConstants.cl read not work").read_to_string(&mut src).unwrap();
        File::open(std::path::PathBuf::from("OpenCL/render_kernel.cl")).expect("render_kernel.cl read not work").read_to_string(&mut src).unwrap();
        let image = 
        image::io::Reader::open(std::path::PathBuf::from("images/default.jpg")).unwrap()
                .decode().unwrap()
                .to_rgba8();
        let dims = 
            ocl::SpatialDims::Two(xtotal, ytotal);
        let pro_que = 
            ocl::ProQue::builder()
            .dims(dims)
            .context(
                ocl::Context::builder()
                .platform(ocl::Platform::default())
                .devices(ocl::enums::DeviceSpecifier::All)
                .build()
                .unwrap()
            )
            .prog_bldr(
                ocl::builders::ProgramBuilder::new()
                .source(src)
                .cmplr_opt(
                    " -cl-std=CL3.0 -cl-single-precision-constant -cl-unsafe-math-optimizations -cl-fast-relaxed-math -cl-finite-math-only -cl-mad-enable -w"
                )
                .to_owned()
            )
            .build()
            .unwrap();
        let dst_img1: ocl::Image<f32> = 
            ocl::Image::<f32>::builder()
            .channel_order(ocl::core::ImageChannelOrder::Rgba)
            .channel_data_type(ocl::core::ImageChannelDataType::Float)
            .image_type(ocl::enums::MemObjectType::Image3d)
            .dims(ocl::SpatialDims::Three(xtotal, ytotal, layers))
            .flags(
                ocl::flags::MEM_READ_WRITE
            )
            .queue(pro_que.queue().clone())
            .build()
            .expect("229");       
        let dst_img2: ocl::Image<u8> = 
            ocl::Image::<u8>::builder()
            .channel_order(ocl::core::ImageChannelOrder::Rgba)
            .channel_data_type(ocl::core::ImageChannelDataType::UnormInt8)
            .image_type(ocl::enums::MemObjectType::Image2d)
            .dims(pro_que.dims())
            .flags(
                ocl::flags::MEM_READ_WRITE
            )
            .copy_host_slice(&image)
            .queue(pro_que.queue().clone())
            .build()
            .expect("229");
        let raw_image = image::DynamicImage::new_rgba32f(xtotal as u32,ytotal as u32);
        let triangles: ocl::Image<f32> = 
            ocl::Image::<f32>::builder()
            .channel_order(ocl::core::ImageChannelOrder::Rgba)
            .channel_data_type(ocl::core::ImageChannelDataType::Float)
            .image_type(ocl::enums::MemObjectType::Image2d)
            .dims(ocl::SpatialDims::Two(6,triangleslength))
            .flags(
                ocl::flags::MEM_READ_WRITE
            )
            // .copy_host_slice(&image)
            .queue(pro_que.queue().clone())
            .build()
            .expect("229");
        let time = 
            std::time::Instant::now();
        MyApp { 
            pro_que: pro_que, 
            time: time, 
            triangles: triangles,
            dst_img: dst_img1, 
            framebuffer: dst_img2, 
            raw_img: raw_image,
            pixels: pixels,
            frameintg:0,
            CamPos:[2.78,-8.0,2.78],
            CamVec:[0.0,1.0,0.0],            
        }
            
    }

        pub fn render(&mut self,kernel:String
        ) -> &mut Self {

            let xtotal ;
            let ytotal ;
            
            match self.pro_que.dims().clone() {
                ocl::SpatialDims::Unspecified => return self,
                ocl::SpatialDims::One(_) => return self,
                ocl::SpatialDims::Two(xtot,ytot) => (xtotal,ytotal) = (xtot,ytot),
                ocl::SpatialDims::Three(_, _,_) => return self,
            }

            let kernel = self.pro_que.kernel_builder(kernel)
                .arg_sampler(&ocl::Sampler::new(self.pro_que.context(), true, ocl::enums::AddressingMode::Repeat, ocl::enums::FilterMode::Nearest).unwrap())
                .arg(&self.triangles)
                // .arg(&self.src_img1)
                // .arg(&self.src_img2)
                .arg(&self.dst_img)
                .arg(&self.framebuffer)
                .arg(self.frameintg)    
                .arg((self.time.elapsed().as_nanos() as f32)/1000000000.)
                .arg(self.CamPos[0])
                .arg(self.CamPos[1])
                .arg(self.CamPos[2])
                .arg(self.CamVec[0])
                .arg(self.CamVec[1])                
                .arg(self.CamVec[2])                             
                .build().expect("263");

            unsafe { kernel.enq().expect("265"); }
            self.frameintg +=1;
            self
        }
        /// Update the `World` internal state; bounce the box around the screen.
        pub fn updateframe(&mut self) -> &mut Self {
            self.framebuffer.read(&mut self.pixels.frame_mut()).enq().expect("267");
            self 
        }
        pub fn updatecam(&mut self,Pos:[f32;3],Vec:[f32;2]) -> &mut Self {
            self.CamPos[0] += Pos[0];
            self.CamPos[1] += Pos[1];
            self.CamPos[2] += Pos[2];
            if Vec[0]!=0.&& Vec[1]!=0.{
                let temp = camoffset(self.CamVec, Vec);
                self.CamVec[0] = temp[0];
                self.CamVec[1] = temp[1];
                self.CamVec[2] = temp[2];
            }
            self 
        }
        pub fn reset(&mut self) -> &mut Self {
            self.frameintg = 0;
            self
        }        
        pub fn checkstop(&mut self,framestostop:i32,S:String) -> &mut Self {
            if(self.frameintg==framestostop){
            self.save(S);
            todo!();
            }
            self
        }
        pub fn save(&mut self,S:String) -> &mut Self {
            let xtotal ;
            let ytotal ;
            match self.pro_que.dims().clone() {
                ocl::SpatialDims::Unspecified => return self,
                ocl::SpatialDims::One(_) => return self,
                ocl::SpatialDims::Two(xtot,ytot) => (xtotal,ytotal) = (xtot,ytot),
                ocl::SpatialDims::Three(_, _,_) => return self,
            }
            let mut image: image::ImageBuffer<image::Rgba<u8>, Vec<u8>> = image::ImageBuffer::from_pixel((xtotal) as u32, (ytotal) as u32, image::Rgba([0,0,0,0_u8]));
            self.framebuffer.read(&mut image).enq().unwrap();
            image.save(&std::path::Path::new(&S)).unwrap();
            self
        }
        pub fn loadtriangles(&mut self,triangles:Vec<triangle>) -> &mut Self {
            if let ocl::SpatialDims::Two(_,maxtriangles) = self.triangles.dims(){
                if triangles.len()>*maxtriangles {return self}
            }
            let mut a: Vec<f32> = vec![0.5;triangles.len()*6*4];
            let mut b = a.as_mut_slice();
            for (i,triangle) in triangles.iter().enumerate() {
                b[6*4*i+00]= triangle.p1[0];                                //h(1)=p1.x
                b[6*4*i+01]= triangle.p1[1];                                //h(1)=p1.x
                b[6*4*i+02]= triangle.p1[2];                                //h(1)=p1.y
                b[6*4*i+03]= 0.;                                //h(1)=p1.z
                b[6*4*i+04]= triangle.p2[0];                                //h(2)=p2.x
                b[6*4*i+05]= triangle.p2[1];                                //h(2)=p2.y
                b[6*4*i+06]= triangle.p2[2];                                //h(2)=p2.z
                b[6*4*i+07]= 0.;                                //h(3)=p3.x
                b[6*4*i+08]= triangle.p3[0];                        //h(3)=p3.y
                b[6*4*i+09]= triangle.p3[1];                        //h(3)=p3.z
                b[6*4*i+10]= triangle.p3[2];                          //h(4).x=radius
                b[6*4*i+11]= 0.;
                b[6*4*i+12]= triangle.R;                    //h(5).x=roughness
                b[6*4*i+13]= triangle.L.n;  
                b[6*4*i+14] = 4.*(triangle.L.isObjectBoundry as i32 as f32)+2.*(triangle.L.isLight as i32 as f32)+1.*(triangle.L.refraction as i32 as f32);
                b[6*4*i+15]= 0.;                           //h(5).x=color.x
                b[6*4*i+16]= triangle.L.roughness;                           //h(5).y=color.y
                b[6*4*i+17]= triangle.L.objectid; 
                b[6*4*i+18]= triangle.L.RorTp; 
                b[6*4*i+19]= 0.; 
                b[6*4*i+20]= triangle.L.color[0]; 
                b[6*4*i+21]= triangle.L.color[1]; 
                b[6*4*i+22]= triangle.L.color[2]; 
                b[6*4*i+23]= 1.; 
                // match (triangle.L.reflection,triangle.L.refraction){    //h(4).z=conditional
                //     (false,false)=>b[6*4*i+14]=1., //(h(4).z=1) when ((reflection==false) &&(refraction==false))
                //     (false,true)=> b[6*4*i+14]=2., //(h(4).z=2) when ((reflection==false) &&(refraction==true ))
                //     (true,false)=> b[6*4*i+14]=3., //(h(4).z=3) when ((reflection==true ) &&(refraction==false))
                //     (true,true)=>  b[6*4*i+14]=4., //(h(4).z=4) when ((reflection==true ) &&(refraction==true ))
                //     _=>return self}                              //h(5).z=color.z
            }
            self.triangles.write(b).enq().unwrap();
            self
        }

        // Draw the `World` state to the frame buffer.
        //
        // Assumes the default texture format: `wgpu::TextureFormat::Rgba8UnormSrgb`
        // fn draw(&mut self, pixels: &mut [u8]) {
        //     // self.render();
        //     pixels
        //     .swap_with_slice(&mut (*self.raw_img.clone()))  
        // }
}

//normandy is a place
//iceland isnt real
//spain is french

pub fn myapprender(
    file_path:std::path::PathBuf,
    image:String,
    xtotal:usize,
    ytotal:usize
) {
    // // let _now_cpu = Instant::now();
    // let mut imageout: ImageBuffer<image::Rgba<u8>, Vec<u8>> = image::ImageBuffer::from_pixel(xtotal as u32, ytotal as u32, image::Rgba([0,0,0,0]));
    // let event_loop = EventLoop::new().unwrap();
    // let window = winit::window::Window::new(&event_loop).unwrap();
    // window.set_visible(false);
    // let pixels = {
    //     let window_size = window.inner_size();
    //     let surface_texture = SurfaceTexture::new(window_size.width, window_size.height, &window);
    //     Pixels::new(xtotal.try_into().unwrap(), ytotal.try_into().unwrap(), surface_texture).unwrap()
    // };
    // let mut my_app_renderer = MyApp::new(pixels, file_path,image.clone(), xtotal, ytotal);

    // my_app_renderer.render("sobel_edge".to_string());

    //     my_app_renderer.dst_img.read(&mut imageout).enq().unwrap();
    //     imageout.save(&Path::new("oclt_computed1.png")).unwrap();

    // my_app_renderer.dst_img.cmd().copy(&my_app_renderer.src_img1, [0, 0, 0]).enq().unwrap();
    // my_app_renderer.render("gauss_filter".to_string());

    //     my_app_renderer.dst_img.read(&mut imageout).enq().unwrap();
    //     imageout.save(&Path::new("oclt_computed2.png")).unwrap();

    // my_app_renderer.src_img1.write(&image::io::Reader::open(image.clone()).unwrap().decode().unwrap().to_rgba8()).enq().unwrap();
    // my_app_renderer.dst_img.cmd().copy(&my_app_renderer.src_img2, [0, 0, 0]).enq().unwrap();
    // // MyApp_renderer.src_img2.cmd().copy(&MyApp_renderer.dst_img, [0, 0, 0]).enq().unwrap();
    // my_app_renderer.render("dyn_gauss".to_string());

    //     my_app_renderer.dst_img.read(&mut imageout).enq().unwrap();
    //     imageout.save(&Path::new("oclt_computed3.png")).unwrap();

    // // MyApp_renderer.src_img1.cmd().copy(&MyApp_renderer.dst_img, [0, 0, 0]).enq().unwrap();
    // my_app_renderer.dst_img.cmd().copy(&my_app_renderer.src_img1, [0, 0, 0]).enq().unwrap();
    // my_app_renderer.render("sharpen".to_string());
    
    //     my_app_renderer.dst_img.read(&mut imageout).enq().unwrap();
    //     imageout.save(&Path::new("oclt_computed4.png")).unwrap();

}

// bool rayTriangleIntersect(
//     const Vec3f &orig, const Vec3f &dir,
//     const Vec3f &v0, const Vec3f &v1, const Vec3f &v2,
//     float &t, float &u, float &v)
// {
// #ifdef MOLLER_TRUMBORE
//     Vec3f v0v1 = v1 - v0;
//     Vec3f v0v2 = v2 - v0;
//     Vec3f pvec = dir.crossProduct(v0v2);
//     float det = v0v1.dotProduct(pvec);
// #ifdef CULLING
//     // if the determinant is negative the triangle is backfacing
//     // if the determinant is close to 0, the ray misses the triangle
//     if (det < kEpsilon) return false;
// #else
//     // ray and triangle are parallel if det is close to 0
//     if (fabs(det) < kEpsilon) return false;
// #endif
//     float invDet = 1 / det;

//     Vec3f tvec = orig - v0;
//     u = tvec.dotProduct(pvec) * invDet;
//     if (u < 0 || u > 1) return false;

//     Vec3f qvec = tvec.crossProduct(v0v1);
//     v = dir.dotProduct(qvec) * invDet;
//     if (v < 0 || u + v > 1) return false;
    
//     t = v0v2.dotProduct(qvec) * invDet;
    
//     return true;
// #else
//     // compute plane's normal
//     Vec3f v0v1 = v1 - v0;
//     Vec3f v0v2 = v2 - v0;
//     // no need to normalize
//     Vec3f N = v0v1.crossProduct(v0v2); // N
//     float denom = N.dotProduct(N);
    
//     // Step 1: finding P
    
//     // check if ray and plane are parallel ?
//     float NdotRayDirection = N.dotProduct(dir);

//     if (fabs(NdotRayDirection) < kEpsilon) // almost 0
//         return false; // they are parallel so they don't intersect ! 

//     // compute d parameter using equation 2
//     float d = -N.dotProduct(v0);
    
//     // compute t (equation 3)
//     t = -(N.dotProduct(orig) + d) / NdotRayDirection;
    
//     // check if the triangle is in behind the ray
//     if (t < 0) return false; // the triangle is behind
 
//     // compute the intersection point using equation 1
//     Vec3f P = orig + t * dir;
 
//     // Step 2: inside-outside test
//     Vec3f C; // vector perpendicular to triangle's plane
 
//     // edge 0
//     Vec3f edge0 = v1 - v0; 
//     Vec3f vp0 = P - v0;
//     C = edge0.crossProduct(vp0);
//     if (N.dotProduct(C) < 0) return false; // P is on the right side
 
//     // edge 1
//     Vec3f edge1 = v2 - v1; 
//     Vec3f vp1 = P - v1;
//     C = edge1.crossProduct(vp1);
//     if ((u = N.dotProduct(C)) < 0)  return false; // P is on the right side
 
//     // edge 2
//     Vec3f edge2 = v0 - v2; 
//     Vec3f vp2 = P - v2;
//     C = edge2.crossProduct(vp2);
//     if ((v = N.dotProduct(C)) < 0) return false; // P is on the right side;

//     u /= denom;
//     v /= denom;

//     return true; // this ray hits the triangle
// #endif
// }
fn camoffset (v:[f32;3],o:[f32;2]) -> [f32;3] {
    let mut t0: [f32; 3] = [-(v[1])*o[0],(v[0])*o[0],0.];
    let mut t1: [f32; 3] = [-v[2]*v[0]*o[1],-v[2]*v[1]*o[1],(v[0]*v[0]*o[1]+v[1]*v[1]*o[1])];
    let t0_n:f32 = (t0[0]*t0[0]+t0[1]*t0[1]+t0[2]*t0[2]).sqrt();
    let t1_n:f32 = (t1[0]*t1[0]+t1[1]*t1[1]+t1[2]*t1[2]).sqrt();
    t0 = [t0[0]/t0_n,t0[2]/t0_n,t0[2]/t0_n];
    t1 = [t1[0]/t1_n,t1[2]/t1_n,t1[2]/t1_n];   
    return [
        v[0]+t0[0]+t1[0],
        v[1]+t0[1]+t1[1],
        v[2]+t0[2]+t1[2]
    ] 
}



// (v)+
// normalize([-(v[1])*o[0],(v[0])*o[0],0.])+
// normalize([-v[2]*v[0]*o[1],-v[2]*v[1]*o[1],(v[0]*v[0]*o[1]+v[1]*v[1]*o[1])]);