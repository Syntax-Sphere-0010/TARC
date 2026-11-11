import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/moment.dart';
import '../database/database_helper.dart';

class MomentService extends ChangeNotifier {
  static final MomentService instance = MomentService._internal();

  MomentService._internal();

  final List<Moment> _moments = [];
  bool _isLoading = false;

  List<Moment> get moments => List.unmodifiable(_moments);
  bool get isLoading => _isLoading;

  // Curated preset image options for adding new moments
  static const List<Map<String, String>> presetPhotos = [
    {
      'title': 'Study Desk & Books',
      'category': 'Study',
      'url': 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?auto=format&fit=crop&w=900&q=80',
    },
    {
      'title': 'Morning Dumbbells & Mat',
      'category': 'Fitness',
      'url': 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=900&q=80',
    },
    {
      'title': 'Mountain Sunrise Peak',
      'category': 'Nature',
      'url': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=900&q=80',
    },
    {
      'title': 'Espresso & Planner',
      'category': 'Mindset',
      'url': 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=900&q=80',
    },
    {
      'title': 'Evening Journaling',
      'category': 'Study',
      'url': 'https://images.unsplash.com/photo-1455390582262-044cdead277a?auto=format&fit=crop&w=900&q=80',
    },
    {
      'title': 'Outdoor Trail Run',
      'category': 'Fitness',
      'url': 'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?auto=format&fit=crop&w=900&q=80',
    },
  ];

  Future<void> init() async {
    await loadMoments();
  }

  Future<void> loadMoments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final loaded = await DatabaseHelper.instance.getMoments();
      _moments.clear();

      if (loaded.isEmpty) {
        // Seed default moments matching user's reference image
        final defaults = [
          Moment(
            id: const Uuid().v4(),
            title: 'Study Session',
            category: 'Study',
            imageUrl: presetPhotos[0]['url']!,
            date: DateTime.now().subtract(const Duration(hours: 3)),
            note: 'Finished 2 chapters of Corporate Finance & reviewed case study notes.',
          ),
          Moment(
            id: const Uuid().v4(),
            title: 'Strength Training',
            category: 'Fitness',
            imageUrl: presetPhotos[1]['url']!,
            date: DateTime.now().subtract(const Duration(days: 1)),
            note: 'Dumbbell press and core routine. Felt energized and focused.',
          ),
          Moment(
            id: const Uuid().v4(),
            title: 'Sunrise Summit Hike',
            category: 'Nature',
            imageUrl: presetPhotos[2]['url']!,
            date: DateTime.now().subtract(const Duration(days: 2)),
            note: 'Breathtaking sunrise. Recharged and set weekly milestones.',
          ),
        ];

        for (final m in defaults) {
          await DatabaseHelper.instance.insertMoment(m);
        }
        _moments.addAll(defaults);
      } else {
        _moments.addAll(loaded);
      }
    } catch (e) {
      debugPrint('Error loading moments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMoment(Moment moment) async {
    try {
      await DatabaseHelper.instance.insertMoment(moment);
      _moments.insert(0, moment);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding moment: $e');
    }
  }

  Future<void> deleteMoment(String id) async {
    try {
      await DatabaseHelper.instance.deleteMoment(id);
      _moments.removeWhere((m) => m.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting moment: $e');
    }
  }

  Future<void> updateMoment(Moment moment) async {
    try {
      await DatabaseHelper.instance.updateMoment(moment);
      final idx = _moments.indexWhere((m) => m.id == moment.id);
      if (idx != -1) {
        _moments[idx] = moment;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating moment: $e');
    }
  }
}
