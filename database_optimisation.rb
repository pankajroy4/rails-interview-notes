Rails Database Optimizations (Basic and general optimization. Part -1 )
=======================================================================
➤ Select Only What You Need:
    Rails by default loads all columns with SELECT *. Bad for performance when you only need 1-2 fields.
      User.select(:id, :email).where(active: true)
      SELECT "users"."id", "users"."email" FROM "users" WHERE "users"."active" = TRUE

➤ Avoid N+1 Queries Using includes, eager_load, preload

➤ Use .pluck Instead of .map(&:field)
    User.where(active: true).map(&:email) => Inefficient as it loads entire User objects just to get emails.
    User.where(active: true).pluck(:email) => Optimized

➤ Use .exists? Instead of .present? or .any?
    User.where(email: 'x@example.com').present? => Inefficient as it loads records into memory.
    User.exists?(email: 'x@example.com') => Optimized

➤ Batch Processing with .find_each / .in_batches
  🔸Slow & Memory-heavy:
      User.all.each do |user|
        process(user)
      end
    
  🔸Efficient:
      User.find_each(batch_size: 100) do |user|
        process(user)
      end

➤ Use counter_cache to Avoid Count Queries
    N+1 Count:
      user.posts.count => Executes SQL each time.

    The counter_cache (column of type int) value is stored in the parent table (i.e., the table that has has_many). Suppose:
      A User has_many posts
      A Post belongs_to a user
    So, we add the posts_count column to the users table:
      class User < ApplicationRecord
        has_many :posts
      end

      class Post < ApplicationRecord
        belongs_to :user, counter_cache: true
      end      
    Then just use:
      user.posts_count

➤ Use scoped / readonly for Security
    User.readonly.first.update(name: "New") => Avoid accidental updates
    # => ActiveRecord::ReadOnlyRecord error

➤ Use EXPLAIN ANALYZE in SQL to Detect Slow Queries
    In Rails console:
      ActiveRecord::Base.connection.execute("EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'x@example.com'")
    For a query object:
      User.where(email: 'x@example.com').explain


Database Indexing in Rails (Part - 2)
=====================================
 - Think of a database index like the index of a book — it helps find records fast without scanning the entire table.
 - Instead of searching 1 million rows, it jumps right to where the data lives.

  Types of Indexes
  ----------------
  ╰┈➤ Single-Column Index
        add_index :users, :email => Add index in users table on email column.
        
        This will optimize => User.find_by(email: "a@example.com")

  ╰┈➤ Multi-Column (Composite) Index 
        NOTE: In composite Index, order matters.

        add_index :orders, [:user_id, :status] => Add index in orders table on user_id  and statsu column together.
        This will optimize => Order.where(user_id: 1, status: 'shipped')

  ╰┈➤ Unique Index
        Prevents duplicate records at the DB level.
        add_index :users, :email, unique: true
    
  ╰┈➤ Partial Index
        add_index :orders, :user_id, where: "status = 'completed'"

        Only indexes completed orders → lighter & faster for certain queries.
          Order.where(user_id: 1, status: 'completed') # uses index

  ╰┈➤ Function/Expression Index (PostgreSQL only)
        add_index :users, "LOWER(email)", name: "index_users_on_lower_email"

        Now this is optimized:
        User.find_by("LOWER(email) = ?", input.downcase)
      
  ╰┈➤ Foreign Key Indexes
        Always index foreign keys:
          t.references :user, index: true, foreign_key: true
        Optimizes:
          Joins
          WHERE user_id = ?
          Eager loading

  ➤ Use EXPLAIN to Check If Index Is Used
      In Rails console:
        User.where(email: "x@x.com").explain
      Sample output:
        Index Scan using index_users_on_email on users
    
  ➤ Over-Indexing Is Dangerous
      Too many indexes will results in
       🔸Slower INSERT/UPDATE
       🔸Higher storage usage
       🔸More bloat

      🎯 Golden Rule: Index only what you query.

  ➤ How to Know What to Index
      Ask yourself:
  
        | If your query has... | You need index on... |
        | -------------------- | -------------------- |
        | WHERE condition      | the filtered columns |
        | JOIN condition       | the joining column   |
        | ORDER BY             | the sorted column    |
        | Foreign keys         | always index them    |


Transactions, Isolation Levels, and Race Conditions in Rails (Advance)
======================================================================
  ➤ These are critical concepts when multiple users hit your app at once — e.g., ticket bookings, payments, inventory updates.
  
  ➤ What Is a Transaction?
     - A transaction groups multiple database operations into one atomic unit:
     - Either all succeed or all fail — never partial. It prevents from data inconsistency!

      ActiveRecord::Base.transaction do
        user.update!(balance: user.balance - 100)
        order.update!(status: 'paid')
      end

    - If any .update! fails, none of the changes are committed.

  ➤ What Are Isolation Levels?
     - Isolation Levels are part of Database Transactions — a fundamental concept to ensure data integrity when multiple users access the database at the same time.

     - when we write:
        ActiveRecord::Base.transaction do
          user.update!(balance: user.balance - 100)
          account.update!(total: account.total + 100)
        end

        Here, we are creating a transaction — a block that should:
          🔸Complete fully (commit), or
          🔸Be undone entirely (rollback) if anything fails

        Now imagine many users do this at the same time.
         To avoid data inconsistencies (like overspending), databases isolate each transaction from others transaction using "Isolation Levels".

      - There are 4 types of Isolation Levels and there are 3 kinds of problems that may occur during concurrent transactions.

  ➤ Three kinds of problems during concurrent transactions:
     ╰┈➤ Dirty Read:
          - A transaction reads data written by another uncommitted transaction

     ╰┈➤ Non-Repeatable Read:
          - A row you read once changes if you read it again in the same transaction

     ╰┈➤ Phantom Read:
          - You run a query, and rerun it and get different rows (e.g. new rows added)
      
  ➤ Four types of Isolation Levels:
     ╰┈➤ Read Uncommitted (Lowest isolation): Rails does not use this. It is very unsafe.
          🔸Dirty Read allowed → Can read uncommitted data from others transaction.
          🔸Non-repeatable Read → Same row may change mid-transaction.
          🔸Phantom Read → Query result may change due to new inserts.

     ╰┈➤ Read Committed: (Rails default in PostgreSQL)
          🔸No Dirty Reads → Cannot see uncommitted data
          🔸Non-Repeatable Reads → A row you read may change if someone commits new data i.e by other transaction.
          🔸Phantom Read → A repeated query may return new rows.

          → You may get a different value on reload even inside the same transaction. This is non-repeatable read.
          ActiveRecord::Base.transaction do
            product = Product.find(1)
            # Suppose User B updates product price at this stage.
            product.reload # New price!
          end

          → This is Phantom read.
          ActiveRecord::Base.transaction do
            users = User.where(active: true)
            # Someone adds a new active user in parallel
            users = User.where(active: true) # New row appears: Phantom Read
          end

     ╰┈➤ Repeatable Read
          🔸No Dirty Reads → Cannot see uncommitted data
          🔸No Non-Repeatable Reads → Rows you read will not change
          🔸Phantom Read → A repeated query may return new rows.

          ActiveRecord::Base.transaction(isolation: :repeatable_read) do
            # safer but heavier
          end

     ╰┈➤ Serializable (Strictest)
          🔸No Dirty Reads
          🔸No Non-Repeatable Reads
          🔸No Phantom Read

          - Acts like only one transaction is running at a time.
          - But it does not actually queue transactions — it uses conflict detection and may throw:
              ActiveRecord::SerializationFailure (could not serialize access)

    ➤ In SERIALIZABLE isolation level:
        PostgreSQL (and other modern databases) does not queue transactions like a mutex (i.e., one-at-a-time locking).
        Instead, it uses MVCC (Multi-Version Concurrency Control) + conflict detection to simulate serial behavior.

        If it detects that two transactions could have interfered with each other in a way that violates serializability, one of them is rolled back with:
          ActiveRecord::SerializationFailure (could not serialize access due to concurrent update)
        So instead of queueing, it lets both run and detects problems after the fact.

    ➤ But in a system like IRCTC?
        IRCTC has to prevent overbooking in scenarios like Tatkal, where:
          🔸1000+ users try to book 1 ticket at exactly 10:00 AM.
          🔸If two people are shown “1 seat available”, both should not book it.

        Such systems often queue at the application level, not just DB.

      Here is how they might ensure strict control:
          
          1.Application-Level Queuing (Real Queueing)
            🔸Use Redis queues, Kafka, RabbitMQ, etc.
            🔸Requests go into a queue.
            🔸A background job or worker processes one at a time.
            🔸Others wait in line (just like IRL ticket counters).
            🔸This is true queuing, unlike DB isolation levels.

              class BookingWorker
                include Sidekiq::Worker

                def perform(user_id, train_id)
                  ActiveRecord::Base.transaction(isolation: :serializable) do
                    seat = Seat.lock.find_by(train_id: train_id, available: true)
                    raise "No seats" unless seat

                    seat.update!(available: false, user_id: user_id)
                  end
                end
              end
              
            user requests will be enqueue like: BookingWorker.perform_async(current_user.id, train.id)

          2.Optimistic Locking or Pessimistic Locking
              Another technique IRCTC-like systems might use is row-level locking:
               Pessimistic Lock (Rails):
            
               Seat.lock("FOR UPDATE").find(id) => It locks the row until the transaction is done.
              Other users trying to access it will wait (this is queuing via locking).
            
          3.Rate-Limiting & Load Shedding
              Sometimes, the app itself refuses to serve too many concurrent booking attempts, to protect the DB.


    ➤ What Sidekiq Queue Actually Guarantees? 
        class BookingWorker
          include Sidekiq::Worker

          def perform(user_id, train_id)
            ActiveRecord::Base.transaction(isolation: :serializable) do
              seat = Seat.lock.find_by(train_id: train_id, available: true) 
                #or: seat = Seat.lock("FOR UPDATE").find_by(train_id: train_id, available: true) #Rails convert like this internally.
              raise "No seats" unless seat

              seat.update!(available: false, user_id: user_id)
            end
          end
        end

      Here we might think that: Since Sidekiq jobs already run one by one in a queue, why do we still need transaction(isolation: :serializable) or locking inside      them?

        ➤ Sidekiq guarantees job-level FIFO within a queue.
          BUT:
            It does not guarantee only one job runs at a time across the whole app.
            You can have many workers (threads/processes) processing jobs in parallel.
          
          So if 1000 users click "Book Now", and you do:
            BookingWorker.perform_async(user.id, train.id)
          All 1000 jobs enter Redis queue.
          If you have 10 Sidekiq threads, 10 jobs run simultaneously.

          Each job:
            Grabs a connection.
            Starts a transaction.
            Queries for an available seat.
            Now if two threads find the same seat is available, they may try to book it at the same time. This is waht the problem might occur.

 Race Conditions in DB
 ========================