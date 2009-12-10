require 'nokogiri'

class Dress
  class Line
    attr_reader :dresses
    def initialize(dresses)
      @dresses = dresses
    end

    def |(obj)
      case obj
      when Line
        Line.new(self.dresses + obj.dresses)
      when Dress
        Line.new(self.dresses + [obj])
      else
        raise "expects a Dress or a Line"
      end
    end

    def length
      dresses.length
    end

    def on(node)
      @dresses.each do |dress|
        dress.on(node)
      end
      node
    end
  end
  
  class << self
    attr_reader :transforms
    def match(matcher,&block)
      @transforms ||= []
      @transforms << [:search,matcher,block]
    end

    def at(matcher,&block)
      @transforms ||= []
      @transforms << [:at,matcher,block]
    end

    # destructive transform of node
    def on(node)
      node =
        case node
        when Nokogiri::XML::Node
          node
        when String,IO
          Nokogiri::XML(node)
        else
          raise "bad xml document: #{node}"
        end
      dresser = self.new(node)
      node
    end

    def style(&block)
      c = Class.new(Dress)
      c.class_eval(&block)
      c
    end

    def |(dress2)
      raise "expects a Dress" unless dress2.ancestors.include?(Dress)
      Line.new([self,dress2])
    end
  end

  attr_reader :me
  def initialize(node)
    self.class.transforms.each do |(method,matcher,block)|
      # method == :at | :search
      @me = node.send(method,matcher)
      self.instance_eval(&block) # this is so we can define helper methods on the dress
    end
  end
  
  def method_missing(method,*args,&block)
    if block
      @me.send(method,*args,&block)
    else
      @me.send(method,*args)
    end
  end
end

def Dress(&block)
  Dress.style(&block)
end


class Dress::Maker 
  class << self
    def layout(name=nil,&block)
      @layouts ||= {}
      if block
        # define layout
        @layouts[name] = Nokogiri.make(&block)
      else # get layout
        pp @layouts
        l = @layouts[name]
        raise "no layout defined for: #{name ? name : 'default'}" unless l
        l
      end
    end

    def render(page,layout_name=nil,*args,&block)
      p [:layout,layout_name]
      content = self.new.send(page,*args,&block)
      p [:content,content]
      l = layout(layout_name).clone
      holder = l.at("content")
      raise "can't find <content> in layout" unless holder
      holder.replace(content)
      l
    end
  end

  def method_missing(method,*args,&block)
    Nokogiri.make {
      #builder = self
      d = self.send(method,*args,&block)
    }
  end
end

def DressMaker(&block)
  c = Class.new(Dress::Maker)
  c.class_eval(&block)
  c
end

