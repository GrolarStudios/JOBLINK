import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GlobalHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? message;
  final String? title;

  const GlobalHeader({super.key, this.message, this.title});

  @override
  Size get preferredSize => const Size.fromHeight(350);

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final double headerHeight = isLandscape
        ? MediaQuery.of(context).size.height * 0.20
        : MediaQuery.of(context).size.height * 0.20;

    return SizedBox(
      height: headerHeight,
      child: Stack(
        children: <Widget>[
          ClipPath(
            clipper: WaveClipperTwo(),
            child: Container(
              height: headerHeight,
              color: Colors.blue,
            ),
          ),
          Positioned(
            top: headerHeight * 0.15,
            left: 16,
            child: message != '/home'
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).maybePop();
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    title ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ],
            )
                : Container(),
          ),
          Positioned(
            top: headerHeight * 0.20,
            left: 0,
            right: 0,
            child: message == '/home'
                ? Center(
              child: SvgPicture.asset(
                'assets/images/fg.svg',
                width: 200,
                height: 55,
                fit: BoxFit.cover,
              ),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
