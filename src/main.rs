
    #[macro_use] 
    extern crate colorify;
    extern crate ocl;
    extern crate fastrand;
    extern crate image;
    // extern crate iced;
    use clap::{Parser, Subcommand};
    // use ocl::{ Context, Device,  Image,  Platform, Result as OclResult, SpatialDims,Sampler};
    use ocl::enums::ImageChannelDataType;
    use ocl::enums::ImageChannelOrder;
    use ocl::Platform;
    


    
    use std::time::{Instant};
    use ocl::ProQue;
    use std::path::Path;
    use std::{self,};
    use image::{/* GenericImage, GenericImageView, */ ImageBuffer};
    use std::fs;
    use std::fs::File;
    use std::io::Read;
    
    use std::thread::{self};
    use std::path::PathBuf;
    
    // use iced::{executor, Application, Command, Element, Length};
    // use iced::widget::{ container};
    // use iced::{ Theme};  
    // use iced::alignment;
    // use iced::mouse;
    // use iced::widget::canvas::{stroke, Cache, Geometry, LineCap, Path, Stroke};
    // use iced::widget::{canvas, container};
    // use iced::{
    //     Degrees, Element, Font, Length, Point, Rectangle, Renderer, Subscription,
    //     Theme, Vector,
    // };
    
    // use crate::gui::Framework;
    use error_iter::ErrorIter as _;
    use log::error;
    use pixels::{Error, Pixels, SurfaceTexture};
    use winit::dpi::LogicalSize;
    use winit::event::{Event, VirtualKeyCode};
    use winit::event_loop::{ControlFlow, EventLoop};
    use winit::window::WindowBuilder;
    use winit_input_helper::WinitInputHelper;
    use std::sync::{Arc, Barrier};
    use std::sync::{Mutex};

    // use std::thread;
    // mod gui;
    
    // const WIDTH: u32 = 1920;
    // const HEIGHT: u32 = 1080;
    
    // #![allow(unused)]
    fn pixels_ez_renderer(file_path:PathBuf,
        xtotal:usize,
        ytotal:usize
    ) -> Result<(), Error> {
        env_logger::init();
        let event_loop = EventLoop::new();
        let mut input = WinitInputHelper::new();
        let window = {
            let size = LogicalSize::new(xtotal as f64, ytotal as f64);
            WindowBuilder::new()
                .with_title("Hello Pixels")
                // .with_inner_size(size)
                .with_min_inner_size(size)
                .with_max_inner_size(size)
                .with_transparent(true)
                // .with_active(false)
                // .with_fullscreen(Some(Fullscreen::Borderless(None)))
                .build(&event_loop)
                .unwrap()
        };
        window
            .set_cursor_visible(false);
            let mut pixels = {
                let window_size = window.inner_size();
                let surface_texture = SurfaceTexture::new(window_size.width, window_size.height, &window);
                Pixels::new(xtotal.try_into().unwrap(), ytotal.try_into().unwrap(), surface_texture)?
            };
            let mut frames = 0;
            let mut loops = 0;
            let barrier = Arc::new(Barrier::new(2));
            let world = Arc::new(Mutex::new(MyApp::new(file_path,xtotal,ytotal)));
            let c2 = Arc::clone(&barrier);

            let _renderThread = {
                let c1 = Arc::clone(&barrier);
                let worldt = Arc::clone(&world);
                thread::spawn(move || {
                loop {
                    // print!("|");
                    c1.wait();
                    worldt.lock().unwrap().render();
                    // print!("|");
                }
                })
            };
            let now_total = Instant::now();

            event_loop.run(move |event, _, control_flow| {
                let _now_save = Instant::now();
                loops +=1;
                // Draw the current frame
                if let Event::RedrawRequested(_) = event {
                    // let mut a = pixels.frame_mut();
                    // a = world.draw().as_mut_slice();
                     c2.wait();
                     world.lock().unwrap().draw(pixels.frame_mut());
                     frames+=1;
                    if let Err(err) = pixels.render() {
                        log_error("pixels.render", err);
                        *control_flow = ControlFlow::Exit;
                        return;
                    }
                }
        
                // Handle input events
                if input.update(&event) {
                    // Close events
                    if  input.key_pressed(VirtualKeyCode::Escape) ||
                    (input.key_held(VirtualKeyCode::LControl) &&
                     input.key_held(VirtualKeyCode::C) )|| 
                    input.close_requested() {
                        *control_flow = ControlFlow::Exit;
                        return;
                    }
        
                    // Resize the window
                    if let Some(size) = input.window_resized() {
                        if let Err(err) = pixels.resize_surface(size.width, size.height) {
                            log_error("pixels.resize_surface", err);
                            *control_flow = ControlFlow::Exit;
                            return;
                        }
                    }
        
                    // Update internal state and request a redraw
                    // world.update();
                    window.request_redraw();
                    // println!("time in millisec: {} ", (now_save.elapsed().as_nanos() as f64)/1000000.);
                    // println!(" fps:{}",1./((now_save.elapsed().as_nanos() as f64)/1000000000.));
                    println!("total frames:{frames}");
                    println!("frames per second: {}",(frames as f64)/((now_total.elapsed().as_nanos() as f64)/1000000000.));
                    println!("loops per second: {}",(loops as f64)/((now_total.elapsed().as_nanos() as f64)/1000000000.));
                    print!("{esc}c", esc = 27 as char);

                }
            });
    }
    
    fn log_error<E: std::error::Error + 'static>(method_name: &str, err: E) {
        error!("{method_name}() failed: {err}");
        for source in err.sources().skip(1) {
            error!("  Caused by: {source}");
        }
    }

fn eguiframe(
    _file_path:PathBuf,
    _xtotal:usize,
    _ytotal:usize
) {
}
struct MyApp {
    pro_que:ProQue,
    time:Instant,
    dst_img:ocl::Image<u8>,
    src_img:ocl::Image<u8>,
    raw_img:ImageBuffer<image::Rgba<u8>, Vec<u8>>
}

impl MyApp {
    fn new(
        file_path:PathBuf,
        xtotal:usize,
        ytotal:usize
        ) -> MyApp{
            let mut src:String = Default::default();
            File::open(&file_path).expect("file read not work").read_to_string(&mut src).unwrap();
            // todo!()
                // println!("{}",src);
                let dims = ocl::SpatialDims::Two(xtotal, ytotal);

                    let img_init: ImageBuffer<image::Rgba<u8>, Vec<u8>> = image::ImageBuffer::from_pixel(xtotal as u32, ytotal as u32, image::Rgba([0,0,0,0]));
                    let pro_que = ProQue::builder()
                    .src(src)
                    .dims(dims)
                    .context(
                        ocl::Context::builder()
                        .platform(Platform::default())
                        .devices(ocl::enums::DeviceSpecifier::First)
                        .build()
                        .unwrap())
                    .build().unwrap();
                // let context = ;
            
                    let src_img = ocl::builders::ImageBuilder::<u8>::new()
                    .dims(pro_que.dims())
                    .context(pro_que.context())
                    .copy_host_slice(&img_init)
                    .build()
                    .unwrap();
                
                    let dst_img = ocl::Image::<u8>::builder()
                    .channel_order(ImageChannelOrder::Rgba)
                    .channel_data_type(ImageChannelDataType::UnormInt8)
                    .image_type(ocl::enums::MemObjectType::Image2d)
                    .dims(pro_que.dims())
                    .flags(
                        ocl::flags::MEM_WRITE_ONLY
                            | ocl::flags::MEM_HOST_READ_ONLY
                            | ocl::flags::MEM_COPY_HOST_PTR,
                    )
                    .copy_host_slice(&img_init)
                    .queue(pro_que.queue().clone())
                    .build()
                    .unwrap();

                    let time = Instant::now();
                    
                    MyApp { 
                        pro_que: pro_que, 
                        time: time, 
                        dst_img: dst_img, 
                        src_img: src_img, 
                        raw_img: img_init
                    }
                
        }
        fn render(&mut self){

            let xtotal ;
            let ytotal ;
            match self.pro_que.dims().clone() {
                ocl::SpatialDims::Unspecified => return,
                ocl::SpatialDims::One(_) => return,
                ocl::SpatialDims::Two(xtot,ytot) => (xtotal,ytotal) = (xtot,ytot),
                ocl::SpatialDims::Three(_, _,_) => return,
            }

            // let mut temp_img = image::ImageBuffer::from_pixel(xtotal as u32, ytotal as u32, image::Rgba([0,0,0,0]));
            let kernel = self.pro_que.kernel_builder("add")
                .arg_sampler(&ocl::Sampler::with_defaults(self.pro_que.context()).unwrap())
                .arg(&self.src_img)
                .arg(&self.dst_img)
                .arg(0)
                .arg(0)
                .arg(xtotal as i32) 
                .arg(ytotal as i32)    
                .arg((self.time.elapsed().as_nanos() as f32)/1000000000.)             
                .build().unwrap();

            unsafe { kernel.enq().unwrap(); }

            self.dst_img.read(&mut self.raw_img).enq().unwrap();
            // temp_img.save(&Path::new("oclt_computed.png")).unwrap();
            // print!("f");
        }
        /// Update the `World` internal state; bounce the box around the screen.
        // fn update(&mut self) {
        // }
        
        /// Draw the `World` state to the frame buffer.
        ///
        /// Assumes the default texture format: `wgpu::TextureFormat::Rgba8UnormSrgb`
        fn draw(&mut self, pixels: &mut [u8]) {
            // self.render();
            pixels
            .swap_with_slice(&mut (*self.raw_img.clone()))
            
        }
}

    
fn render_image(
    file_path:PathBuf,
    width:usize,
    height:usize,
    xtotal:usize,
    ytotal:usize
) -> ocl::Result<()> {

    if width==0||height==0||xtotal==0||ytotal==0 {return Err("invalid input".into());}
    
    let mut src:String = Default::default();
    File::open(file_path.clone()).expect("file read not work").read_to_string(&mut src).unwrap();

    let now_cpu = Instant::now();
    let xgroups:usize = (xtotal as f32/width as f32).ceil() as usize;
    let ygroups:usize = (ytotal as f32/height as f32).ceil() as usize;

    let dims = ocl::SpatialDims::Two(width, height);

    let pro_que = ProQue::builder()
        .src(src)
        .dims(dims)
        .build()?;

        let mut imageout = image::ImageBuffer::from_pixel(width as u32, height as u32, image::Rgba([0,0,0,0]));
        let src_img: ocl::Image<u8> = ocl::builders::ImageBuilder::<u8>::new()
        .dims(pro_que.dims())
        .context(pro_que.context())
        .copy_host_slice(&imageout)
        .build()?;

        
        let dst_img = ocl::Image::<u8>::builder()
        .channel_order(ImageChannelOrder::Rgba)
        .channel_data_type(ImageChannelDataType::UnormInt8)
        .image_type(ocl::enums::MemObjectType::Image2d)
        .dims(pro_que.dims())
        .flags(
            ocl::flags::MEM_WRITE_ONLY
                | ocl::flags::MEM_HOST_READ_ONLY
                | ocl::flags::MEM_COPY_HOST_PTR,
        )
        .copy_host_slice(&imageout)
        .queue(pro_que.queue().clone())
        .build()
        .unwrap();

        let now_vec_buffer_create = Instant::now();
        let mut imagearray: Vec<Vec<ImageBuffer<image::Rgba<u8>, Vec<u8>>>> = vec![vec![image::ImageBuffer::from_pixel((width) as u32, (height) as u32, image::Rgba([0,0,0,0_u8]));ygroups];xgroups];
        let _end_vec_buffer_create = now_vec_buffer_create.elapsed().as_nanos(); 

        let mut sum_load: u128 = 0;
        let mut sum_compute: u128 = 0;
        let mut sum_read: u128 = 0;
        let mut sum_save: u128 = 0;
        let now_gpu = Instant::now();
    for xgroup in 0..xgroups{
    for ygroup in 0..ygroups{
        
        let now_load = Instant::now();
        
            let kernel = pro_que.kernel_builder("add")
                .arg_sampler(&ocl::Sampler::with_defaults(pro_que.context())?)
                .arg(&src_img)
                .arg(&dst_img)
                .arg(xgroup as i32)
                .arg(ygroup as i32)
                .arg(width as i32) 
                .arg(height as i32)                 
                .arg(1. as f32)             

                .build()?;
        sum_load += now_load.elapsed().as_nanos();
        let now_compute = Instant::now();

            unsafe { kernel.enq().unwrap(); }

        sum_compute += now_compute.elapsed().as_nanos();
        let now_read_frag = Instant::now();

            dst_img.read(&mut imageout).enq().unwrap();

        sum_read += now_read_frag.elapsed().as_nanos();
        let now_save_frag = Instant::now();

            if 1==0
            {
                // imageout.save(&Path::new(&format!("{}x{}.png",xgroup,ygroup))).unwrap();
            }else{
                imagearray[xgroup][ygroup] = imageout.clone();
            }

        sum_save += now_save_frag.elapsed().as_nanos();
        print!(".")
    }println!("");}
    println!("");

    let end_gpu = now_gpu.elapsed().as_nanos();
    println!("total time for gpu processing:{} millisec", (end_gpu as f64)/1000000.);
    println!("total time to load fragments:{} millisec", (sum_load as f64)/1000000.);
    println!("total time to compute fragments:{} millisec", (sum_compute as f64)/1000000.);
    println!("total time to read fragment:{} millisec", (sum_read as f64)/1000000.);
    println!("total time to save fragments:{} millisec", (sum_save as f64)/1000000.);

    let now_buffer_create = Instant::now();
    let mut imagecomb: ImageBuffer<image::Rgba<u8>, Vec<u8>> = image::ImageBuffer::from_pixel((xtotal) as u32, (ytotal) as u32, image::Rgba([0,0,0,0_u8]));
    let end_buffer_create = now_buffer_create.elapsed().as_nanos(); 
    
    let now_image_combine = Instant::now();
    for xgroup in 0..xgroups{
        for ygroup in 0..ygroups{
            /* let mut on_top = ImageBuffer::new(width as u32, height as u32);
            if 1==0
            {
                // on_top = open(&format!("{}x{}.png",xgroup,ygroup)).unwrap().into_rgba8();
            }else{
                on_top = imagearray[xgroup][ygroup].clone();
            } */

            image::imageops::overlay(&mut imagecomb, &imagearray[xgroup][ygroup].clone(), (xgroup*width) as i64, (ygroup*height) as i64);
            // fs::remove_file(&format!("{}x{}.png",xgroup,ygroup))?;
    }}
    let end_image_combine = now_image_combine.elapsed().as_nanos(); 

    let thread_image_save = thread::spawn(move || {
        let now_save = Instant::now();
        imagecomb.save(&Path::new("oclt_computed.png")).unwrap();
        let end_save = now_save.elapsed().as_nanos(); 
        println!("time to save final:{} millisec", (end_save as f64)/1000000.);

    });

    let _thread_temp_files_clean: thread::JoinHandle<()>;
    if 1==0
    {
        let thread_temp_files_clean = thread::spawn(move || {
            let now_clean = Instant::now();
            for xgroup in 0..xgroups{
                for ygroup in 0..ygroups{
                    fs::remove_file(&format!("{}x{}.png",xgroup,ygroup)).unwrap();
            }}
            let end_clean = now_clean.elapsed().as_nanos();  
            println!("time to clean files:{} millisec", (end_clean as f64)/1000000.);

        });
    let _ = thread_temp_files_clean.join();

    }

    let _ = thread_image_save.join();
    let end_cpu = now_cpu.elapsed().as_nanos();
    println!("time to create final buffer:{} millisec", (end_buffer_create as f64)/1000000.);
    println!("time to combine images:{} millisec", (end_image_combine as f64)/1000000.);
    println!("time to cpu:{} millisec", (end_cpu as f64)/1000000.);

    println!( "Images saved as: '{}'.","oclt_computed.png");
    Ok(())
}

fn render_video(
    file_path:PathBuf,
    xtotal:usize,
    ytotal:usize
) -> ocl::Result<()> {
    // let surface = ImageSurface::create(Format::ARgb32, 600, 600)
    //     .expect("Couldn’t create surface");
    // let context = Context::new(&surface).unwrap();
    // if (xtotal==0||ytotal==0||xtotal>16384||ytotal>16384){return Err("invalid input".into());}
    
    let mut src:String = Default::default();
    File::open(file_path.clone()).expect("file read not work").read_to_string(&mut src).unwrap();

    let now_cpu = Instant::now();

    let dims = ocl::SpatialDims::Two(xtotal, ytotal);

    let pro_que = ProQue::builder()
        .src(src)
        .dims(dims)
        .build()?;

        let mut imageout: ImageBuffer<image::Rgba<u8>, Vec<u8>> = image::ImageBuffer::from_pixel(xtotal as u32, ytotal as u32, image::Rgba([0,0,0,0]));
        let src_img = ocl::builders::ImageBuilder::<u8>::new()
        .dims(pro_que.dims())
        .context(pro_que.context())
        .copy_host_slice(&imageout)
        .build()
        .unwrap();
    
        let dst_img = ocl::Image::<u8>::builder()
        .channel_order(ImageChannelOrder::Rgba)
        .channel_data_type(ImageChannelDataType::UnormInt8)
        .image_type(ocl::enums::MemObjectType::Image2d)
        .dims(pro_que.dims())
        .flags(
            ocl::flags::MEM_WRITE_ONLY
                | ocl::flags::MEM_HOST_READ_ONLY
                | ocl::flags::MEM_COPY_HOST_PTR,
        )
        .copy_host_slice(&imageout)
        .queue(pro_que.queue().clone())
        .build()
        .unwrap();

        let mut sum_load: u128 = 0;
        let mut sum_compute: u128 = 0;
        let mut sum_read: u128 = 0;
        let _sum_save: u128 = 0;
        let mut frames = 0.;
        let now_gpu = Instant::now();
        
        for _ in 0..10{
            frames += 1.;
            let now_load = Instant::now();
            let kernel = pro_que.kernel_builder("add")
                .arg_sampler(&ocl::Sampler::with_defaults(pro_que.context())?)
                .arg(&src_img)
                .arg(&dst_img)
                .arg(1)
                .arg(1)
                .arg(xtotal as i32) 
                .arg(ytotal as i32)    
                .arg((now_cpu.elapsed().as_nanos() as f32)/1000000.)             
                .build()?;
        sum_load += now_load.elapsed().as_nanos();
        let now_compute = Instant::now();

            unsafe { kernel.enq().unwrap(); }

        sum_compute += now_compute.elapsed().as_nanos();
        let now_read_frag = Instant::now();

        dst_img.read(&mut imageout).enq().unwrap();

        sum_read += now_read_frag.elapsed().as_nanos();
}
    println!("");

    let end_gpu = now_gpu.elapsed().as_nanos();
    println!("total frames:{frames}");
    println!("total time for gpu processing:{} millisec", (end_gpu as f64)/1000000.);
    println!("fps:{}",frames/((end_gpu as f64)/1000000000.));
    println!("spf:{}",(end_gpu as f64)/1000000000./frames);
    println!("frame time for gpu processing:{} millisec", (end_gpu as f64)/1000000./frames);
    println!("frame time to load fragments:{} millisec", (sum_load as f64)/1000000./frames);
    println!("frame time to compute fragments:{} millisec", (sum_compute as f64)/1000000./frames);
    println!("frame time to read fragments:{} millisec", (sum_read as f64)/1000000./frames);

   
    let now_save = Instant::now();
    imageout.save(&Path::new("oclt_computed.png")).unwrap();
    let end_save = now_save.elapsed().as_nanos(); 
    println!("time to save final:{} millisec", (end_save as f64)/1000000.);

    let end_cpu = now_cpu.elapsed().as_nanos();
    println!("time to cpu:{} millisec", (end_cpu as f64)/1000000.);
    println!( "Images saved as: '{}'.","oclt_computed.png");
    Ok(())
}

fn img_formats() -> ocl::Result<()> {
    for (p_idx, platform) in ocl::Platform::list().into_iter().enumerate() {
        for (d_idx, device) in ocl::Device::list_all(&platform)?.into_iter().enumerate() {
            printlnc!(blue: "Platform [{}]: {}", p_idx, platform.name()?);
            printlnc!(teal: "Device [{}]: {} {}", d_idx, device.vendor()?, device.name()?);

            let context = ocl::Context::builder()
            .platform(platform)
            .devices(device)
            .build()?;
            
        let sup_img_formats = ocl::Image::<u8>::supported_formats(
            &context,
            ocl::flags::MEM_READ_WRITE,
            ocl::enums::MemObjectType::Image2d,
        )?;
        println!("Image Formats: {:#?}.", sup_img_formats);
    }
}
Ok(())
}

fn myapprender(
    file_path:PathBuf,
    xtotal:usize,
    ytotal:usize
) {
    let mut src:String = Default::default();
    File::open(file_path.clone()).expect("file read not work").read_to_string(&mut src).unwrap();

    let _now_cpu = Instant::now();

    let dims = ocl::SpatialDims::Two(xtotal, ytotal);

    let pro_que = ProQue::builder()
        .src(src)
        .dims(dims)
        .build()
        .unwrap();

        let imageout: ImageBuffer<image::Rgba<u8>, Vec<u8>> = image::ImageBuffer::from_pixel(xtotal as u32, ytotal as u32, image::Rgba([0,0,0,0]));
        let _src_img = ocl::builders::ImageBuilder::<u8>::new()
        .dims(pro_que.dims())
        .context(pro_que.context())
        .copy_host_slice(&imageout)
        .build()
        .unwrap();
    
        let _dst_img = ocl::Image::<u8>::builder()
        .channel_order(ImageChannelOrder::Rgba)
        .channel_data_type(ImageChannelDataType::UnormInt8)
        .image_type(ocl::enums::MemObjectType::Image2d)
        .dims(pro_que.dims())
        .flags(
            ocl::flags::MEM_WRITE_ONLY
                | ocl::flags::MEM_HOST_READ_ONLY
                | ocl::flags::MEM_COPY_HOST_PTR,
        )
        .copy_host_slice(&imageout)
        .queue(pro_que.queue().clone())
        .build()
        .unwrap();
        let mut MyApp_renderer = 
        MyApp::new(file_path, xtotal, ytotal);
    MyApp_renderer.render();

    
}


#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// width of "chunk" size for images
    #[arg(short='W', long="width", default_value_t = 1920)]
    width:usize,
    /// height of "chunk" size for images
    #[arg(short='H', long="height", default_value_t = 1080)]
    height:usize,
    /// total pixels in image in the x direction
    #[arg(short='X', long="xtotal", default_value_t = 600)]
    xtotal:usize,
    /// total pixels in image in the y direction
    #[arg(short='Y', long="ytotal", default_value_t = 400)]
    ytotal:usize,
    #[arg(short='k', long = "kernel_file_path", default_value = "img_add_kernel.cl")]
    file_path: PathBuf,
    #[command(subcommand)]
    cmd: Commands
}

#[derive(Subcommand, Debug, Clone)]
enum Commands {
    ImgFormats,
    ImgRender,
    VidRender,
    Eframe,
    MyApp,
    Pixels

}

pub fn main() {
    let args = Args::parse();
    match args.cmd {
        Commands::ImgFormats => img_formats().expect("msg"),
        Commands::ImgRender => render_image(args.file_path,args.width,args.height,args.xtotal,args.ytotal).expect("msg"),
        Commands::VidRender => render_video(args.file_path,args.xtotal,args.ytotal).expect("msg"),
        Commands::Eframe => eguiframe(args.file_path,args.xtotal,args.ytotal),
        Commands::MyApp => myapprender(args.file_path,args.xtotal,args.ytotal),
        Commands::Pixels => pixels_ez_renderer(args.file_path, args.xtotal, args.ytotal).expect("msg"),
        _ => return,
    }
    
    // img_formats().unwrap();
}        