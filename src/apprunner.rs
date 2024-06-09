extern crate ocl;
extern crate image;
extern crate pixels;
extern crate winit;
extern crate winit_input_helper;
extern crate env_logger;



use crate::myapp;

pub(crate) fn pixels_ez_renderer(file_path:std::path::PathBuf,
    image:String,
    xtotal:usize,
    ytotal:usize
) -> Result<(), pixels::Error> {
    let _ = image;
    env_logger::init();
    let event_loop = winit::event_loop::EventLoop::new().unwrap();
    let mut input = winit_input_helper::WinitInputHelper::new();
    let window = {
        let sizeh2 = winit::dpi::LogicalSize::new(0.5*xtotal as f64, 0.5*ytotal as f64);
        winit::window::WindowBuilder::new()
            .with_title("Hello Pixels")
            .with_min_inner_size(sizeh2)
            .with_max_inner_size(sizeh2)
            .with_transparent(false)
            .with_position(winit::dpi::PhysicalPosition::new(0,0))
            // .with_active(false)
            // .with_fullscreen(Some(winit::window::Fullscreen::Borderless(None)))
            .build(&event_loop)
            .unwrap()
    };
    // let window = winit::window::Window::new(&event_loop).unwrap();

    
    // window.set_cursor_visible(false);
        let mut pixels = {
            let window_size = window.inner_size();
            let surface_texture = ::pixels::SurfaceTexture::new(window_size.width, window_size.height, &window);
            pixels::PixelsBuilder::new(xtotal as u32, ytotal as u32, surface_texture)
            .clear_color(pixels::wgpu::Color::BLACK)
            .build()
            .unwrap()
        };
        for pixel in pixels.frame_mut().chunks_exact_mut(4) {
            pixel[0] = 255;; // R
            pixel[1] = 255;; // G
            pixel[2] = 255;; // B
            pixel[3] = 255;; // A
        }
        let _white_l = 
            myapp::L{
                color:[0.755,0.748,0.751],
                isLight:false,
                refraction:false,
                isObjectBoundry:false,
                n:1.,
                roughness:1.0,
                objectid:1.,
                RorTp:1.,
            };
        let green_l = 
            myapp::L{
                color:[0.061,0.426,0.061],
                isLight:false,
                refraction:false,
                isObjectBoundry:false,
                n:1.,
                roughness:1.0,
                objectid:2.,
                RorTp:1.,
            };
        let red_l = 
            myapp::L{
                color:[0.443,0.061,0.062],
                isLight:false,
                refraction:false,
                isObjectBoundry:false,
                n:1.,
                roughness:1.0,
                objectid:3.,
                RorTp:1.,
            };
        let light_l = 
            myapp::L { 
                color: [17.,15.,13.], 
                isLight: true, 
                isObjectBoundry:false,
                refraction: false, 
                n: 1., 
                roughness: 1.0, 
                objectid: 4., 
                RorTp: 1. 
            };
        let s_cube_l = 
            myapp::L { 
                color: [0.755,0.748,0.751],         
                isLight: false, 
                refraction: true, 
                isObjectBoundry:false,
                n: 2.5, 
                roughness: 0.1, 
                objectid: 5., 
                RorTp: 0.1
            };
        let t_cube_l = 
            myapp::L { 
                color:  [0.755,0.748,0.751],         
                isLight: false, 
                refraction: true, 
                isObjectBoundry:true,
                n: 1.0, 
                roughness: 0.0, 
                objectid: 6., 
                RorTp: 0.0 
            };
        let wall_l = 
            myapp::L{
                color:[0.755,0.748,0.751],
                isLight:false,
                refraction:false,
                isObjectBoundry:false,
                n:2.5,
                roughness:1.0,
                objectid:7.,
                RorTp:1.,
            };
            let blue_l = 
            myapp::L{
                color:[0.061,0.061,0.426],
                isLight:false,
                refraction:false,
                isObjectBoundry:false,
                n:1.,
                roughness:1.0,
                objectid:8.,
                RorTp:1.,
            };
        let triangles = 
        vec![
        myapp::triangle{
            p1:[5.528,0.000,0.000],
            p2:[0.000,0.000,0.000],    
            p3:[0.000,5.592,0.000],  
            R:0.01,  
            L:wall_l,
        },//floor
        myapp::triangle{
            p1:[5.528,0.000,0.000],
            p2:[0.000,5.592,0.000],    
            p3:[5.496,5.592,0.000],  
            R:0.01,  
            L:wall_l,
        },//floor
        myapp::triangle{
            p1:[3.430,2.270,5.480],
            p2:[3.430,3.320,5.480],    
            p3:[2.130,3.320,5.480],  
            R:0.01,  
            L:light_l,
        },//light
        myapp::triangle{
            p1:[3.430,2.270,5.480],
            p2:[2.130,3.320,5.480],    
            p3:[2.130,2.270,5.480],  
            R:0.01,  
            L:light_l,
        },//light
        myapp::triangle{
            p1:[5.560,0.000,5.488],
            p2:[5.560,5.592,5.488],    
            p3:[0.000,5.592,5.488],  
            R:0.01,  
            L:wall_l,
        },//celing
        myapp::triangle{
            p1:[5.560,0.000,5.488],
            p2:[0.000,5.592,5.488],    
            p3:[0.000,0.000,5.488],  
            R:0.01,  
            L:wall_l,
        },//celing
        myapp::triangle{
            p1:[5.496,5.592,0.000],
            p2:[0.000,5.592,0.000],    
            p3:[0.000,5.592,5.488],  
            R:0.01,  
            L:wall_l,
        },//back wall
        myapp::triangle{
            p1:[5.496,5.592,0.000],
            p2:[0.000,5.592,5.488],    
            p3:[5.560,5.592,5.488],  
            R:0.01,  
            L:wall_l,
        },//back wall
        myapp::triangle{
            p1:[0.000,5.592,0.000],
            p2:[0.000,0.000,0.000],    
            p3:[0.000,0.000,5.488],  
            R:0.01,  
            L:green_l,
        },//green wall
        myapp::triangle{
            p1:[0.000,5.592,0.000],
            p2:[0.000,0.000,5.488],    
            p3:[0.000,5.592,5.488],  
            R:0.01,  
            L:green_l,
        },//green wall
        myapp::triangle{
            p1:[5.528,0.000,0.000],
            p2:[5.496,5.592,0.000],    
            p3:[5.560,5.592,5.488],  
            R:0.01,  
            L:red_l,
        },// red wall
        myapp::triangle{
            p1:[5.528,0.000,0.000],
            p2:[5.560,5.592,5.488],    
            p3:[5.560,0.000,5.488],  
            R:0.01,  
            L:red_l,
        },// red wall
        myapp::triangle{
            p1:[1.300,0.650,1.650],
            p2:[0.820,2.250,1.650],    
            p3:[2.400,2.720,1.650],  
            R:0.01,  
            L:s_cube_l,
        },//short block
        myapp::triangle{
            p1:[1.300,0.650,1.650],
            p2:[2.400,2.720,1.650],    
            p3:[2.900,1.140,1.650],   
            R:0.01,  
            L:s_cube_l,
        },//short block
        myapp::triangle{
            p1:[2.900,1.140,0.000],
            p2:[2.900,1.140,1.650],    
            p3:[2.400,2.720,1.650],  
            R:0.01,  
            L:s_cube_l,
        },//short block
        myapp::triangle{
            p1:[2.900,1.140,0.000],
            p2:[2.400,2.720,1.650],    
            p3:[2.400,2.720,0.000],   
            R:0.01,  
            L:s_cube_l,
        },//short block
        myapp::triangle{
            p1:[1.300,0.650,0.000],
            p2:[1.300,0.650,1.650],    
            p3:[2.900,1.140,1.650],  
            R:0.01,  
            L:s_cube_l,
        },//short block
        myapp::triangle{
            p1:[1.300,0.650,0.000],
            p2:[2.900,1.140,1.650],    
            p3:[2.900,1.140,0.000],   
            R:0.01,  
            L:s_cube_l,
        },//short block
        myapp::triangle{
            p1:[0.820,2.250,0.000],
            p2:[0.820,2.250,1.650],    
            p3:[1.300,0.650,1.650],  
            R:0.01,  
            L:s_cube_l,
        },//short block
        myapp::triangle{
            p1:[0.820,2.250,0.000],
            p2:[1.300,0.650,1.650],    
            p3:[1.300,0.650,0.000],   
            R:0.01,  
            L:s_cube_l,
        },//short block
        myapp::triangle{
            p1:[2.400,2.720,0.000],
            p2:[2.400,2.720,1.650],    
            p3:[0.820,2.250,1.650],  
            R:0.01,  
            L:s_cube_l,
        },//short block
        myapp::triangle{
            p1:[2.400,2.720,0.000],
            p2:[0.820,2.250,1.650],    
            p3:[0.820,2.250,0.000],  
            R:0.01,  
            L:s_cube_l,
        },//short block
        myapp::triangle{
            p1:[4.230,2.470,3.300],
            p2:[2.650,2.960,3.300],    
            p3:[3.140,4.560,3.300],  
            R:0.01,  
            L:t_cube_l,
        },//tall block
        myapp::triangle{
            p1:[4.230,2.470,3.300],
            p2:[3.140,4.560,3.300],    
            p3:[4.720,4.060,3.300],   
            R:0.01,  
            L:t_cube_l,
        },//tall block
        myapp::triangle{
            p1:[4.230,2.470,0.000],
            p2:[4.230,2.470,3.300],    
            p3:[4.720,4.060,3.300],  
            R:0.01,  
            L:t_cube_l,
        },//tall block
        myapp::triangle{
            p1:[4.230,2.470,0.000],
            p2:[4.720,4.060,3.300],    
            p3:[4.720,4.060,0.000],   
            R:0.01,  
            L:t_cube_l,
        },//tall block
        myapp::triangle{
            p1:[4.720,4.060,0.000],
            p2:[4.720,4.060,3.300],    
            p3:[3.140,4.560,3.300],  
            R:0.01,  
            L:t_cube_l,
        },//tall block
        myapp::triangle{
            p1:[4.720,4.060,0.000],
            p2:[3.140,4.560,3.300],    
            p3:[3.140,4.560,0.000],   
            R:0.01,  
            L:t_cube_l,
        },//tall block
        myapp::triangle{
            p1:[3.140,4.560,0.000],
            p2:[3.140,4.560,3.300],    
            p3:[2.650,2.960,3.300],  
            R:0.01,  
            L:t_cube_l,
        },//tall block
        myapp::triangle{
            p1:[3.140,4.560,0.000],
            p2:[2.650,2.960,3.300],    
            p3:[2.650,2.960,0.000],   
            R:0.01,  
            L:t_cube_l,
        },//tall block
        myapp::triangle{
            p1:[2.650,2.960,0.000],
            p2:[2.650,2.960,3.300],    
            p3:[4.230,2.470,3.300],  
            R:0.01,  
            L:t_cube_l,
        },//tall block
        myapp::triangle{
            p1:[2.650,2.960,0.000],
            p2:[4.230,2.470,3.300],    
            p3:[4.230,2.470,0.000],   
            R:0.01,  
            L:t_cube_l,
        },//tall block
        ];
        let mut frames = 0;
        let mut loops = 0;
        let barrier = std::sync::Arc::new(std::sync::Barrier::new(2));
        let world = std::sync::Arc::new(std::sync::Mutex::new(myapp::MyApp::new(pixels,xtotal,ytotal,8,triangles.len())));
        let c2 = std::sync::Arc::clone(&barrier);
        
        world.lock().unwrap().loadtriangles(triangles.clone());
        let _render_thread = {
            let c1 = std::sync::Arc::clone(&barrier);
            let worldt = std::sync::Arc::clone(&world);
            std::thread::spawn(move || {
                // let imaget = image.clone();
                // worldt.lock().expect("failed lock").src_img1.write(&image::io::Reader::open("default.jpg".to_string()).unwrap().decode().unwrap().to_rgb32f()).enq().unwrap();
                // worldt.lock().expect("failed lock").src_img2.write(&image::io::Reader::open("default.jpg".to_string()).unwrap().decode().unwrap().to_rgb32f()).enq().unwrap();
                // worldt.lock().unwrap().src_img1.write(&image::io::Reader::open(image.clone()).unwrap().decode().unwrap().to_rgba8()).enq().unwrap();

            loop {
                // c1.wait();
            {
                let mut worldlocked = worldt.lock().expect("failed lock");                    
                worldlocked
                .loadtriangles(triangles.clone())
                .render("render".to_string())
                .updateframe()
                // .checkstop(66, "pathTracingProgress/Cornell40.PNG".to_string())
                ;
                // worldlocked.dst_img1.cmd().copy(&worldlocked.dst_img1, [0, 0, 0]).enq().unwrap();
                // worldlocked.framebuffer.cmd().copy(&worldlocked.src_img1, [0, 0, 0]).enq().unwrap();
                // worldlocked.framebuffer.cmd().copy(&worldlocked.src_img2, [0, 0, 0]).enq().unwrap();
                // if(worldlocked.frameintg>=256){
                //     worldlocked.save("ROCL2.PNG".to_string());
                //     todo!();
                // }
            }
                c1.wait();
                // worldlocked
            }
            })
        };
        let now_total = std::time::Instant::now();
        // let mut time_rendered = now_total.elapsed();
        // let event_loop_proxy = event_loop.create_proxy();
        let _ = event_loop.run(move |event, control_flow| {
            loops +=1;
            // Draw the current frame
            if let winit::event::Event::WindowEvent { window_id:_, event:winit::event::WindowEvent::RedrawRequested } = event {
                // window.pre_present_notify();
                frames+=1;
                c2.wait();
                {
                if let Err(err) = world.lock().expect("failed lock").pixels.render() {
                    println!("{err}");
                    control_flow.exit();
                    return;
                }
                }
                // c2.wait();

            }
            // if let Event::UserEvent(val) = event {
            //     // let mut a = pixels.frame_mut();
            //     //  = world.draw().as_mut_slice();
            //     c2.wait();
            //     world.lock().unwrap().draw(pixels.frame_mut());
            //     frames+=1;
            //     if let Err(err) = pixels.render() {
            //         log_error("pixels.render", err);
            //         *control_flow = ControlFlow::Exit;
            //         return;
            //     }
            //     // c2.wait();
            // }
    
            // Handle input events
            if input.update(&event) {
                // Close events
                if  input.key_pressed(winit::keyboard::KeyCode::Escape) ||
                (input.key_held(winit::keyboard::KeyCode::ControlLeft) &&
                 input.key_pressed(winit::keyboard::KeyCode::KeyC) )|| 
                input.close_requested() {
                    control_flow.exit();
                    return;
                }
                let mut worldlocked = world.lock().expect("failed lock");                    
                if (input.key_held(winit::keyboard::KeyCode::ControlLeft) &&
                    input.key_pressed(winit::keyboard::KeyCode::KeyX) ){
                        world.lock().expect("failed lock").save(image.clone());
                }
                
                if (input.key_pressed(winit::keyboard::KeyCode::KeyW)){
                    worldlocked.updatecam([0.0,0.1,0.0], [0.0,0.0]).reset();
                }
                if (input.key_pressed(winit::keyboard::KeyCode::KeyS)){
                    worldlocked.updatecam([0.0,-0.1,0.0], [0.0,0.0]).reset();
                }
                if (input.key_pressed(winit::keyboard::KeyCode::KeyA)){
                    worldlocked.updatecam([-0.1,0.0,0.0], [0.0,0.0]).reset();
                }
                if (input.key_pressed(winit::keyboard::KeyCode::KeyD)){
                    worldlocked.updatecam([0.1,0.0,0.0], [0.0,0.0]).reset();
                }
                if (input.key_pressed(winit::keyboard::KeyCode::KeyR)){
                    worldlocked.updatecam([0.0,0.0,0.1], [0.0,0.0]).reset();
                }
                if (input.key_pressed(winit::keyboard::KeyCode::KeyF)){
                    worldlocked.updatecam([0.0,0.0,-0.1], [0.0,0.0]).reset();
                }

                if (input.key_pressed(winit::keyboard::KeyCode::ArrowLeft)){
                    worldlocked.updatecam([0.0,0.0,0.0], [-0.1, 0.0]).reset();
                }
                if (input.key_pressed(winit::keyboard::KeyCode::ArrowDown)){
                    worldlocked.updatecam([0.0,0.0,0.0], [ 0.0,-0.1]).reset();
                }
                if (input.key_pressed(winit::keyboard::KeyCode::ArrowRight)){
                    worldlocked.updatecam([0.0,0.0,0.0], [ 0.1, 0.0]).reset();
                }
                if (input.key_pressed(winit::keyboard::KeyCode::ArrowUp)){
                    worldlocked.updatecam([0.0,0.0,0.0], [ 0.0, 0.1]).reset();
                }

                // Resize the window
                if let Some(size) = input.window_resized() {
                    worldlocked.pixels.resize_surface(size.width, size.height).unwrap();
                }


                // Update internal state and request a redraw
                // world.update();

                // println!("time in millisec: {} ", (now_save.elapsed().as_nanos() as f64)/1000000.);
                // println!(" fps:{}",1./((now_save.elapsed().as_nanos() as f64)/1000000000.));

            }
            // {
            //     if let Ok(_) = world.try_lock()
            //     {

            //     }
            // }
            window.request_redraw();
            window.pre_present_notify();
            println!("total frames:{frames}");
            println!("frames per second: {}",(frames as f64)/((now_total.elapsed().as_nanos() as f64)/1000000000.));
            println!("loops per second: {}",(loops as f64)/((now_total.elapsed().as_nanos() as f64)/1000000000.));
            print!("{esc}c", esc = 27 as char);
        });
        Result::Ok(())
}