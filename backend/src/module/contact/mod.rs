pub mod router;
pub mod handler;
pub mod command;
pub mod query;
pub mod model;
pub mod dto;
pub mod metadata;

pub mod event {
    #[derive(Debug, Clone, Copy)]
    pub enum ContactEvent {
        ContactCreated,
        ContactUpdated,
        ContactDeleted,
    }
}
