import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../models/radio_player_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_footer.dart';
import '../widgets/ui.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RadioPlayerModel>().trackPageVisit(Routes.favorites);
      }
      // The new favorites are seen now; the dot on "Moj profil" goes away.
      hasNewFavorite.value = false;
    });
  }

  void _remove(RadioPlayerModel model, String song) {
    model.removeFavorite(song);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Uklonjeno iz omiljenih'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final model = context.watch<RadioPlayerModel>();
    final loggedIn = context.watch<AuthService>().isAuthenticated;
    // Saved oldest first; the newest one goes on top.
    final songs = model.favoriteSongs.reversed.toList();

    return StripedPage(
      children: [
        const FadeSlideIn(child: BackLink('Nazad na početnu')),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: FadeSlideIn(
            delay: Duration(milliseconds: 40),
            child: PageTitle('Omiljene pjesme'),
          ),
        ),
        if (!loggedIn) ...[
          const FadeSlideIn(
            delay: Duration(milliseconds: 80),
            child: LoginPrompt(
              title: 'Želiš mogućnost da sačuvaš svoje omiljene pjesme?',
              message: 'Prijavi se i pjesme koje voliš uvijek su ti pri ruci.',
              color: AppTheme.raspberry,
            ),
          ),
          const FadeSlideIn(
            delay: Duration(milliseconds: 200),
            child: _LockedPreview(),
          ),
        ] else if (songs.isEmpty)
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: Container(
              color: colors.surface,
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Još nemaš omiljenih pjesama',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Kad čuješ pjesmu koja ti se sviđa, na početnoj klikni '
                    '"Dodaj u omiljene".',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.55,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextLink(
                    'Vrati se na radio',
                    padding: EdgeInsets.zero,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Container(
            color: colors.surface,
            child: Column(
              children: [
                for (final (i, song) in songs.indexed)
                  FadeSlideIn(
                    key: ValueKey(song),
                    delay: Duration(milliseconds: 100 + 70 * (i < 10 ? i : 10)),
                    offset: const Offset(-24, 0),
                    child: _SongRow(
                      song: song,
                      index: i,
                      onRemove: () => _remove(model, song),
                    ),
                  ),
              ],
            ),
          ),
          FadeSlideIn(
            delay: const Duration(milliseconds: 500),
            child: Text(
              'Klikni na srce da ukloniš pjesmu iz omiljenih.',
              style: TextStyle(fontSize: 13, color: colors.muted),
            ),
          ),
        ],
      ],
    );
  }
}

const _rowColors = [AppTheme.raspberry, AppTheme.blue, AppTheme.coral];

class _SongRow extends StatelessWidget {
  const _SongRow({
    required this.song,
    required this.index,
    required this.onRemove,
  });

  final String song;
  final int index;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final parts = song.split(' - ');
    final title = parts.first;
    final artist = parts.length > 1 ? parts.sublist(1).join(' - ') : '';
    final square = _rowColors[index % _rowColors.length];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        border: index == 0
            ? null
            : Border(top: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            color: square,
            child: Icon(
              Icons.music_note_outlined,
              size: 18,
              color: AppTheme.onBrand(square),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: colors.ink,
                  ),
                ),
                if (artist.isNotEmpty)
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: colors.muted),
                  ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'Ukloni $title iz omiljenih',
            child: Pressable(
              onTap: onRemove,
              scale: .85,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.favorite,
                  size: 20,
                  color: AppTheme.raspberry,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two blurred example songs behind a lock, shown to logged-out users.
class _LockedPreview extends StatelessWidget {
  const _LockedPreview();

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);

    Widget row(String title, String artist, Color square, bool divider) =>
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            border: divider
                ? Border(top: BorderSide(color: colors.divider))
                : null,
          ),
          child: Row(
            children: [
              Container(width: 40, height: 40, color: square),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artist,
                      style: TextStyle(fontSize: 13, color: colors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.favorite, size: 20, color: AppTheme.raspberry),
            ],
          ),
        );

    return ExcludeSemantics(
      child: Container(
        color: colors.surface,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Column(
                children: [
                  row('Naziv pjesme', 'Ime izvođača', AppTheme.blue, false),
                  row('Druga pjesma', 'Drugi izvođač', AppTheme.coral, true),
                ],
              ),
            ),
            Icon(Icons.lock_outline, size: 26, color: colors.ink),
          ],
        ),
      ),
    );
  }
}
