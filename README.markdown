# XSLT(not!) with Elegant Dress

You'd swear XSLT is a joke, but it's not. It's
cruelty. XSLT is like this: it's good to rid the
city of this horrible vermin infestation-- Let's
nuke the city. It's an out-of-proportion
insanity. It's Turing-complete, and it's XML.

Hmm.

But what it is, is just a set of transformations
on fragments of your XML document. The beauty of
XSLT (they say), is that XSLT itself is XML, so
you can (in principle) use XSLT to transform
itself.

Hmm.

Oh I know, how about let's use Ruby?

# Transformation Elegant Dress

Honestly, there's not much to it. A `Dress` is
just a sequence of transformations you perform on
a DOM tree. Unlike XSLT though, the
transformations are performed directly on the DOM
tree. That is to say, they are destructive.

This is a simple dress,

    require 'dress'
    doc = "<my><brain></brain></my>"
    dress = Dress {
     match("brain") do
       set("size","pea")
     end
    }
    result = dress.on(doc)
    puts result.to_s
    # <my><brain "size"="pea"></brain></my>


We can have more matchers,

    dress = Dress {
     match("brain") do
       set("size","pea")
     end
     match("my") do
       each { |e| e.name = "homer"}
     end
    }
    result = dress.on(doc)
    puts result.to_s
    # <homer><brain "size"="pea"></brain></homer>


Note that match always yield a
`Nokogiri::Nodeset`. But sometimes we'd like to
operate on just one node (or the first one we
find). For that there's the `at` matcher.

    dress = Dress {
      at("my") do
        me.name = "homer"
      end
    }

`me` is always the object yielded by the matcher
string. For `match` it would be a Nodeset, and for
`at`, it would be an Element.

We can define helper methods on a Dress. This is
one that implements a counter,

    dress = Dress {
      def count
        @count ||= 0
        @count += 1
        @count
      end

      match("brain") do
        each { |e| e["area"] = count.to_s }
      end
    }
    puts dress.on(Nokogiri.make { my { brain; brain; brain; brain }}).to_s
    # <my><brain area="1"></brain><brain area="2"></brain><brain area="3"></brain><brain area="4"></brain></my>



We can combine dresses into lines,

    d1 = Dress { ... }
    d2 = Dress { ... }
    (d1 | d2).on(doc)


We can link lines together,

    d3 = Dress { ... }
    d4 = Dress { ... }
    ((d1 | d2) | (d3 | d4)).on(doc)


A dress is a class inheriting from Dress.

    class FancyDress < Dress
      def helper1
      end
      def helper2
      end
      match(...) { ... }
      ...
    end

    class PrettyDress < Dress
      ...
    end


Then we can combine these dresses,

    (FancyDress | PrettyDress).on(document)

You can of course mix that with dynamic dresses,

    (FancyDress | PrettyDress | Dress do ... end).on(doc)


# That Wasn't So Hard, Was It?

So Ruby saved us all from XSLT. Minus all the
XSLT-inspired buckets of tears, the world is a
better place. FTW.

# Copyright

Copyright (c) 2009 Howard Yeh. See LICENSE for details.
