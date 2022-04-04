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

impl From<CompleteCommand> for String {
    fn from(c: CompleteCommand) -> Self {
        match c {
            CompleteCommand::Get { key } => {
                format!("GET {}", key)
            }
            CompleteCommand::Set { key, value } => {
                format!("SET {} {}", key, value)
            }
            CompleteCommand::Del { key } => {
                format!("DEL {}", key)
            }
            CompleteCommand::GetCounter => {
                String::from("GETC")
            }
            CompleteCommand::SetCounter => {
                String::from("SETC")
            }
            CompleteCommand::DelCounter => {
                String::from("DELC")
            }
            CompleteCommand::GetDump => {
                String::from("GETDUMP")
            }
            CompleteCommand::NewDump => {
                String::from("NEWDUMP")
            }
            CompleteCommand::DumpInterval { duration } => {
                format!("DUMPINTERVAL {}h-{}m-{}s", duration.num_hours(), duration.num_minutes(), duration.num_seconds())
            }
            CompleteCommand::SetTTL { key, value, duration } => {
                format!("SETTTL {} {} {}h-{}m-{}s", key, value, duration.num_hours(), duration.num_minutes(), duration.num_seconds())
            }
        }
    }
}
