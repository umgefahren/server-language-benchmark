

pub enum CompleteCommand {
    Get {
        key: String
    },
    Set {
        key: String,
        value: String
    },
    Del {
        key: String
    },
    GetCounter,
    SetCounter,
    DelCounter,
    GetDump,
    NewDump,
    DumpInterval {
        duration: chrono::Duration 
    },
    SetTTL {
        key: String,
        value: String,
        duration: chrono::Duration
    }
}

pub fn duration_to_string(duration: &chrono::Duration) -> String {
    let seconds = duration.num_seconds();
    let minutes = duration.num_minutes();
    let hours = duration.num_hours();
    format!("{:?}h-{:?}m-{:?}s", hours, seconds, minutes)
}
