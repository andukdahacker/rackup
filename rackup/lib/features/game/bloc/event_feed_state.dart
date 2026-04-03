import 'package:equatable/equatable.dart';

/// Categories for event feed items, determining left border color.
enum EventFeedCategory {
  /// Green (#22C55E) — score events.
  score,

  /// Gold (#FFD700) — streak events.
  streak,

  /// Blue (#3B82F6) — item events (Epic 5).
  item,

  /// Red (#EF4444) — punishment events (Epic 4).
  punishment,

  /// Purple (#A855F7) — mission events (Epic 6).
  mission,

  /// Off-white (#F0EDF6) — system events (game start/end).
  system,
}

/// A single event in the event feed.
class EventFeedItem extends Equatable {
  /// Creates an [EventFeedItem].
  const EventFeedItem({
    required this.id,
    required this.text,
    required this.category,
    required this.timestamp,
  });

  /// Unique identifier for keying in AnimatedList.
  final String id;

  /// Display text with optional emoji.
  final String text;

  /// Category determining the left border color.
  final EventFeedCategory category;

  /// When the event occurred.
  final DateTime timestamp;

  @override
  List<Object?> get props => [id, text, category, timestamp];
}

/// State for [EventFeedCubit].
class EventFeedState extends Equatable {
  /// Creates an [EventFeedState].
  const EventFeedState({this.events = const []});

  /// Recent events, newest first. Maximum 4 items.
  final List<EventFeedItem> events;

  @override
  List<Object?> get props => [events];
}
