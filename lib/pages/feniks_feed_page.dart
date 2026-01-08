import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/feniks_content_generator.dart';
import '../widgets/feed_card.dart';
import '../widgets/common_footer.dart';

class FeniksFeedPage extends StatefulWidget {
  const FeniksFeedPage({super.key});

  @override
  State<FeniksFeedPage> createState() => _FeniksFeedPageState();
}

class _FeniksFeedPageState extends State<FeniksFeedPage> {
  List<Map<String, dynamic>> _content = [];

  @override
  void initState() {
    super.initState();
    _generateInitialContent();
  }

  void _generateInitialContent() {
    _content = List.generate(10, (_) => FeniksContentGenerator.generateContent());
  }

  void _generateMoreContent() {
    final newContent = List.generate(5, (_) => FeniksContentGenerator.generateContent());
    setState(() {
      _content.addAll(newContent);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              title: const Text(
                'Feniks Feed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _content.clear();
                      _generateInitialContent();
                    });
                  },
                ),
              ],
            ),
            
            // Feed content
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Generate more content when near the end
                  if (index >= _content.length - 3) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _generateMoreContent();
                    });
                  }
                  
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == _content.length - 1 ? 120 : 0,
                    ),
                    child: FeedCard(
                      content: _content[index],
                      isActive: true,
                    ),
                  );
                },
                childCount: _content.length,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CommonFooter(currentRoute: '/feed', isDark: true),
    );
  }
}