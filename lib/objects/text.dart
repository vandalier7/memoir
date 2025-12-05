import 'package:flutter/material.dart';

class MemoirDescriptionScrollView extends StatelessWidget {
  const MemoirDescriptionScrollView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2c3e50);
    const Color tertiaryColor = Color(0xFFe74c3c);
    const Color backgroundColor = Color(0xFFf8f9fa);

    return Container(
      padding: const EdgeInsets.all(0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const SizedBox(height: 24),
            RichText(
              textAlign: TextAlign.justify,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  height: 1.8,
                  color: primaryColor,
                  fontFamily: 'Georgia',
                ),
                children: [
                  WidgetSpan(
                    child: SizedBox(width: 40),
                  ),
                  TextSpan(
                    text: 'Welcome to Memoir — ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'your personal space for capturing memories and emotions. ',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  TextSpan(
                    text: 'This app is designed to support ',
                  ),
                  TextSpan(
                    text: 'SDG 3: Good Health and Well-Being',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: tertiaryColor,
                    ),
                  ),
                  TextSpan(
                    text: ', which emphasizes promoting mental health and emotional wellness around the world. By journaling your feelings, reflecting on your experiences, and storing meaningful moments, Memoir helps you ',
                  ),
                  TextSpan(
                    text: 'cultivate emotional awareness and mindfulness',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  TextSpan(
                    text: ' in your daily life.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            RichText(
              textAlign: TextAlign.justify,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  height: 1.8,
                  color: primaryColor,
                  fontFamily: 'Georgia',
                ),
                children: [
                  WidgetSpan(
                    child: SizedBox(width: 40),
                  ),
                  TextSpan(
                    text: 'Every photo and note you post is ',
                  ),
                  TextSpan(
                    text: 'more than a memory',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: ' — it\'s a step toward understanding yourself, processing emotions, and improving your mental well-being. By tying memories to the places you\'ve been, Memoir also helps you ',
                  ),
                  TextSpan(
                    text: 'see patterns in your moods and experiences',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: tertiaryColor,
                    ),
                  ),
                  TextSpan(
                    text: ', giving you a deeper connection to your surroundings and your personal growth.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            RichText(
              textAlign: TextAlign.justify,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  height: 1.8,
                  color: primaryColor,
                  fontFamily: 'Georgia',
                ),
                children: [
                  WidgetSpan(
                    child: SizedBox(width: 40),
                  ),
                  TextSpan(
                    text: 'Memoir is meaningful because it goes beyond traditional social media: ',
                  ),
                  TextSpan(
                    text: 'it\'s not about likes or comparisons, but about your emotional journey',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  TextSpan(
                    text: '. This originality makes it uniquely aligned with ',
                  ),
                  TextSpan(
                    text: 'SDG 3',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: tertiaryColor,
                    ),
                  ),
                  TextSpan(
                    text: ', supporting mental health through ',
                  ),
                  TextSpan(
                    text: 'intentional, reflective, and mindful engagement',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  TextSpan(
                    text: '.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}