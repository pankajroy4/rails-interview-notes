Database Scaling Strategies
============================
➤ Scaling Options Overview

  |        Type            |               What It Means                      |          When to Use                      |
  | ---------------------- | ------------------------------------------------ | ----------------------------------------- |
  |   Vertical Scaling     | Make one DB server stronger (more RAM, CPU, SSD) | In early stages of your app               |
  |   Horizontal Scaling   | Add more DBs or servers to divide the load       | For very large systems                    |
  |   Read Replicas        | Create read-only copies of DB for reading        | If most queries are `SELECT`              |
  |   Partitioning         | Break large tables into smaller pieces           | Huge tables like logs, orders             |
  |   Sharding             | Split data into multiple databases               | When user data is huge or region-specific |


  