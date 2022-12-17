# Decision: Our HTML type will use an enum as the runtime value, but will support implicit casting from strings and arrays to make it more expressive.

In SmallUniverse we're using a VirtualDOM - we have render functions that return `Html` - and we use that to print HTML on the server, and to update the DOM inside the browser as the app receives updates.

I've made the decision to use a Haxe feature called [Abstract Types](https://haxe.org/manual/types-abstract.html) for the `Html` type.

> An abstract type is a type which is actually a different type at run-time. It is a compile-time feature which defines types "over" concrete types in order to modify or augment their behavior

So what does this mean?

The "concrete" type we use for modelling our virutal DOM nodes is called `HtmlType`, and it is an enum:

```haxe
enum HtmlType<Action> {
	Element(tag:String, attrs:Array<HtmlAttribute<Action>>, children:Html<Action>);
	Text(text:String);
	Comment(text:String);
	Fragment(nodes:Array<Html<Action>>);
  // ... in future we'll probably also have some types specifically for components
}
```

and we have a similar type for attributes:

```haxe
enum HtmlAttribute<Action> {
	Attribute(name:String, value:String);
	BooleanAttribute(name:String, value:Bool);
	Property(name:String, value:Any);
	Event(on:String, fn:(e:Event) -> Option<Action>);
	Hook(hookType:HookType<Action>);
	Key(key:String);
	Multiple(attributes:Array<HtmlAttribute<Action>>);
}
```

These allow us to cleanly model all the HTML elements and nodes that can go on to a page, and we can rely on Haxe features like pattern matching for handling all of the cases.

But... typing these out by hand would be quite verbose:

```
const myParagraph = Element("p", [], Fragment([
	Text("This is"),
	Element("em", [], Text("my")),
	Text("paragraph.")
]))
```

Compared to React (where the runtime values of Nodes can be strings, objects, arrays, null or undefined) using enums in this way makes our Virtual DOM easier to work with, but it feels harder to write.

Using Abstract Types, we can make these easier to write, while ensuring the runtime value continues to be these easy-to-process enums.

To do this we use a feature called [implicit casts](https://haxe.org/manual/types-abstract-implicit-casts.html). These are functions we define on our Html type that allow code to supply some other type, and have it automatically convert into the underlying type we're looking for.

In our case, we provide the following casts:

- from String
- from Array<Html>
- from HtmlType (the raw enums)

So for example:

- `"A string"` becomes `Text("A string")`
- `[Element("img", [], []), Element("hr", [], [])]` becomes `Fragment(Element("img", [], []), Element("hr", [], []))`
- and you can also nest them in interesting ways: `Element("p", ["my name is ", Element("em", "Jason")])`

Combined with some of the helpers we wrote, we get:

```haxe
p([], ["my name is", em([], "Jason")])
```

This isn't quite as clean as using JSX, but for sticking with the native Haxe syntax, its pretty expressive, while keeping the underlying types easy to process and be consistent with.
