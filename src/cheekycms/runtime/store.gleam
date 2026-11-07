//// The actor that owns the live catalogue and reload status.
////
//// Answers snapshot requests and handles reload messages serially. A successful
//// reload replaces the complete catalogue; a failed reload records errors while
//// retaining the last valid catalogue. The filesystem watcher requests reloads,
//// and the HTTP server reads snapshots.

import cheekycms/content/catalogue
import cheekycms/content/load as discovery
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import gleam/time/calendar
import gleam/time/timestamp

/// Catalogue size and the outcome and timestamps of reload attempts.
pub type Status {
  Status(
    catalogue_size: Int,
    successful_reloads: Int,
    last_successful_reload: String,
    last_reload_attempt: String,
    last_error: Option(String),
  )
}

/// A catalogue and its matching status, read together from the actor.
pub type Snapshot {
  Snapshot(catalogue: catalogue.Catalogue, status: Status)
}

/// An opaque handle to the actor that owns the live catalogue.
pub opaque type Store {
  Store(subject: Subject(Message))
}

type State {
  State(content_root: String, snapshot: Snapshot)
}

type Message {
  Get(reply: Subject(Snapshot))
  Reload
}

/// Start the store with a complete initial catalogue and its content root.
/// Subsequent reload messages discover replacement content from this root.
pub fn start(
  initial: catalogue.Catalogue,
  content_root: String,
) -> Result(Store, actor.StartError) {
  let loaded_at = now()
  let state =
    State(
      content_root:,
      snapshot: Snapshot(
        catalogue: initial,
        status: Status(
          catalogue_size: catalogue.size(initial),
          successful_reloads: 0,
          last_successful_reload: loaded_at,
          last_reload_attempt: loaded_at,
          last_error: None,
        ),
      ),
    )

  actor.new(state)
  |> actor.on_message(handle_message)
  |> actor.start
  |> result.map(fn(started) { Store(started.data) })
}

/// Read the catalogue and reload status in one actor call.
/// The call waits up to five seconds for the store to reply.
pub fn snapshot(store: Store) -> Snapshot {
  let Store(subject:) = store
  actor.call(subject, waiting: 5000, sending: Get)
}

/// Queue a reload without blocking the filesystem watcher.
pub fn reload(store: Store) -> Nil {
  let Store(subject:) = store
  actor.send(subject, Reload)
}

fn handle_message(
  state: State,
  message: Message,
) -> actor.Next(State, Message) {
  case message {
    Get(reply) -> {
      process.send(reply, state.snapshot)
      actor.continue(state)
    }
    Reload -> actor.continue(reload_state(state))
  }
}

// Discover a whole replacement; on failure retain the catalogue and update only status.
fn reload_state(state: State) -> State {
  let Snapshot(catalogue: current, status:) = state.snapshot
  let Status(successful_reloads:, last_successful_reload:, ..) = status
  let attempted_at = now()

  case discovery.discover(state.content_root) {
    Ok(updated) ->
      State(
        ..state,
        snapshot: Snapshot(
          catalogue: updated,
          status: Status(
            catalogue_size: catalogue.size(updated),
            successful_reloads: successful_reloads + 1,
            last_successful_reload: attempted_at,
            last_reload_attempt: attempted_at,
            last_error: None,
          ),
        ),
      )
    Error(errors) ->
      State(
        ..state,
        snapshot: Snapshot(
          catalogue: current,
          status: Status(
            catalogue_size: catalogue.size(current),
            successful_reloads:,
            last_successful_reload:,
            last_reload_attempt: attempted_at,
            last_error: Some(string.inspect(errors)),
          ),
        ),
      )
  }
}

fn now() -> String {
  timestamp.system_time()
  |> timestamp.to_rfc3339(calendar.utc_offset)
}
