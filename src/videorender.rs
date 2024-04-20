extern crate std;
use std::{fs::File, io::Read};

pub(crate) fn render_video(
    file_path:std::path::PathBuf,
    xtotal:usize,
    ytotal:usize
) -> ocl::Result<()> {
    // let surface = ImageSurface::create(Format::ARgb32, 600, 600)
    //     .expect("Couldn’t create surface");
    // let context = Context::new(&surface).unwrap();
    // if (xtotal==0||ytotal==0||xtotal>16384||ytotal>16384){return Err("invalid input".into());}
    
    let mut src:String = Default::default();
    File::open(file_path.clone()).expect("file read not work").read_to_string(&mut src).unwrap();

    let now_cpu = std::time::Instant::now();

    let dims = ocl::SpatialDims::Two(xtotal, ytotal);

    let pro_que = ocl::ProQue::builder()
        .src(src)
        .dims(dims)
        .build()?;

        let mut imageout: image::ImageBuffer<image::Rgba<u8>, Vec<u8>> = image::ImageBuffer::from_pixel(xtotal as u32, ytotal as u32, image::Rgba([0,0,0,0]));
        let src_img = ocl::builders::ImageBuilder::<u8>::new()
        .dims(pro_que.dims())
        .context(pro_que.context())
        .copy_host_slice(&imageout)
        .build()
        .unwrap();
    
        let dst_img = ocl::Image::<u8>::builder()
        .channel_order(ocl::core::ImageChannelOrder::Rgba)
        .channel_data_type(ocl::core::ImageChannelDataType::UnormInt8)
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
        let now_gpu = std::time::Instant::now();
        
        for _ in 0..10{
            frames += 1.;
            let now_load = std::time::Instant::now();
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
        let now_compute = std::time::Instant::now();

            unsafe { kernel.enq().unwrap(); }

        sum_compute += now_compute.elapsed().as_nanos();
        let now_read_frag = std::time::Instant::now();

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

   
    let now_save = std::time::Instant::now();
    imageout.save(&std::path::Path::new("oclt_computed.png")).unwrap();
    let end_save = now_save.elapsed().as_nanos(); 
    println!("time to save final:{} millisec", (end_save as f64)/1000000.);

    let end_cpu = now_cpu.elapsed().as_nanos();
    println!("time to cpu:{} millisec", (end_cpu as f64)/1000000.);
    println!( "Images saved as: '{}'.","oclt_computed.png");
    Ok(())
}