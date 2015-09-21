## Watchman

Rack based authorization middleware.

## Setup

### Rack

Watchman _must_ be downstream of some kind of authentication middleware. It _must_ have
a failure application declared, and you should declare which strategy to use by
default.

```ruby
Rack::Builder.new do
  use Rack::Session::Cookie, :secret => "replace this with some secret key"

  ## Setup authentication

  use Warden::Manager do |warden|
    warden.default_strategies :password
    warden.failure_app = BadAuthenticationEndsUpHere
  end

  use Watchman::Manager do |watchman|
    # use the 'warden' strategy to get access to the permission collection
    watchman.default_strategies :warden
    watchman.failure_app = BadAuthorizationEndsUpHere
  end

  run SomeApp
end
```

### Session

One of the results of using any kind of permission objects is that you need to
tell Watchman how to serialize the permissions in and out of the session. You'll
need to set this up

```ruby
Watchman::Manager.serialize_into_session do |permissions|
  permissions.map(&:id)
end

Watchman::Manager.serialize_from_session do |ids|
  Permission.get(ids)
end
```

This can of course be as complex as needed.

### Declare Some Strategies

You'll need to declare some strategies to be able to get Watchman to actually authorize.
Watchman uses the conceof strategies to determine if a request should be authorized.
Watchman will try strategies one after another until either,
* One succeeds
* No strategies found relevant
* A strategy fails

Conceptually a strategy is where you put the logic for determining the permissions
for a request. Practically, it's a decendant of @Watchman::Strategies::Base@.

You can define many strategies and one will be selected and used.

```ruby
Watchman::Strategies.add(:warden) do
  def valid?
    env.has_key?('warden')
  end

  def authorize!
    u = env['warden'].user(scope)
    u.nil? fail!("Could not authorize") : success!(u.permissions)
  end
end
```

### Setup Permissions

Permissions are simple, easy to setup objects that implement a specific interface. The minimum
we need to define is a permission name, which is usually implemented via a symbol. Permissions can
also be coupled with a subject, such as @Post@ or @Comment@, for example. Subjects open the door
for more fine tuned logic based on collections and resources. We pass a class as a second argument
to define how to process collections of objects that the user has certain permissions for. By
supplying a collection block, we give Watchman a chance to short circuit the authorization process
and return a collection of preauthorized objects for the requested permission. This makes it simple
to hook into something like @ActiveRecord@ and specify rules for applying a scoping. Supplying a
resource block will enable us to check authorization of individual objects and array-like
collections for requested permissions.

```ruby
Watchman::Permissions.add(:read_published_posts)

Watchman::Permissions.add(:read, Post) do
  collection do |posts|
    return false unless permitted?(:read_published_posts)

    posts.where(published: true)
  end

  resource do |post|
    return false unless permitted?(:read_published_posts)

    post.published?
  end
end
```

### Use it in your application

Authorization logic succeeds authentication. When, for example, using Warden for authentication
it's trivial to initialize the authorization environment by using Warden's @after_set_user@ hook. Passing
Warden's supplied options without modification is usually sufficient as many relevant option names are the same.

```ruby
Warden::Manager.after_set_user do |user, auth, opts|
  env['watchman'].authorize! opts # use all default strategies
  env['watchman'].authorize! :warden, opts # use only the :warden strategy
end

env['watchman'].ensure! :read, Post # Ensures that this permission is currently active, throws :watchman if fails.

posts = env['watchman'].permitted(:read, Post) # Only retrieves posts where published is set to true
env['watchman'].ensure! :read, posts # Checks all posts to ensure each returns true for published?, throws :watchman if fails.
env['watchman'].ensure! :read, posts.first # Ensure that post returns true for published?, throws :watchman if fails.

env['watchman'].permitted? :read, Post # Returns true if this permission is currently active.
env['watchman'].permitted? :read, posts # Checks all posts and returns true if each returns true for published?
env['watchman'].permitted? :read, posts.first # Returns true if post returns true for published?.
```

This setup means that whenever a user is authenticated using warden, they will automatically be
authorized, that is their permissions will be known to watchman. Using the @permitted@ method you
can retrieve a collection of objects for which the user has the permission. Using the @ensure!@
method you can then test individual objects or entire collections whether the action is authorized
or not and terminate the current request. By using the @permitted?@ method one can query whether
a permission is granted.
