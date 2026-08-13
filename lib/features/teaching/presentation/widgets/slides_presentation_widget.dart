import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/presentation/widgets/lesson_block_card.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class SlidesPresentationWidget extends StatefulWidget {
  final List<LessonBlock> blocks;
  final int initialIndex;

  const SlidesPresentationWidget({
    super.key,
    required this.blocks,
    this.initialIndex = 0,
  });

  @override
  State<SlidesPresentationWidget> createState() => _SlidesPresentationWidgetState();
}

class _SlidesPresentationWidgetState extends State<SlidesPresentationWidget> {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _isFullScreen = false;
  bool _showThumbnailGrid = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setPreferredOrientations([]);
      }
    });
  }

  void _toggleThumbnailGrid() {
    setState(() => _showThumbnailGrid = !_showThumbnailGrid);
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _navigateToSlide(int index) {
    setState(() {
      _showThumbnailGrid = false;
      _currentIndex = index;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _goToNextSlide() {
    if (_currentIndex < widget.blocks.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousSlide() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_showThumbnailGrid) {
      return _buildThumbnailGrid(l10n);
    }

    return _buildPresentationView(l10n);
  }

  Widget _buildPresentationView(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: widget.blocks.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(_isFullScreen ? 48 : 16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: LessonBlockCard(
                    block: widget.blocks[index],
                    allBlocks: widget.blocks,
                    blockIndex: index,
                  ),
                ),
              );
            },
          ),
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(l10n),
            ),
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(l10n),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.6),
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.only(top: 40, left: 8, right: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: l10n.close,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              l10n.pageIndicator(_currentIndex + 1, widget.blocks.length),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(
              _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
            ),
            tooltip: _isFullScreen ? 'Exit full screen' : 'Full screen',
            onPressed: _toggleFullScreen,
          ),
          IconButton(
            icon: const Icon(Icons.grid_view, color: Colors.white),
            tooltip: 'Slide grid',
            onPressed: _toggleThumbnailGrid,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.6),
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.only(bottom: 32, left: 16, right: 16, top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_right
                  : Icons.chevron_left,
              color: Colors.white,
            ),
            tooltip: l10n.previous,
            onPressed: _currentIndex > 0 ? _goToPreviousSlide : null,
          ),
          const SizedBox(width: 16),
          _buildSlideProgress(),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              color: Colors.white,
            ),
            tooltip: l10n.next,
            onPressed: _currentIndex < widget.blocks.length - 1
                ? _goToNextSlide
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSlideProgress() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        widget.blocks.length,
        (index) => GestureDetector(
          onTap: () => _navigateToSlide(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: _currentIndex == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentIndex == index
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailGrid(AppLocalizations l10n) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.slides),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.close,
          onPressed: () => setState(() => _showThumbnailGrid = false),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          childAspectRatio: 3 / 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: widget.blocks.length,
        itemBuilder: (context, index) {
          final block = widget.blocks[index];
          final isSelected = index == _currentIndex;
          return _buildThumbnailItem(block, index, isSelected);
        },
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width > 1200) return 6;
    if (width > 800) return 4;
    if (width > 500) return 3;
    return 2;
  }

  Widget _buildThumbnailItem(LessonBlock block, int index, bool isSelected) {
    return GestureDetector(
      onTap: () => _navigateToSlide(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(7),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _slideTypeIcon(block.slideType),
                      size: 24,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      block.content,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(7),
                ),
              ),
              child: Text(
                '${index + 1}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _slideTypeIcon(SlideType? slideType) {
    return switch (slideType) {
      SlideType.title => Icons.title,
      SlideType.concept => Icons.lightbulb_outline,
      SlideType.definition => Icons.menu_book,
      SlideType.formula => Icons.functions,
      SlideType.example => Icons.calculate,
      SlideType.summary => Icons.checklist,
      SlideType.quiz => Icons.quiz,
      SlideType.reference => Icons.library_books,
      SlideType.tableOfContents => Icons.list,
      null => Icons.slideshow,
    };
  }
}
