# Browser demo

This example shows how a language-learning product can turn one typing attempt
into accuracy, CPM, and grapheme-level feedback.

From the package root, run:

```sh
dart pub get
dart compile js example/web/main.dart -o example/web/main.dart.js
python3 -m http.server 8080 --directory example/web
```

Then open <http://localhost:8080>. Add `?autoplay=1` to replay the short
interaction used for the README demo.
