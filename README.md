# Hungarian Algorithm Implementation

This repository contains an implementation of the Hungarian algorithm for solving the assignment problem. The implementation leverages the JuMP modeling package and the HiGHS optimizer in Julia. The Hungarian algorithm, also known as the Kuhn-Munkres algorithm, finds the optimal assignment for a given cost matrix, where the goal is to minimize or maximize the total cost of assigning jobs to workers.

## Features

- **Linear Programming (LP) Model:** Uses JuMP and HiGHS to solve the assignment problem through linear programming.
- **Market Price Calculation:** Computes market prices for each buyer and seller pair to determine the equilibrium.
- **Equality Graph Creation:** Generates an equality graph that helps in finding maximum matching.
- **Custom Implementation:** A custom implementation of the Hungarian algorithm that adjusts the matching process iteratively.

## Usage

### `maxMatchingLP` Function

The `maxMatchingLP` function computes the maximum matching using a linear programming approach.

### `marketPrices` Function

The `marketPrices` function calculates the market prices for buyers and sellers using the dual variables from the LP model.

### `create_equality_graph` Function

This function creates an equality graph based on the current matchings and the weight matrix.

### `maxMatchingHungarian` Function

The `maxMatchingHungarian` function implements the custom Hungarian algorithm, using iterative steps to find the optimal assignment.

## `sixthtryisthecharm` Function

This function iteratively refines the matching process to find the optimal assignment of buyers to sellers based on the given weight matrix. Below is a detailed breakdown of how this function works:

### 1. Initialization

The function begins by initializing several variables that will be used throughout the process:

- **`matchings`:** A dictionary that stores the current matchings between buyers and sellers. It uses keys like `"buyer_1"` and `"seller_2"` to map a buyer to their corresponding seller and vice versa.
- **`first_equality_graph`:** This matrix is created using the `create_equality_graph` function, which initially sets up an equality graph where each buyer is connected to sellers based on their highest preference.
- **`matching_checker`:** A boolean array that keeps track of whether each buyer has been successfully matched.
- **`final_graph`:** This matrix will store the final matching results.
- **`seller_values`, `max_second_value`, `max_second_buyer`, `max_second_seller`, `passedBy`:** Variables used to track the current state and the next best potential matches during the iteration.

### 2. Main Loop for Matching

The function enters a `while` loop that continues until all buyers are matched:

- **Maximum Value Selection:** The function finds the maximum value in the current `first_equality_graph`, which represents the best potential match between a buyer and a seller. It also identifies the position of this maximum value, which indicates the specific buyer-seller pair.

- **Handling Competing Buyers:**
  - If multiple buyers are competing for the same seller, the function evaluates each buyer’s second-best option. This is crucial for deciding which buyer should be matched with the seller, and which should be rerouted to their next best option.
  - It calculates the difference between the best and second-best matches for competing buyers and selects the match that minimizes this difference, ensuring that the algorithm moves towards an optimal solution.

- **Exclusive Seller Assignment:** If only one buyer is interested in a particular seller (i.e., the seller is exclusive to that buyer), the function directly assigns this match, updates the `final_graph`, and marks the buyer as matched.

- **Iterative Adjustment:** For non-exclusive matches:
  - The function adjusts the weights in the weight matrix `W` by subtracting the calculated difference, effectively rerouting the less optimal buyers to their next best sellers.
  - This ensures that each step of the iteration moves closer to a globally optimal solution.

### 3. Rebuilding the Equality Graph

After each adjustment, the function recreates the `first_equality_graph` to reflect the updated matchings and preferences. This updated graph then guides the next iteration of matching.

### 4. Completion Check

The function continuously checks whether the matching is complete. This is done by ensuring that each buyer and seller has exactly one connection in the `first_equality_graph`, which indicates a perfect matching.

### 5. Return Final Matching

Once all buyers have been successfully matched to sellers, the function exits the loop and returns the `final_graph`, which contains the optimal assignment of buyers to sellers based on the initial weight matrix `W`.
