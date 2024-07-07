// use eframe::egui;
//
// #[no_mangle]
// pub extern "C" fn gui_run() {
//     let options = eframe::NativeOptions {
//         viewport: egui::ViewportBuilder::default().with_inner_size([320.0, 240.0]),
//         ..Default::default()
//     };
//
//     // Our application state:
//     let mut name = "Arthur".to_owned();
//     let mut age = 42;
//
//     eframe::run_simple_native("My egui App", options, move |ctx, _frame| {
//         egui::CentralPanel::default().show(ctx, |ui| {
//             ui.heading("Emerald");
//             ui.horizontal(|ui| {
//                 let name_label = ui.label("Your name: ");
//                 ui.text_edit_singleline(&mut name)
//                     .labelled_by(name_label.id);
//             });
//             ui.add(egui::Slider::new(&mut age, 0..=120).text("age"));
//             if ui.button("Increment").clicked() {
//                 age += 1;
//             }
//             ui.label(format!("Hello '{name}', age {age}"));
//         });
//     })
//     .unwrap();
// }
//

use gpui::*;

struct HelloWorld {
    text: SharedString,
}

impl Render for HelloWorld {
    fn render(&mut self, _cx: &mut ViewContext<Self>) -> impl IntoElement {
        div()
            .flex()
            .bg(rgb(0x2e7d32))
            .size_full()
            .justify_center()
            .items_center()
            .text_xl()
            .text_color(rgb(0xffffff))
            .child(format!("Hello, {}!", &self.text))
    }
}

#[no_mangle]
pub extern "C" fn gui_run() {
    App::new().run(|cx: &mut AppContext| {
        cx.open_window(WindowOptions::default(), |cx| {
            cx.new_view(|_cx| HelloWorld {
                text: "World".into(),
            })
        })
        .unwrap();
    });
}
