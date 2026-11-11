import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../models/moment.dart';
import '../services/moment_service.dart';
import '../theme/app_theme.dart';
import '../screens/moments_gallery_screen.dart';
import 'moment_image_view.dart';

class MyMomentsSection extends StatelessWidget {
  final bool isDark;

  const MyMomentsSection({super.key, required this.isDark});

  static void showAddMomentSheet(
    BuildContext context, {
    bool isDark = false,
    String defaultCategory = 'Study',
    Moment? existingMoment,
  }) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddMomentSheet(
        isDark: isDark,
        initialCategory: defaultCategory,
        existingMoment: existingMoment,
      ),
    );
  }

  void _openAddMoment(BuildContext context, {String defaultCategory = 'Study', Moment? existingMoment}) {
    showAddMomentSheet(context, isDark: isDark, defaultCategory: defaultCategory, existingMoment: existingMoment);
  }

  void _viewMomentDetails(BuildContext context, Moment moment) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => _MomentDetailDialog(moment: moment, isDark: isDark),
    );
  }

  void _openGallery(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MomentsGalleryScreen(isDark: isDark)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MomentService.instance,
      builder: (context, _) {
        final moments = MomentService.instance.moments;

        final firstMoment = moments.isNotEmpty ? moments[0] : null;
        final secondMoment = moments.length > 1 ? moments[1] : null;
        final thirdMoment = moments.length > 2 ? moments[2] : null;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Icon, "My Moments", "Upload your progress photos", "View All >"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.image_outlined,
                            size: 19,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Moments',
                                style: GoogleFonts.inter(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.text(isDark),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Upload your progress photos',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSub(isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _openAddMoment(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryOrange.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_photo_alternate_rounded, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'Upload',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _openGallery(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          child: Row(
                            children: [
                              Text(
                                'View All',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryOrange,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: AppTheme.primaryOrange,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 2. Asymmetric Photo Collage (Left Large Card + Right 2 Stacked Cards)
              SizedBox(
                height: 224,
                child: Row(
                  children: [
                    // Left Large Card (Study / Laptop / Books)
                    Expanded(
                      flex: 58,
                      child: _buildMomentCard(
                        context: context,
                        moment: firstMoment,
                        height: 224,
                        fallbackUrl: MomentService.presetPhotos[0]['url']!,
                        fallbackTitle: 'Study Session',
                        fallbackCategory: 'Study',
                        onTap: () {
                          if (firstMoment != null) {
                            _viewMomentDetails(context, firstMoment);
                          } else {
                            _openAddMoment(context, defaultCategory: 'Study');
                          }
                        },
                        onAddTap: () => _openAddMoment(context, defaultCategory: 'Study'),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Right Stacked Column (Dumbbells + Sunset)
                    Expanded(
                      flex: 42,
                      child: Column(
                        children: [
                          // Top Card: Dumbbells
                          Expanded(
                            child: _buildMomentCard(
                              context: context,
                              moment: secondMoment,
                              height: 107,
                              fallbackUrl: MomentService.presetPhotos[1]['url']!,
                              fallbackTitle: 'Workout',
                              fallbackCategory: 'Fitness',
                              onTap: () {
                                if (secondMoment != null) {
                                  _viewMomentDetails(context, secondMoment);
                                } else {
                                  _openAddMoment(context, defaultCategory: 'Fitness');
                                }
                              },
                              onAddTap: () => _openAddMoment(context, defaultCategory: 'Fitness'),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Bottom Card: Sunset Mountains
                          Expanded(
                            child: _buildMomentCard(
                              context: context,
                              moment: thirdMoment,
                              height: 107,
                              fallbackUrl: MomentService.presetPhotos[2]['url']!,
                              fallbackTitle: 'Sunrise Hike',
                              fallbackCategory: 'Nature',
                              onTap: () {
                                if (thirdMoment != null) {
                                  _viewMomentDetails(context, thirdMoment);
                                } else {
                                  _openAddMoment(context, defaultCategory: 'Nature');
                                }
                              },
                              onAddTap: () => _openAddMoment(context, defaultCategory: 'Nature'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMomentCard({
    required BuildContext context,
    required Moment? moment,
    required double height,
    required String fallbackUrl,
    required String fallbackTitle,
    required String fallbackCategory,
    required VoidCallback onTap,
    required VoidCallback onAddTap,
  }) {
    final imageUrl = moment?.imageUrl ?? fallbackUrl;
    final title = moment?.title ?? fallbackTitle;
    final category = moment?.category ?? fallbackCategory;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : const Color(0xFFDCC8B8).withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo Image with smooth caching and fallback (supporting web & gallery photos)
              MomentImageView(
                imageUrl: imageUrl,
                category: category,
                fit: BoxFit.cover,
              ),

              // Gradient dark scrim at the bottom for readability
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.65),
                      ],
                      stops: const [0.5, 0.7, 1.0],
                    ),
                  ),
                ),
              ),

              // Top category badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.5),
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Bottom Title
              Positioned(
                left: 10,
                bottom: 8,
                right: 36,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),

              // Plus (+) Button on Bottom Right matching reference photo
              Positioned(
                right: 7,
                bottom: 7,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onAddTap();
                  },
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: Color(0xFF2C221B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal Dialog displaying detailed full view of a clicked Moment
class _MomentDetailDialog extends StatelessWidget {
  final Moment moment;
  final bool isDark;

  const _MomentDetailDialog({required this.moment, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMM d, yyyy • h:mm a');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image with rounded top corners
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: MomentImageView(
                  imageUrl: moment.imageUrl,
                  category: moment.category,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Content details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          moment.category,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ),
                      Text(
                        dateFormat.format(moment.date),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textSub(isDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    moment.title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.text(isDark),
                    ),
                  ),
                  if (moment.note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      moment.note,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        height: 1.45,
                        color: isDark ? const Color(0xFFCFBDB0) : const Color(0xFF5A4D42),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                        label: Text('Delete', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600)),
                        onPressed: () async {
                          Navigator.pop(context);
                          await MomentService.instance.deleteMoment(moment.id);
                        },
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.primaryOrange, width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 15, color: AppTheme.primaryOrange),
                            label: Text(
                              'Change Photo',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryOrange,
                                fontSize: 12,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              MyMomentsSection.showAddMomentSheet(
                                context,
                                isDark: isDark,
                                defaultCategory: moment.category,
                                existingMoment: moment,
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryOrange,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom Sheet for adding/uploading/editing a progress photo moment
class _AddMomentSheet extends StatefulWidget {
  final bool isDark;
  final String initialCategory;
  final Moment? existingMoment;

  const _AddMomentSheet({
    required this.isDark,
    required this.initialCategory,
    this.existingMoment,
  });

  @override
  State<_AddMomentSheet> createState() => _AddMomentSheetState();
}

class _AddMomentSheetState extends State<_AddMomentSheet> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _urlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late String _selectedCategory;
  late String _selectedImageUrl;
  bool _isFromGallery = false;
  int _imageMode = 0; // 0: Gallery / Camera, 1: Internet URL, 2: Presets

  final categories = ['Study', 'Fitness', 'Nature', 'Mindset', 'Work'];

  // Curated inspiring presets
  final List<Map<String, String>> _inspirationalPresets = [
    {
      'title': 'Study Focus',
      'url': 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?auto=format&fit=crop&w=900&q=80',
    },
    {
      'title': 'Morning Grind',
      'url': 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=900&q=80',
    },
    {
      'title': 'Mountain Peak',
      'url': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=900&q=80',
    },
    {
      'title': 'Coffee & Journal',
      'url': 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=900&q=80',
    },
    {
      'title': 'Library Books',
      'url': 'https://images.unsplash.com/photo-1507842229452-772d139c84e9?auto=format&fit=crop&w=900&q=80',
    },
    {
      'title': 'Sunrise Horizon',
      'url': 'https://images.unsplash.com/photo-1470240731273-7821a6eeb6bd?auto=format&fit=crop&w=900&q=80',
    },
    {
      'title': 'Calm Nature Trail',
      'url': 'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?auto=format&fit=crop&w=900&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingMoment != null) {
      _titleController.text = widget.existingMoment!.title;
      _noteController.text = widget.existingMoment!.note;
      _selectedCategory = widget.existingMoment!.category;
      _selectedImageUrl = widget.existingMoment!.imageUrl;
      _isFromGallery = !_selectedImageUrl.startsWith('http');
      _imageMode = _isFromGallery ? 0 : 1;
      if (!_isFromGallery) {
        _urlController.text = _selectedImageUrl;
      }
    } else {
      _selectedCategory = widget.initialCategory;
      _selectedImageUrl = '';
      _isFromGallery = true;
      _imageMode = 0;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    HapticFeedback.lightImpact();
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _selectedImageUrl = base64String;
          _isFromGallery = true;
          _imageMode = 0;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo selected from your gallery! 📸'),
              backgroundColor: AppTheme.primaryOrange,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access gallery: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickFromCamera() async {
    HapticFeedback.lightImpact();
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final base64Photo = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _selectedImageUrl = base64Photo;
          _isFromGallery = true;
          _imageMode = 0;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo captured successfully! 📸'),
              backgroundColor: AppTheme.primaryOrange,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error using camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access camera: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _applyInternetUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid web image URL (http:// or https://)'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _selectedImageUrl = url;
      _isFromGallery = false;
    });
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Web image loaded! 🌐'),
        backgroundColor: AppTheme.primaryOrange,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title for your moment'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final imageUrlToSave = _selectedImageUrl.trim().isNotEmpty
        ? _selectedImageUrl.trim()
        : MomentService.presetPhotos[0]['url']!;

    if (widget.existingMoment != null) {
      final updated = widget.existingMoment!.copyWith(
        title: title,
        category: _selectedCategory,
        imageUrl: imageUrlToSave,
        note: _noteController.text.trim(),
      );
      await MomentService.instance.updateMoment(updated);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Moment updated successfully! ✨'),
            backgroundColor: AppTheme.primaryOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      final newMoment = Moment(
        id: const Uuid().v4(),
        title: title,
        category: _selectedCategory,
        imageUrl: imageUrlToSave,
        date: DateTime.now(),
        note: _noteController.text.trim(),
      );

      await MomentService.instance.addMoment(newMoment);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inspiring moment added to your timeline! ✨'),
            backgroundColor: AppTheme.primaryOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingMoment != null;
    return Container(
      padding: EdgeInsets.only(
        top: 18,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.white24 : const Color(0xFFDDD0C2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_rounded : Icons.add_photo_alternate_rounded,
                    color: AppTheme.primaryOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isEditing ? 'Edit Inspiring Moment' : 'Add Inspiring Moment',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.text(widget.isDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Image Preview Card with tap-to-upload and status badge
            GestureDetector(
              onTap: _pickFromGallery,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_selectedImageUrl.trim().isNotEmpty)
                        MomentImageView(
                          imageUrl: _selectedImageUrl,
                          category: _selectedCategory,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: widget.isDark ? const Color(0xFF281E18) : const Color(0xFFFAF1E8),
                            border: Border.all(
                              color: AppTheme.primaryOrange.withValues(alpha: 0.4),
                              width: 1.5,
                              strokeAlign: BorderSide.strokeAlignInside,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFECE0),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_rounded,
                                  color: AppTheme.primaryOrange,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Tap to choose photo from gallery',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: widget.isDark ? Colors.white : const Color(0xFF2D2017),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'or use buttons below for camera & web link',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: widget.isDark ? AppTheme.textDarkMuted : AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_selectedImageUrl.trim().isNotEmpty) ...[
                        // Dark top scrim for badge
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 45,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white24, width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isFromGallery
                                      ? Icons.photo_library_rounded
                                      : Icons.public_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _isFromGallery ? 'Photo Ready' : 'Internet / Preset',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Tap to Change pill
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryOrange.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Tap to Change',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Image Source Mode Selector Tabs: [Phone Gallery] [Internet URL] [Presets]
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF281E18) : const Color(0xFFF4ECE4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildSourceTab(0, 'Gallery', Icons.photo_library_outlined),
                  _buildSourceTab(1, 'Internet URL', Icons.link_rounded),
                  _buildSourceTab(2, 'Presets', Icons.auto_awesome_outlined),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Mode 0: Gallery / Camera upload buttons
            if (_imageMode == 0) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppTheme.primaryOrange, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: widget.isDark ? const Color(0xFF382317) : const Color(0xFFFFEDE0),
                      ),
                      icon: const Icon(Icons.photo_library_rounded, color: AppTheme.primaryOrange, size: 20),
                      label: Text(
                        'Upload Gallery',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                      onPressed: _pickFromGallery,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: widget.isDark ? AppTheme.borderDark : const Color(0xFFDCC8B8),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: Icon(
                        Icons.camera_alt_outlined,
                        color: widget.isDark ? Colors.white70 : const Color(0xFF4A3425),
                        size: 20,
                      ),
                      label: Text(
                        'Take Photo',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          color: AppTheme.text(widget.isDark),
                        ),
                      ),
                      onPressed: _pickFromCamera,
                    ),
                  ),
                ],
              ),
            ],

            // Mode 1: Internet URL input
            if (_imageMode == 1) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      style: TextStyle(color: AppTheme.text(widget.isDark), fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Paste image link (https://...)',
                        hintStyle: TextStyle(
                          color: widget.isDark ? AppTheme.textDarkSecondary : const Color(0xFF9E8E80),
                          fontSize: 12.5,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _applyInternetUrl,
                    child: Text(
                      'Load',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],

            // Mode 2: Presets selector
            if (_imageMode == 2) ...[
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _inspirationalPresets.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (ctx, i) {
                    final item = _inspirationalPresets[i];
                    final url = item['url']!;
                    final isChosen = _selectedImageUrl == url;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedImageUrl = url;
                          _isFromGallery = false;
                        });
                      },
                      child: Container(
                        width: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isChosen ? AppTheme.primaryOrange : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(url, fit: BoxFit.cover),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                                  color: Colors.black54,
                                  child: Text(
                                    item['title']!,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Title input
            TextField(
              controller: _titleController,
              style: TextStyle(color: AppTheme.text(widget.isDark)),
              decoration: InputDecoration(
                labelText: 'Moment Title',
                hintText: 'e.g. Completed Chapter 4, Gym PR, Sunrise Run',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Category selector
            Text(
              'Category',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.text(widget.isDark),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryOrange,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.text(widget.isDark),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 14),

            // Note input
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: TextStyle(color: AppTheme.text(widget.isDark)),
              decoration: InputDecoration(
                labelText: 'Reflection / Notes (Optional)',
                hintText: 'What did you accomplish today?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                label: Text(
                  'Save Inspiring Moment',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceTab(int mode, String label, IconData icon) {
    final isSelected = _imageMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _imageMode = mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : (widget.isDark ? Colors.white70 : const Color(0xFF6B584B)),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : (widget.isDark ? Colors.white70 : const Color(0xFF6B584B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

