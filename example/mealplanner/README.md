# Meal Planner Example

This is intended as a real world example of how Small Universe could work.

The idea is an app that lets you:

- Define meals and ingredients
- Create a meal plan for a week based on those meals
- Create shopping lists for that week

## Running locally

    yarn dev

## Running in Docker

    yarn build
    docker build . --tag mealplanner
    docker run -p 4723:4723 --volume "$PWD/app-content/":/app-content mealplanner
