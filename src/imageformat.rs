use std;

pub(crate) fn img_formats() -> ocl::Result<()> {
    for (p_idx, platform) in ocl::Platform::list().into_iter().enumerate() {
        for (d_idx, device) in ocl::Device::list_all(&platform)?.into_iter().enumerate() {
            println!("Platform [{}]: {}", p_idx, platform.name()?);
            println!("Device [{}]: {} {}", d_idx, device.vendor()?, device.name()?);

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