import 'package:flutter/widgets.dart';

class ErrorDisplay extends StatelessWidget {
  const ErrorDisplay({super.key, required this.errors});

  final List<(Object, StackTrace?)> errors;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: errors.length,
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding: const EdgeInsets.all(5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xffffffff),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                '${errors[index].$1}',
                style: DefaultTextStyle.of(context).style.copyWith(
                  color: const Color(0xff757575),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
