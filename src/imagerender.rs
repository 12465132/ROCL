extern crate std;
use std::{fs::File, io::Read};

pub(crate) fn render_image(
    file_path:std::path::PathBuf,
    width:usize,
    height:usize,
    xtotal:usize,
    ytotal:usize
) -> ocl::Result<()> {

    if width==0||height==0||xtotal==0||ytotal==0 {return Err("invalid input".into());}
    
    let mut src:String = Default::default();
    std::fs::File::open(file_path.clone()).expect("file read not work").read_to_string(&mut src).unwrap();

    let now_cpu = std::time::Instant::now();
    let xgroups:usize = (xtotal as f32/width as f32).ceil() as usize;
    let ygroups:usize = (ytotal as f32/height as f32).ceil() as usize;

    let dims = ocl::SpatialDims::Two(width, height);

    let pro_que = ocl::ProQue::builder()
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

        let now_vec_buffer_create = std::time::Instant::now();
        let mut imagearray: Vec<Vec<image::ImageBuffer<image::Rgba<u8>, Vec<u8>>>> = vec![vec![image::ImageBuffer::from_pixel((width) as u32, (height) as u32, image::Rgba([0,0,0,0_u8]));ygroups];xgroups];
        let _end_vec_buffer_create = now_vec_buffer_create.elapsed().as_nanos(); 

        let mut sum_load: u128 = 0;
        let mut sum_compute: u128 = 0;
        let mut sum_read: u128 = 0;
        let mut sum_save: u128 = 0;
        let now_gpu = std::time::Instant::now();
    for xgroup in 0..xgroups{
    for ygroup in 0..ygroups{
        
        let now_load = std::time::Instant::now();
        
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
        let now_compute = std::time::Instant::now();

            unsafe { kernel.enq().unwrap(); }

        sum_compute += now_compute.elapsed().as_nanos();
        let now_read_frag = std::time::Instant::now();

        dst_img.read(&mut imageout).enq().unwrap();

        sum_read += now_read_frag.elapsed().as_nanos();
        let now_save_frag = std::time::Instant::now();

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

    let now_buffer_create = std::time::Instant::now();
    let mut imagecomb: image::ImageBuffer<image::Rgba<u8>, Vec<u8>> = image::ImageBuffer::from_pixel((xtotal) as u32, (ytotal) as u32, image::Rgba([0,0,0,0_u8]));
    let end_buffer_create = now_buffer_create.elapsed().as_nanos(); 
    
    let now_image_combine = std::time::Instant::now();
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

    let thread_image_save = std::thread::spawn(move || {
        let now_save = std::time::Instant::now();
        imagecomb.save(&std::path::Path::new("oclt_computed.png")).unwrap();
        let end_save = now_save.elapsed().as_nanos(); 
        println!("time to save final:{} millisec", (end_save as f64)/1000000.);

    });

    let _thread_temp_files_clean: std::thread::JoinHandle<()>;
    if 1==0
    {
        let thread_temp_files_clean = std::thread::spawn(move || {
            let now_clean = std::time::Instant::now();
            for xgroup in 0..xgroups{
                for ygroup in 0..ygroups{
                    std::fs::remove_file(&format!("{}x{}.png",xgroup,ygroup)).unwrap();
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
