# Practice 9 — Put it high, subscribe low

## Lifted version

The commit named `lifted` runs without provider. Adding the cart total to the toolbar changed two constructor signatures: BooksScreen in lib/books_screen.dart and CartBadge in lib/cart_badge.dart. Shell in lib/main.dart computed the total and passed it into BooksScreen; BooksScreen forwarded it even though its list did not display it.

In the lifted widget test, one Add produced seven build log lines: one for BooksScreen and one for each of the six book rows (excluding the initial frame). Removing a book on the cart route also updated the catalogue after navigating back.

## Listening and not listening

Using watch inside an Add callback produces the provider assertion: “Tried to listen to a value exposed with provider, from outside of the widget tree.” The callback is running after build; read gets the model without subscribing.

Using read for the badge count during build produces **no error message**. The count can stay at 0 after adding a book because the badge did not subscribe. An unrelated rebuild can refresh it, so it can look like an intermittent bug.

## Quantity experiment

The widget test tapped the plus button three times with the cart route open, settling each frame. Counting only the `badge build` lines between the BEGIN and END markers (not the opening frame): **watch: 3**, **select on count: 0**. Removing one distinct title printed **1** build with select. The price beside the badge subscribes separately to total, so it still updates when quantities change.

Cart.count counts distinct titles. Two copies of the first book plus one of the second cost 2 × 4200 + 3100 = 11500 ₸, but the badge still says 2. The total section uses Consumer with a const child for the static icon and label.

## Where does it live?

- **Cart — provided** above MaterialApp. Both named routes and the badge need the same instance.
- **Search text — ephemeral** in BooksScreen. It filters that screen without affecting the cart.
- **Total expanded/collapsed — ephemeral** in CartScreen. It only changes how the total is presented.
- **Theme mode (hypothetical) — lifted** above MaterialApp. It changes the theme across routes; a settings switch could send a callback to that owner.
