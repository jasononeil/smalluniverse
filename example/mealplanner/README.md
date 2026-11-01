# Meal Planner Example

This is intended as a real world example of how Small Universe could work.

The idea is an app that lets you:

- Define meals and ingredients
- Create a meal plan for a week based on those meals
- Create shopping lists for that week

## Running locally

    yarn dev

## Running in Docker

From the repository root:

    docker build --pull -f example/Dockerfile --tag mealplanner .
    docker run -p 4723:4723 --volume "$PWD/example/app-content/":/app/app-content mealplanner

The container expects an initialized `app-content` directory, writable by the
container's `app` user. On ARM hosts, building requires Docker's x86-64
emulation because the pinned Haxe compiler is only available for Linux x86-64.
