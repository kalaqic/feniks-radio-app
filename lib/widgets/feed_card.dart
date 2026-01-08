import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/feniks_content_generator.dart';

class FeedCard extends StatefulWidget {
  const FeedCard({
    super.key,
    required this.content,
    required this.isActive,
  });

  final Map<String, dynamic> content;
  final bool isActive;

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLiked = false;
  int _likes = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Generate random likes
    _likes = 50 + (DateTime.now().millisecondsSinceEpoch % 200);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likes += _isLiked ? 1 : -1;
    });
    
    if (_isLiked) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final contentType = FeniksContentGenerator.getContentType(widget.content);
    final contentIcon = FeniksContentGenerator.getContentIcon(widget.content);
    final author = widget.content['author'] ?? '';
    final text = widget.content['text'] ?? '';
    final badge = widget.content['badge'];
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.cardBorder,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main post
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryWithOpacity(0.2),
                  child: Icon(
                    contentIcon,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Post content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author and badge
                      Row(
                        children: [
                          Text(
                            author,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            contentType,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Post text
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Action buttons row
                      Row(
                        children: [
                          // Share
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Dijeljenje sadržaja...'),
                                  backgroundColor: AppTheme.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.share_outlined,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 18,
                              ),
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // Like
                          GestureDetector(
                            onTap: _toggleLike,
                            child: AnimatedBuilder(
                              animation: _scaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _scaleAnimation.value,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isLiked ? Icons.favorite : Icons.favorite_border,
                                          color: _isLiked ? const Color(0xFFFF3B30) : Colors.white.withValues(alpha: 0.7),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$_likes',
                                          style: TextStyle(
                                            color: _isLiked ? const Color(0xFFFF3B30) : Colors.white.withValues(alpha: 0.7),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}