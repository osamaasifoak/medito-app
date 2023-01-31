import 'package:Medito/components/header/collapsible_header_component.dart';
import 'package:Medito/constants/colors/color_constants.dart';
import 'package:Medito/constants/strings/asset_constants.dart';
import 'package:Medito/constants/strings/string_constants.dart';
import 'package:Medito/constants/styles/widget_styles.dart';
import 'package:Medito/network/folder/new_folder_response.dart';
import 'package:Medito/utils/navigation_extra.dart';
import 'package:Medito/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'folder_provider.dart';

class NewFolderScreen extends ConsumerWidget {
  const NewFolderScreen({Key? key, required this.id}) : super(key: key);

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var value = ref.watch(folderDataProvider(id: id, skipCache: false));
    return value.when(
        data: (data) => buildScaffoldWithData(context, data, ref),
        error: (err, stack) => Text(err.toString()),
        loading: () => _buildLoadingWidget());
  }

  Widget _buildLoadingWidget() =>
      const Center(child: CircularProgressIndicator());

  RefreshIndicator buildScaffoldWithData(
      BuildContext context, NewFolderResponse? folder, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        return await ref.refresh(folderDataProvider(id: id, skipCache: true));
      },
      child: Scaffold(
        body: CollapsibleHeaderComponent(
            bgImage: AssetConstants.dalle,
            title: folder?.data?.title ?? '',
            description: folder?.data?.description,
            children: [
              for (int i = 0; i < (folder?.data?.items?.length ?? 0); i++)
                GestureDetector(
                  onTap: () => _onListItemTap(folder?.data?.items?[i].item?.id,
                      folder?.data?.items?[i].item?.type, ref.context),
                  child: _buildListTile(
                      context,
                      folder?.data?.items?[i].item?.title,
                      folder?.data?.items?[i].item?.subtitle,
                      true),
                )
            ]),
      ),
    );
  }

  Container _buildListTile(
      BuildContext context, String? title, String? subtitle, bool showIcon) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 0.5, color: MeditoColors.softGrey),
        ),
      ),
      constraints: BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(
                  title,
                  style: Theme.of(context).primaryTextTheme.bodyText1?.copyWith(
                      color: MeditoColors.walterWhite,
                      fontFamily: DmSans,
                      height: 2),
                ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: Theme.of(context).primaryTextTheme.bodyText1?.copyWith(
                        fontFamily: DmMono,
                        height: 2,
                        color: MeditoColors.newGrey,
                      ),
                )
            ],
          ),
          if (showIcon) Icon(_getIcon(), color: Colors.white)
        ],
      ),
    );
  }

  void _onListItemTap(int? id, String? type, BuildContext context) {
    checkConnectivity().then((value) {
      if (value) {
        var location = GoRouter.of(context).location;
        if (type == 'folder') {
          if (location.contains('folder2')) {
            context.go(getPathFromString(
                Folder3Path, [location.split('/')[2], this.id, id.toString()]));
          } else {
            context
                .go(getPathFromString(Folder2Path, [this.id, id.toString()]));
          }
        } else {
          context.go(location + getPathFromString(type, [id.toString()]));
        }
      } else {
        createSnackBar(CHECK_CONNECTION, context);
      }
    });
  }

  IconData _getIcon() {
    return Icons.check_circle_outline_sharp;
    // return Icons.article_outlined;
    // return Icons.arrow_forward_ios_sharp;
  }
}