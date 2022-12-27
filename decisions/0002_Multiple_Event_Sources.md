# Decision: we will have one event stream per domain, rather than a global stream that represents all domains.

One of the interesting parts of this project for me has been that while I have a lot of experience in Front End architecture, I'm trying to build a full stack framework that includes a CQRS and Event Sourced backend - two concepts I am familiar with from hearing others talk about, but have very limited experience in myself.

So some questions I have might be obvious to people with more experience, and some assumptions I make turn out to be wrong.

When I started this project, I think I imagined there being a single event stream for all the events that ever take place in the app. The advantage there would be that replaying the history is straight-forward, and you could fairly reliably reproduce any state in the app.

But as I began building my first example app, I quickly realised there were going to be many types of events, and if I kept them all in a single stream, with a single enum representing those events, it was going to become cluttered quickly:

```haxe
enum MealPlannerEvents {
  AddMeal;
  RenameMeal;
  DeleteMeal;
  AddIngredient;
  RenameIngredient;
  TickIngredient;
  UntickIngredient;
  SetShopForIngredient;
  DeleteIngredient;
  AddMealToPlan;
  RemoveMealFromPlan;
  AddPlanToShoppingList;
  // etc...
}
```

In our code, these then become massive `switch` statements with many different cases to cover. We could nest events, but, we're just adding extra work to the developer to organise their code, when its probably an important part of development for them to consider the various domains in their app and mark out their boundaries.

Another concern was migrations. We're storing our events as serialised JSON, and edits to the event types could require migrations on your event store if the type changes you make aren't backward compatible. Migrations are never much fun (I've avoided doing one in my example app so far!) but they'd become more complex the more domains are mixed up in the same event stream.

I'm not sure any usage of this framework will ever have scaling problems, but if it did, being able to deploy separate domains as separate services and scale them independently would probably be beneficial.

So - I decided that one event stream per domain probably made sense, and have made sure the framework is built around this expectation.

One remaining question I have is if I should be grouping events in each stream around a common "aggregate" - so the "Users" event source might have an `aggregateId` field that groups events related to a particular user, so that we can filter out events related to that user more easily.

I _think_ this is common in other Event Sourcing frameworks, but I don't have enough experience to know for sure yet, and at the time of writing, haven't yet made a decision. Watch this space (or reach out if you want to help me decide!)
