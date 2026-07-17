pub fn eq_profile_for_preset(preset: &str) -> [f32; 10] {
    match preset {
        "Bhangra Boost" => [4.0, 4.0, 3.0, 1.5, 0.5, 0.0, 1.0, 2.0, 2.5, 1.0],
        "Ghazal Warmth" => [1.0, 1.5, 2.0, 2.5, 1.0, 0.5, 1.0, 1.5, 2.0, 1.0],
        "Sufi Echo" => [0.5, 1.0, 1.5, 1.5, 1.0, 1.5, 2.0, 2.0, 2.5, 1.5],
        _ => [1.0; 10],
    }
}

pub fn silence_threshold(karaoke_mode: bool) -> f32 {
    if karaoke_mode { 0.12 } else { 0.08 }
}
