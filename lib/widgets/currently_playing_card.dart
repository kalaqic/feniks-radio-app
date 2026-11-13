import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../models/radio_player_model.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/text_formatting.dart';
import 'common_footer.dart';
import 'ui.dart';

/// White block with the song that is playing, the favorite button and the
/// few songs that played before it.
class CurrentlyPlayingCard extends StatefulWidget {
  const CurrentlyPlayingCard({super.key});

  @override
  State<CurrentlyPlayingCard> createState() => _CurrentlyPlayingCardState();
}

class _CurrentlyPlayingCardState extends State<CurrentlyPlayingCard>
    with TickerProviderStateMixin {
  final _favoriteKey = GlobalKey();

  /// A heart jumps out of the favorite button, wiggles at the top and falls
  /// with gravity onto the "Moj profil" tab, where favorites live.
  void _flyHeart() {
    final overlay = Overlay.maybeOf(context);
    final overlayBox = overlay?.context.findRenderObject() as RenderBox?;
    final from = _heartOfButton();
    if (overlay == null || overlayBox == null || from == null) return;
    final to = profileTabCenter(
      overlayBox.size,
      MediaQuery.paddingOf(context).bottom,
    );

    // Three phases: thrown up, a short wiggle at the top, then a fall with
    // gravity (accelerating) onto the tab while it spins a little.
    const rise = .26;
    const wiggle = .55;
    final peak = Offset(from.dx, from.dy - 85);
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );
    var landed = false;

    final entry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final v = controller.value;
          final Offset point;
          final double angle;
          final double scale;
          if (v < rise) {
            final t = Curves.easeOutCubic.transform(v / rise);
            point = Offset.lerp(from, peak, t)!;
            angle = 0;
            scale = 1 + .5 * t;
          } else if (v < wiggle) {
            final t = (v - rise) / (wiggle - rise);
            final shake = math.sin(t * math.pi * 6) * (1 - t);
            point = peak + Offset(shake * 3.5, 0);
            angle = shake * .15;
            scale = 1.5;
          } else {
            final t = (v - wiggle) / (1 - wiggle);
            final fall = t * t;
            point = Offset(
              peak.dx + (to.dx - peak.dx) * Curves.easeInOut.transform(t),
              peak.dy + (to.dy - peak.dy) * fall,
            );
            angle = .8 * fall;
            scale = 1.5 - .8 * fall;
          }
          const size = 18.0;
          return Positioned(
            left: point.dx - size / 2,
            top: point.dy - size / 2,
            child: IgnorePointer(
              child: Opacity(
                opacity: v > .96 ? (1 - v) / .04 : 1,
                child: Transform.rotate(
                  angle: angle,
                  child: Transform.scale(
                    scale: scale,
                    child: const Icon(
                      Icons.favorite,
                      size: size,
                      color: AppTheme.raspberry,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    // The tab reacts right as the heart lands, not after it disappears.
    controller.addListener(() {
      if (!landed && controller.value >= .94) {
        landed = true;
        favoriteLanded.value++;
        hasNewFavorite.value = true;
      }
    });
    overlay.insert(entry);
    controller.forward().whenComplete(() {
      entry.remove();
      controller.dispose();
    });
  }

  /// Where the heart icon of the favorite button is, in overlay coordinates.
  Offset? _heartOfButton() {
    final box = _favoriteKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (box == null || overlayBox == null || !box.hasSize) return null;
    return box.localToGlobal(
      Offset(16 + 8, box.size.height / 2),
      ancestor: overlayBox,
    );
  }

  /// False (and a hint to sign in) when the user may not save favorites.
  bool _canSaveFavorites(ScaffoldMessengerState messenger) {
    if (context.read<AuthService>().isAuthenticated) return true;
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Prijavi se da čuvaš omiljene pjesme'),
        action: SnackBarAction(
          label: 'Prijavi se',
          onPressed: () => Navigator.pushNamed(context, Routes.login),
        ),
      ),
    );
    return false;
  }

  void _toggleFavorite(RadioPlayerModel model) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final isFavorite = model.isFavorite(model.currentSongDisplay);

    if (!isFavorite && !_canSaveFavorites(messenger)) return;
    model.toggleFavorite();
    if (!isFavorite) {
      _flyHeart();
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Uklonjeno iz omiljenih'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleRecent(RadioPlayerModel model, String song) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final isFavorite = model.isFavorite(song);
    if (!isFavorite && !_canSaveFavorites(messenger)) return;
    model.toggleFavoriteSong(song);
    if (!isFavorite) {
      favoriteLanded.value++;
      hasNewFavorite.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final model = context.watch<RadioPlayerModel>();

    final info = TextFormatting.formatSongInfo(
      model.currentSong,
      model.currentArtist,
    );
    final title = info['title'] ?? model.currentSong;
    final artist = info['artist'] ?? model.currentArtist;
    final feat = info['feat'] ?? '';
    final fetching =
        !model.playing && (model.isFetchingCurrentSong || model.isFallbackSong);
    final isFavorite = model.isFavorite(model.currentSongDisplay);
    final recent = model.recentSongs;

    return Container(
      width: double.infinity,
      color: colors.surface,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Trenutno svira',
                  style: TextStyle(fontSize: 13, color: colors.muted),
                ),
              ),
              EqualizerBars(active: model.playing),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, .15),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topLeft,
              children: [...previous, if (current != null) current],
            ),
            child: Column(
              key: ValueKey('$fetching|$title|$artist'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fetching ? 'Pušta se radio…' : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fetching
                      ? 'Molimo sačekajte'
                      : [artist, if (feat.isNotEmpty) 'feat. $feat']
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, color: colors.soft),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _FavoriteButton(
            key: _favoriteKey,
            isFavorite: isFavorite,
            // Studio announcements are not songs and cannot be saved.
            onTap: model.isStationInfo && !isFavorite
                ? null
                : () => _toggleFavorite(model),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: recent.isEmpty
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: Container(
                      padding: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: colors.divider),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ranije na Feniksu',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          for (final (i, song) in recent.indexed)
                            FadeSlideIn(
                              key: ValueKey(song),
                              delay: Duration(milliseconds: 60 * i),
                              offset: const Offset(0, -8),
                              child: _RecentRow(
                                song: song,
                                // Older songs fade a little more.
                                opacity: 1 - i * .18,
                                isFavorite: model.isFavorite(song),
                                onTap: () => _toggleRecent(model, song),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// One song that played earlier, with a small heart to keep it.
class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.song,
    required this.opacity,
    required this.isFavorite,
    required this.onTap,
  });

  final String song;
  final double opacity;
  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final dash = song.indexOf(' - ');
    final title = dash < 0 ? song : song.substring(0, dash);
    final artist = dash < 0 ? '' : song.substring(dash + 3);
    return Opacity(
      opacity: opacity,
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: title,
                style: TextStyle(color: colors.ink),
                children: [
                  if (artist.isNotEmpty)
                    TextSpan(
                      text: '  $artist',
                      style: TextStyle(color: colors.muted),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ),
          Semantics(
            button: true,
            label: isFavorite
                ? 'Ukloni $title iz omiljenih'
                : 'Dodaj $title u omiljene',
            child: Pressable(
              onTap: onTap,
              scale: .8,
              haptic: Haptic.light,
              child: SizedBox(
                width: 40,
                height: 40,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: Tween(begin: .4, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.elasticOut,
                      ),
                    ),
                    child: child,
                  ),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(isFavorite),
                    size: 18,
                    color: isFavorite ? AppTheme.raspberry : colors.muted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onTap,
  });

  final bool isFavorite;

  /// Null greys the button out.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final fg = isFavorite ? Colors.white : colors.ink;
    return AnimatedOpacity(
      opacity: onTap == null ? .35 : 1,
      duration: const Duration(milliseconds: 250),
      child: _button(colors, fg),
    );
  }

  Widget _button(AppColors colors, Color fg) {
    return Semantics(
      button: true,
      label: isFavorite
          ? 'Ukloni pjesmu iz omiljenih'
          : 'Dodaj pjesmu u omiljene',
      enabled: onTap != null,
      child: Pressable(
        onTap: onTap,
        haptic: Haptic.medium,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: ShapeDecoration(
            color: isFavorite ? AppTheme.raspberry : Colors.transparent,
            shape: StadiumBorder(
              side: BorderSide(
                color: isFavorite ? AppTheme.raspberry : colors.fieldLine,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: Tween(begin: .4, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.elasticOut),
                  ),
                  child: child,
                ),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey(isFavorite),
                  size: 15,
                  color: fg,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isFavorite ? 'U omiljenim' : 'Dodaj u omiljene',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
