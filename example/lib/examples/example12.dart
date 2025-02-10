import 'package:easy_sticky_header/easy_sticky_header.dart';
import 'package:flutter/material.dart';

import '../test_config.dart';

class Example12 extends StatelessWidget {
  const Example12({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        shadowColor: Colors.transparent,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Infinite list'),
      ),
      body: StickyHeader(
        showFooter: true,
        footerBuilder: (context, index) {
          var nextIndex = index + (30 - (index % 30));
          if (nextIndex > 70) {
            return null;
          }
          return Container(
            color: const Color.fromRGBO(255, 105, 0, 1.0),
            padding: const EdgeInsets.only(left: 16.0),
            alignment: Alignment.centerLeft,
            width: double.infinity,
            height: 50,
            child: Text(
              'Header #$nextIndex',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          );
        },
        child: ListView.builder(
          reverse: TestConfig.reverse,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          itemBuilder: (context, index) {
            if (index % 30 == 0 && index < 70) {
              return StickyContainerWidget(
                index: index,
                child: Container(
                  color: const Color.fromRGBO(255, 105, 0, 1.0),
                  padding: const EdgeInsets.only(left: 16.0),
                  alignment: Alignment.centerLeft,
                  width: double.infinity,
                  height: 50,
                  child: Text(
                    'Header #$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  height: 80,
                  color: Colors.white,
                  padding: const EdgeInsets.only(left: 16),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Item #$index',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
                Divider(
                  height: 1.0,
                  thickness: 1.0,
                  color: Colors.grey.shade200,
                  indent: 16.0,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
