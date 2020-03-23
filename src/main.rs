use iui::UI;
use iui::controls::{Window, WindowType};

fn main() {
    let ui = UI::init().expect("Failed to start UI");
    let mut window = Window::new(&ui, "Choose", 300, 200, WindowType::NoMenubar);
    window.show(&ui);
    
    ui.main();
}
