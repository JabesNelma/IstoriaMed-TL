/// DEVELOPMENT PREVIEW SWITCH — NOT A FEATURE.
///
/// When true, the login screen shows "demo" buttons that enter the staff and
/// patient shells with a fake session, WITHOUT any backend call, so the UI/UX
/// can be reviewed before accounts/memberships are provisioned.
///
/// Set to false (or delete the demo branch in LoginScreen/AuthBloc) before any
/// real deployment. Demo sessions are never persisted and never touch Isar.
const bool kDemoMode = true;
