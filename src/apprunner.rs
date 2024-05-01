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
        let pixels = {
            let window_size = window.inner_size();
            let surface_texture = ::pixels::SurfaceTexture::new(window_size.width, window_size.height, &window);
            pixels::Pixels::new(xtotal.try_into().unwrap(), ytotal.try_into().unwrap(), surface_texture)?
            };
        let _white_l = 
            myapp::L{
                color:[0.755,0.748,0.751],
                reflection:true,
                refraction:false,
                n:0.,
                roughness:1.0,
                fresnel:0.,
                density:0.,
            };
        let green_l = 
            myapp::L{
                color:[0.061,0.426,0.061],
                reflection:true,
                refraction:false,
                n:0.,
                roughness:1.0,
                fresnel:0.,
                density:0.,
            };
        let red_l = 
            myapp::L{
                color:[0.443,0.061,0.062],
                reflection:true,
                refraction:false,
                n:0.,
                roughness:1.0,
                fresnel:0.,
                density:0.,
            };
        let light_l = 
            myapp::L { 
                color: [18.,15.,8.], 
                reflection: false, 
                refraction: false, 
                n: 0., 
                roughness: 1.0, 
                fresnel: 0., 
                density: 0. 
            };
        let s_cube_l = 
            myapp::L { 
                color: [0.755,0.748,0.751],         
                reflection: true, 
                refraction: false, 
                n: 2., 
                roughness: 1.0, 
                fresnel: 0., 
                density: 0. 
            };
        let t_cube_l = 
            myapp::L { 
                color: [0.755,0.748,0.751],         
                reflection: true, 
                refraction: false, 
                n: 1.5, 
                roughness: 1.0, 
                fresnel: 0., 
                density: 0. 
            };
        let wall_l = 
            myapp::L{
                color:[0.755,0.748,0.751],
                reflection:true,
                refraction:false,
                n:0.,
                roughness:1.0,
                fresnel:0.,
                density:0.,
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
            p1:[3.430,2.270,5.48795],
            p2:[3.430,3.320,5.48795],    
            p3:[2.130,3.320,5.48795],  
            R:0.01,  
            L:light_l,
        },//light
        myapp::triangle{
            p1:[3.430,2.270,5.48795],
            p2:[2.130,3.320,5.48795],    
            p3:[2.130,2.270,5.48795],  
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
        let world = std::sync::Arc::new(std::sync::Mutex::new(myapp::MyApp::new(pixels,file_path,"default.jpg".to_string().clone(),xtotal,ytotal,triangles.len())));
        let c2 = std::sync::Arc::clone(&barrier);
        
        world.lock().unwrap().loadtriangles(triangles);
        let _render_thread = {
            let c1 = std::sync::Arc::clone(&barrier);
            let worldt = std::sync::Arc::clone(&world);
            std::thread::spawn(move || {
                // let imaget = image.clone();
                worldt.lock().unwrap().src_img1.write(&image::io::Reader::open("default.jpg".to_string()).unwrap().decode().unwrap().to_rgba8()).enq().unwrap();
                worldt.lock().unwrap().src_img2.write(&image::io::Reader::open("default.jpg".to_string()).unwrap().decode().unwrap().to_rgba8()).enq().unwrap();
                // worldt.lock().unwrap().src_img1.write(&image::io::Reader::open(image.clone()).unwrap().decode().unwrap().to_rgba8()).enq().unwrap();

            loop {
                c1.wait();
                let mut worldlocked = worldt.lock().unwrap();                    
                worldlocked.render("render".to_string());//.update();
                // worldlocked.dst_img1.cmd().copy(&worldlocked.dst_img1, [0, 0, 0]).enq().unwrap();
                worldlocked.dst_img1.cmd().copy(&worldlocked.src_img1, [0, 0, 0]).enq().unwrap();
                if(worldlocked.frameintg>=512){
                    worldlocked.save("ROCL2.PNG".to_string());
                    todo!();
                }
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
                if let Err(_errr) = world.lock().unwrap().raw_img.render() {
                    control_flow.exit();
                    return;
                }
                c2.wait();
            }
            // if let Event::UserEvent(val) = event {
            //     // let mut a = pixels.frame_mut();
            //     // a = world.draw().as_mut_slice();
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
                 input.key_held(winit::keyboard::KeyCode::KeyC) )|| 
                input.close_requested() {
                    control_flow.exit();
                    return;
                }
    
                // Resize the window
                if let Some(size) = input.window_resized() {
                    world.lock().unwrap().raw_img.resize_surface(size.width, size.height).unwrap();
                }
                window.request_redraw();
                window.pre_present_notify();
                // Update internal state and request a redraw
                // world.update();

                // println!("time in millisec: {} ", (now_save.elapsed().as_nanos() as f64)/1000000.);
                // println!(" fps:{}",1./((now_save.elapsed().as_nanos() as f64)/1000000000.));

            }
            // if world.lock().unwrap().time.elapsed() - time_rendered >= std::time::Duration::from_millis(30) {
            //     time_rendered = world.lock().unwrap().time.elapsed();

            //     }
            println!("total frames:{frames}");
            println!("frames per second: {}",(frames as f64)/((now_total.elapsed().as_nanos() as f64)/1000000000.));
            println!("loops per second: {}",(loops as f64)/((now_total.elapsed().as_nanos() as f64)/1000000000.));
            print!("{esc}c", esc = 27 as char);
        });
        Result::Ok(())
}