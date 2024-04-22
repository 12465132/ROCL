extern crate ocl;
extern crate pixels;
extern crate std;
use std::{fs::File, io::Read};

#[derive(Clone)]
pub struct L {
	pub color:[f32;3],	// diffuse color
	pub reflection:bool,	// has reflection 
	pub refraction:bool,	// has refraction
	pub n:f32,			// refraction index
	pub roughness:f32,	// Cook-Torrance roughness
	pub fresnel:f32,		// Cook-Torrance fresnel reflectance
	pub density:f32,		// Cook-Torrance color density i.e. fraction of diffuse reflection
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
    pub dst_img1:ocl::Image<u8>,
    pub dst_img2:ocl::Image<u8>,
    pub src_img1:ocl::Image<u8>,
    pub src_img2:ocl::Image<u8>,
    pub raw_img:pixels::Pixels,
    frameintg:i32
}
impl MyApp {
    pub fn new(
    pixels:pixels::Pixels,
    file_path:std::path::PathBuf,
    image_path:String,
    xtotal:usize,
    ytotal:usize,
    triangleslength:usize
    ) -> MyApp{
        let mut src:String = 
            Default::default();
        File::open(&file_path).expect("file read not work").read_to_string(&mut src).unwrap();
        let image = 
            image::io::Reader::open(image_path).unwrap()
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
                .src_file(file_path)
                .cmplr_opt(
                    " -cl-unsafe-math-optimizations -cl-fast-relaxed-math -cl-finite-math-only -cl-mad-enable "
                )
                .to_owned()
            )
            .build()
            .unwrap();
        let src_img1 = 
            ocl::builders::ImageBuilder::<u8>::new()
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
            .expect("214");
        let src_img2 = 
            ocl::builders::ImageBuilder::<u8>::new()
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
            .expect("214");
        let dst_img1: ocl::Image<u8> = 
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
        let triangles: ocl::Image<f32> = 
            ocl::Image::<f32>::builder()
            .channel_order(ocl::core::ImageChannelOrder::Rgba)
            .channel_data_type(ocl::core::ImageChannelDataType::Float)
            .image_type(ocl::enums::MemObjectType::Image2d)
            .dims(ocl::SpatialDims::Two(5,triangleslength))
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
            dst_img1: dst_img1, 
            dst_img2: dst_img2, 
            src_img1: src_img1, 
            src_img2: src_img2, 
            raw_img: pixels,
            frameintg:0
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
                .arg(&self.src_img1)
                .arg(&self.src_img2)
                .arg(&self.dst_img1)
                .arg(&self.dst_img2)
                .arg(self.frameintg)    
                .arg((self.time.elapsed().as_nanos() as f32)/1000000000.)             
                .build().expect("263");

            unsafe { kernel.enq().expect("265"); }
            self.frameintg +=1;
            self
        }
        /// Update the `World` internal state; bounce the box around the screen.
        pub fn update(&mut self) -> &mut Self {
            self.dst_img1.read(self.raw_img.frame_mut()).enq().expect("267");
            self 
        }
        pub fn reset(&mut self) -> &mut Self {
            self.frameintg = 0;
            self
        }
        pub fn loadtriangles(&mut self,triangles:Vec<triangle>) -> &mut Self {
            if let ocl::SpatialDims::Two(_,maxtriangles) = self.triangles.dims(){
                if triangles.len()>*maxtriangles {return self}
            }
            let mut a: Vec<f32> = vec![0.;triangles.len()*5*3];
            let mut b = a.as_mut_slice();
            for (i,triangle) in triangles.iter().enumerate() {
                b[i+01]= triangle.p1[0];                                //h(1)=p1.x
                b[i+02]= triangle.p1[1];                                //h(1)=p1.y
                b[i+03]= triangle.p1[2];                                //h(1)=p1.z
                b[i+04]= triangle.p2[0];                                //h(2)=p2.x
                b[i+05]= triangle.p2[1];                                //h(2)=p2.y
                b[i+06]= triangle.p2[2];                                //h(2)=p2.z
                b[i+07]= triangle.p3[0];                                //h(3)=p3.x
                b[i+08]= triangle.p3[1];                                //h(3)=p3.y
                b[i+09]= triangle.p3[2];                                //h(3)=p3.z
                b[i+10]= triangle.R;                                    //h(4).x=radius
                b[i+11]= triangle.L.n;                                  //h(4).y=n
                match (triangle.L.reflection,triangle.L.refraction){    //h(4).z=conditional
                    (false,false)=>b[i+12]=1.,                          //(h(4).z=1) when ((reflection==false) &&(refraction==false))
                    (false,true)=>b[i+12]=2.,                           //(h(4).z=2) when ((reflection==false) &&(refraction==true ))
                    (true,false)=>b[i+12]=3.,                           //(h(4).z=3) when ((reflection==true ) &&(refraction==false))
                    (true,true)=>b[i+12]=4.,                            //(h(4).z=4) when ((reflection==true ) &&(refraction==true ))
                    _=>return self}                                     //future 
                b[i+13]= triangle.L.roughness;                          //h(5).x=roughness
                b[i+14]= triangle.L.fresnel;                            //h(5).y=fresnel
                b[i+15]= triangle.L.density;                            //h(5).z=density
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