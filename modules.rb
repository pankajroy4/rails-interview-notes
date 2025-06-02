Modules:
=======
  ➤ A module is a collection of methods, constants, and classes. 
    It cannot be instantiated like a class but can be included or extended in other classes to share functionality.

  ➤ Key Features of a Module:
    - Used to group related methods.
    - Cannot be instantiated.
    - Can be included or extended to add functionality to classes.
    - Supports namespacing to organize code and avoid naming conflicts.
    - We cannot use instance methods of a module without including or extending (or prepending) it in some other class.

  module MyModule
    PI = 3.14
    class InnerClass
      def say_hello
        puts "Hello from InnerClass!"
      end
    end

    #Instance method (Directly defined method in the modules)
    def greet
      puts "Value of pi is #{PI}"
      puts "Hello from MyModule!"
    end

    # module methods (aka singleton methods)
    def self.area_of_circle(radius)
      PI * radius**2
    end
  end

  puts MyModule::PI   #=> 3.14
  puts MyModule::area_of_circle(7)   #=> 153.86 
  puts MyModule.greet  #=> Error (Can not use instance method direclty)
  puts MyModule::greet  #=> Error (Can not use instance method direclty)
  puts MyModule::InnerClass.new.say_hello  #=> Hello from InnerClass

  ➤ Mixins (Using include or extend)
      A mixin is a way to add module methods to a class. Since Ruby does not support multiple inheritance, mixins are used to share code across classes.
        include → Adds module methods(direclty defined methods of module) as instance methods in the target class
        extend → Adds module methods(direclty defined methods of module) as class methods in the target class.

  ➤ When a class extend, include or prepend a module then:
      - Only the instance methods will get mixins to the target class.
      - Constants, classes and module methods will not get mixins to the target class.

  
Difference betwwen require, include, extend and prepend
========================================================
  ╰┈➤ require:
        - Used to load external files or libraries.
        - It is part of Ruby load path system, which finds the file and loads it once.
        - Typically used for loading Ruby gems, libraries, or custom Ruby files.
        - Loads the file once during runtime.
        - Does not include methods directly into a class or module.
        - Commonly used at the top of Ruby files to load dependencies.

        Syntax: require 'my_module'

  ╰┈➤ include:
        - Used to mix in a module's methods into a class. 
        - The module's instance methods(direclty defined methods of module) become Instance methods of the class where it is included.
        - Adds methods as instance methods.
        - Does not load files — the file must be required first if it os not already loaded.

  ╰┈➤ extend:
        - Used to mix in a module's methods into a class. 
        - The module's instance methods(direclty defined methods of module) become Class methods of the class where it is included.
        - Adds methods as Class methods.
        - Does not load files — the file must be required first if it os not already loaded.

  ╰┈➤ prepend:
        - Used to mix in a module's methods into a class. 
        - The module's instance methods(direclty defined methods of module) become instance methods of the class (just like include do) where it is included, But with higer prioprity.
        - Higher proiority means, If the target class already have method with same name then also module method will win which was injected by prepend
        - Adds methods as instance methods.
        - Does not load files — the file must be required first if it os not already loaded.

        module Greeting
          def greet
            puts "Hello from module!"
          end
        end

        class User
          prepend Greeting   # Adds `greet` as an instance method 

          def greet 
            puts "Hello from User instance method!"
          end
        end

        User.new.greet  #=> "Hello from module!"

  Think of it like:
    include - adds behavior
    extend - adds class behavior
    prepend - overrides behavior

➤ Mixins in Ruby act as an alternative to multiple inheritance, similar to how multiple inheritance works in C++.
    - Ruby follows a single inheritance model, meaning a class can inherit from only one parent class.
    - To achieve code reusability across multiple classes, Ruby provides mixins using modules.

    module A
      def greet
        puts "Hello from A!"
      end
    end

    module B
      def greet
        puts "Hello from B!"
      end
    end

    class C
      include A
      include B
    end

    obj = C.new
    obj.greet  # Output: "Hello from B!" (Last included module wins)

  - Ruby follows the Method Lookup Path (MRO).
  - In the above example, since B was included after A, its greet method takes priority.
  - This avoids the diamond problem common in C++ multiple inheritance.

  Even though module B takes priority (since it was included last), you can still explicitly call module A greet method using super.

    module A
      def greet
        puts "Hello from A!"
      end
    end

    module B
      def greet
        puts "Hello from B!"
        super   # Calls `greet` from the previous module in the lookup path (here, `module A`)
      end
    end

    class C
      include A
      include B
    end

    obj = C.new
    obj.greet

    # Output:
    # Hello from B!
    # Hello from A!

    - The super keyword calls the next method in the method lookup path (MRO).
    - Since module B was included last, its method runs first.
    - super then moves up the chain and calls module A method.

Nested module with extend & include
==================================
  👇With extend:
  module Greeting
    def greet
      puts "Hello!"
    end

    module ClassMethods
      def say_hello
        puts "say hello"
      end
    end
  end

  class User
    include Greeting
    extend Greeting::ClassMethods
  end

  User.say_hello   #=> say hello
  - This is how Rails does it internally too (ActiveSupport::Concern helps automate this).

  👇With include:
  module Greeting
    def greet
      puts "Hello!"
    end

    module ClassMethods
      def say_hello
        puts "say hello"
      end
    end
  end

  class User
    include Greeting
    include Greeting::ClassMethods
  end

  User.new.say_hello   #=> say hello

Method resolution precedence
============================
 ➤ Method resolution precedence when the same method name exists in module and in target class:
    ╰┈➤ When we use extend then:(Adds module methods as class method )
      - class method of the target class with same name will get precedence and method from module will not take into effect.
      - Adds module methods as class methods.
      - If the target class already defines a class method with the same name, it takes precedence.

        module Greet
          def hello
            "Hello from module!"
          end
        end

        class Person
          extend Greet

          def self.hello
            "Hello from person class method"
          end
        end

        Person.hello #=> Hello from person class method  #(Due to chain lookup, First ruby will seacrh for method in same class)

      - Instance method of same name in the target class will not have any problem , they will be used as before.
      - Instance methods in the target class with same name are unaffected.

        module Greet
          def hello
            "Hello from module!"
          end
        end

        class Person
          extend Greet
        
          def hello
            "Hello from person instance method"
          end
        end

        Person.hello  #=> Hello from module!
        Person.new.hello #=> Hello from person instance method

      - Person class defines an instance method hello, not a class method. 
      - So it does not override the hello method from the module, which was extended as a class method.

    ╰┈➤ When we use include then:(Adds module methods as instance method )
      - class method of the target class with same name will not got affected. They will be used as before.

        module Greet
          def hello
            "Hello from module method!"
          end
        end

        class Person
          include Greet

          def self.hello
            "Hello from person class method"
          end
        end

        Person.hello #=> Hello from person class method
        person.new.hello #=> Hello from module method!


      - Instance method of same name in the target class will get precedence and method from module will not take into effect.
        module Greet
          def hello
            "Hello from module!"
          end
        end

        class Person
        include Greet
        
          def hello
            "Hello from person instance method"
          end
        end

        Person.new.hello #=> Hello from person instance method

        - Even though the module defined hello, the class has its own hello, which takes precedence.

    ╰┈➤ When we use prepend then:(It is just like include but with higher method priority. Adds module methods as instance method in target class. )

        module Greet
          def hello
            "Hello from module!"
          end
        end

        class Person
          prepend Greet
        
          def hello
            "Hello from person instance method"
          end
        end

        Person.new.hello #=> Hello from module.

        - prepend is just like include, adds module methods as instance methods, but with higher priority.
        - Even if the target class defines the method with same name, module method wins.


