// team logo watermark for background display

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/theme/colors.dart';
import 'package:scorecard/viewmodels/teams_view_model.dart';
import 'package:scorecard/widgets/common/football_icon.dart';

/// team logo watermark widget
class TeamLogoWatermark extends StatelessWidget {
  const TeamLogoWatermark({required this.teamName, super.key});
  final String teamName;

  /// gradient for fading watermark towards bottom
  static const _watermarkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.black, Colors.black, Colors.transparent],
    stops: [0.0, 0.4, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<TeamsViewModel>(
      builder: (context, teamsProvider, child) {
        final team = teamsProvider.findTeamByName(teamName);
        final logoUrl = team?.logoUrlLarge ?? team?.logoUrl48 ?? team?.logoUrl;

        return Center(
          child: Opacity(
            opacity: 0.2,
            child: SizedBox(
              width: 144,
              height: 144,
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return _watermarkGradient.createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child:
                    logoUrl != null && logoUrl.isNotEmpty
                        ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: logoUrl,
                            fit: BoxFit.cover,
                            // Limit decoded image size (2x for retina)
                            memCacheWidth: 288,
                            memCacheHeight: 288,
                            errorWidget: (context, url, error) {
                              return _buildFallbackLogo(context);
                            },
                          ),
                        )
                        : _buildFallbackLogo(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackLogo(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorService.withAlpha(context.colors.outline, 0.1),
      ),
      child: FootballIcon(
        size: 72,
        color: ColorService.withAlpha(context.colors.outline, 0.3),
      ),
    );
  }
}
