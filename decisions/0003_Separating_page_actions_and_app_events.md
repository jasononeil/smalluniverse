# Separating page "actions" and app "events"

This decision follows on from the last one, that [we will have one event stream per domain, rather than a global stream that represents all domains](./0002_Multiple_Event_Sources.md).

When I first imagined the Small Universe framework, I'd imagined that the events triggered on a page would be the same as the events we record in the database.

I had imagined the progression might be:

- User clicks a button, which triggers a `SetNewPassword(password)` event.
- This sends a HTTP Post request to the server, with the data in the `SetNewPassword` event. eg `{ SetNewPassword: { password: "so_incredibly_secure" } }`
- That data is then sent to the appropriate `EventSource`, and probably saved directly to the `EventLog` without any modifications.
- Any projections are updated with the data from the `EventLog` request.
- The client then receives updated props for the page.

Once I started building an example app I quickly realised that our domains can get quite large, and we wanted to have a different Event Source for each of our data domains. And it seemed like it would rarely be the case that a data domain had a nice mapping to a page - most pages would rely on multiple data domains, and most data domains would serve multiple pages. It was likely going to be a many-to-many relationship.

There was also the problem that sometimes the thing we want in our database isn't the same as the thing we want in the browser. In the `SetNewPassword` example, you definitely don't want to store the password directly in your database, you want to store a hash of it. You probably also want to generate the hash with some extra data that is only known server-side (called a "salt") so that its harder to reverse the hash. So the client will send the password over HTTPS, but we want to transform it into a hash on the server before we ever save it to a database.

So I decided to separate the two concepts:

- `Action`: an action a user has triggered on a page (which may yet be modified or rejected).
- `Event`: an event that has occurred and is part of our data history going forward.

This time, the progression looks like:

- User clicks a button, which triggers a `SetNewPassword(password)` event.
- This sends a HTTP Post request to the server, with the data in the `SetNewPassword` event. eg `{ SetNewPassword: { password: "..." } }`
- A PageAPI receives this request, and handles it. Is there a valid user session already? If not, it can reject it. If it does accept it, it should hash it, using a server-side "salt" string, and turn it into an event `PasswordUpdated(passwordHash)`.
- That event is then sent to the appropriate `EventSource` as a Command. This can still be validated and rejected (and the EventSource should be the main line of defence in validating data or commands). But if accepted, an event will be saved to the `EventLog`.
- Any projections are updated with the data from the `EventLog`.
- The client then receives updated props for the page.

You might notice the slight tweak in wording:

- The `Action` is something the user is trying, so it helps to write it in present tense and imperative: `SetNewPassword`.
- The `Event` is something that has happened, so it helps to write it in past tense: `PasswordUpdated`.
- You could use the same name for both if its easier, but using words to differentiate actions that are still being handled, from events that already occurred, can help your code be easier to read.

So a PageApi now looks like this:

```haxe
/**
  A PageApi is the back-end API required for displaying a page and handling its actions and updates.

	Each Page should have exactly one PageApi, and the PageApi can interact with multiple `EventSource` or `Projection` services.
**/
interface PageApi<Action, PageParams, PageData> {
	/** A reference to the Page class this API is tightly coupled to. **/
	var relatedPage(default, null):Class<Page<Action, PageParams, PageData>>;

	/** Load data for the given page. **/
	function getPageData(pageParams:PageParams):Promise<PageData>;

	/** Convert a page Action into the relevant Command for our Event Stores.**/
	function actionToCommand(
		pageParams:PageParams,
		action:Action
	):Promise<Command<Any>>;
}
```

In the `getPageData()` function we can load data from multiple domains (either a combination of `EventSources` and `Projections`).

And in `actionToCommand()` we take the PageAction, and have a chance to perform some validation, add some data known to the server, and turn it into a `Command` - a request to add an event to one or more event sources.

This de-coupling of pages from event domains is actually quite similar to an architecture we've landed on in my work at Culture Amp - many back end services with their data domains, many front end apps with their pages. We use an API layer (we call them "backend for frontends") that belong to the page, but can request data from many domain data services.
