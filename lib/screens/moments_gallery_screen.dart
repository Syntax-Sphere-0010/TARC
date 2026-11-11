import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/moment.dart';
import '../services/moment_service.dart';
import '../theme/app_theme.dart';
import '../widgets/moment_image_view.dart';
import '../widgets/my_moments_section.dart';

class MomentsGalleryScreen extends StatefulWidget {
  final bool isDark;

  const MomentsGalleryScreen({super.key, required this.isDark});

  @override
  State<MomentsGalleryScreen> createState() => _MomentsGalleryScreenState();
}

class _MomentsGalleryScreenState extends State<MomentsGalleryScreen> {
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();

  final categories = ['All', 'Study', 'Fitness', 'Nature', 'Mindset', 'Work'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDetail(Moment moment) {
    HapticFeedback.lightImpact();
    final dateFormat = DateFormat('EEEE, MMM d, yyyy • h:mm a');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: widget.isDark ? AppTheme.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: SizedBox(
                  height: 240,
                  child: MomentImageView(
                    imageUrl: moment.imageUrl,
                    category: moment.category,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
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
                            color: widget.isDark ? const Color(0xFF382317) : const Color(0xFFFFECE0),
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
                            color: AppTheme.textSub(widget.isDark),
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
                        color: AppTheme.text(widget.isDark),
                      ),
                    ),
                    if (moment.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        moment.note,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          height: 1.45,
                          color: widget.isDark ? const Color(0xFFCFBDB0) : const Color(0xFF5A4D42),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                          label: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            Navigator.pop(ctx);
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
                                Navigator.pop(ctx);
                                MyMomentsSection.showAddMomentSheet(
                                  context,
                                  isDark: widget.isDark,
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
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MomentService.instance,
      builder: (context, _) {
        var list = MomentService.instance.moments;

        // Filter category
        if (_selectedCategory != 'All') {
          list = list.where((m) => m.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
        }

        // Search query
        final q = _searchController.text.trim().toLowerCase();
        if (q.isNotEmpty) {
          list = list.where((m) => m.title.toLowerCase().contains(q) || m.note.toLowerCase().contains(q)).toList();
        }

        return Scaffold(
          backgroundColor: widget.isDark ? AppTheme.bgDark : AppTheme.bgCream,
          appBar: AppBar(
            backgroundColor: widget.isDark ? AppTheme.cardDark : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.text(widget.isDark), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'My Moments Gallery',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.text(widget.isDark),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Upload Moment',
                icon: const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.primaryOrange),
                onPressed: () => MyMomentsSection.showAddMomentSheet(context, isDark: widget.isDark),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'gallery_add_moment',
            backgroundColor: AppTheme.primaryOrange,
            elevation: 4,
            icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 20),
            label: Text(
              'Upload Moment',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
            ),
            onPressed: () => MyMomentsSection.showAddMomentSheet(context, isDark: widget.isDark),
          ),
          body: Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isDark ? AppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.softShadow(),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: AppTheme.text(widget.isDark)),
                    decoration: InputDecoration(
                      hintText: 'Search your moments...',
                      hintStyle: TextStyle(color: AppTheme.textSub(widget.isDark), fontSize: 13.5),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryOrange, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),

              // Category chips
              SizedBox(
                height: 46,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final cat = categories[i];
                    final isSel = _selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSel,
                      selectedColor: AppTheme.primaryOrange,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppTheme.text(widget.isDark),
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12.5,
                      ),
                      onSelected: (sel) {
                        if (sel) setState(() => _selectedCategory = cat);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Grid of moments
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Text(
                          'No moments found in this category.',
                          style: GoogleFonts.inter(color: AppTheme.textSub(widget.isDark), fontSize: 14),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(18),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final item = list[i];
                          return GestureDetector(
                            onTap: () => _showDetail(item),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: AppTheme.softShadow(),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    MomentImageView(
                                      imageUrl: item.imageUrl,
                                      category: item.category,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(alpha: 0.7),
                                            ],
                                            stops: const [0.5, 1.0],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item.category,
                                          style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 10,
                                      left: 10,
                                      right: 10,
                                      child: Text(
                                        item.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
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
          ),
        );
      },
    );
  }
}
