What is Caching?
=================
 ➤ Caching stores the result of expensive operations (e.g., DB queries, API calls, view rendering) so they can be reused without repeating the work.
 ➤ Rails supports multiple cache layers:
    Fragment Cache: =>	Cache parts of views
    Page Cache:	=> Cache full page (not common today)
    Action Cache: =>	Cache full controller action
    Low-Level: =>	Store any custom data manually

  Redis is commonly used as the backing store for all of these.

Fragment Caching with Redis
===========================
  Useful when you want to cache view partials:

  <% cache(@user) do %>
    <%= render @user %>
  <% end %>

  This will store the HTML for @user in Redis. The cache key is based on @user.cache_key_with_version.

Low-Level Caching (Manually Caching Any Data)
=============================================
  Store data:
    Rails.cache.write("user_#{user.id}_stats", expensive_stats)
  
  Read (and fallback):
    stats = Rails.cache.fetch("user_#{user.id}_stats", expires_in: 10.minutes) do
      user.calculate_stats
    end
  
  This is known as fetch with fallback — most common pattern.

Russian Doll Caching
====================
  It's a nested fragment caching technique in Rails. The idea comes from Russian dolls (matryoshka) — one doll inside another.
  In Rails views:
    You cache the outer object (e.g., a post)
    Inside it, you also cache its associated objects (e.g., comments)
  When one part changes, only that part is re-rendered — not everything.

  <% cache(@post) do %>
    <h2><%= @post.title %></h2>
    <p><%= @post.body %></p>

    <% @post.comments.each do |comment| %>
      <% cache(comment) do %>
        <div><%= comment.body %></div>
      <% end %>
    <% end %>
  <% end %>

  Suppose:
    @post has 5 comments.
    One comment is edited.
  With Russian Doll Caching:
    Only the updated comment's cache is invalidated.
    The rest (post + other comments) are reused from Redis.
    This makes rendering much faster!

  Russian Doll Caching = nested fragment caching
  Fragment Caching = caching any individual block (could be outer or inner)
  So when you nest fragment caches inside each other, it becomes Russian Doll Caching — just like dolls inside dolls.

Cache Invalidation — How It Works
=================================
  Rails uses cache_key_with_version, which includes: Model name, ID, updated_at
  post.cache_key_with_version # => "posts/42-20250602123456"
  So if post.updated_at changes, the key becomes new, and old cache is automatically ignored. No need to delete manually — new key replaces old.

Caching Queries
===============
  Rails.cache.fetch("recent_posts", expires_in: 15.minutes) do
    Post.published.order(created_at: :desc).limit(10).to_a
  end
  Avoid querying the DB every time — cache it in Redis.