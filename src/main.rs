
use std; 
use clap::{Parser, Subcommand};
mod myapp;
mod imageformat;
mod imagerender;
mod apprunner;
mod videorender;

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
    #[arg(short='X', long="xtotal", default_value_t = 1920)]
    xtotal:usize,
    /// total pixels in image in the y direction
    #[arg(short='Y', long="ytotal", default_value_t = 1080)]
    ytotal:usize,
    #[arg(short='k', long = "kernel_file_path", default_value = "render_kernel.cl")]
    kernel_path: std::path::PathBuf,
    #[arg(short='i', long = "image_file_path", default_value = "oclt2.jpg")]
    image_path: String,
    #[command(subcommand)]
    cmd: Commands
}

#[derive(Subcommand, Debug, Clone)]
enum Commands {
    ImgFormats,
    ImgRender,
    VidRender,
    MyApp,
    Pixels

}

pub fn main() {
    let args = Args::parse();
    match args.cmd {
        Commands::ImgFormats => imageformat::img_formats().expect("msg"),
        Commands::ImgRender => imagerender::render_image(args.kernel_path,args.width,args.height,args.xtotal,args.ytotal).expect("msg"),
        Commands::VidRender => videorender::render_video(args.kernel_path,args.xtotal,args.ytotal).expect("msg"),
        Commands::MyApp => myapp::myapprender(args.kernel_path,args.image_path,args.xtotal,args.ytotal),
        Commands::Pixels => apprunner::pixels_ez_renderer(args.kernel_path, args.image_path,args.xtotal, args.ytotal).expect("msg"),
    }
}        