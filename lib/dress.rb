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

# TODO move to monkey patch
class Nokogiri::XML::Builder
  def n(*docs)
    docs.each do |doc|
      case doc
      when String
        self << doc
      when Nokogiri::XML::Node
        insert(doc)
        #self << doc.to_s
        #self.doc.children.each 
      else
        raise "bad node: #{doc}" 
      end
    end
  end

  def t(*texts)
    texts.each do |text|
      self.text(text.to_s)
      self.text(" ")
    end
  end
end

class Dress::Maker
  require 'active_support'
  require 'active_support/core_ext'

  class_inheritable_hash :layout_defs
  self.layout_defs = {}
  
  class << self
    
    
    def layouts
      #read_inheritable_attribute(:layouts).keys
      layout_defs.keys
    end
    
    def layout(name=nil,&block)
      layout_defs[name] = block
    end

    def with(name,page,*args,&block)
      content = self.new.send(page,*args,&block)
      l = layout(name).clone
      l.at("content").replace(content)
      l
    end

    def render(page,*args,&block)
      self.new.render(page,*args,&block)
    end

    def render_with(layout,page,*args,&block)
      self.new.render_with(layout,page,*args,&block)
    end
  end

  def render(page,*args,&block)
    # use default layout
    render_with(nil,page,*args,&block)
  end

  def render_with(layout,page,*args,&block)
    content = self.send(page,*args,&block)
    l = self.instance_eval(&self.class.layout_defs[layout])
    l.at("content").replace(content)
    l
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


# TODO break this out to a separate loadable file
class Dress::ActiveView < Dress::Maker
  require 'action_pack'
  require 'action_view'
  extend ActionView::Helpers
  include ActionView::Helpers
  DEFAULT_CONFIG = ActionView::DEFAULT_CONFIG unless defined?(DEFAULT_CONFIG)

  def config
    self.config = DEFAULT_CONFIG unless @config
    @config
  end

  def config=(config)
    @config = ActiveSupport::OrderedOptions.new.merge(config)
  end

  def initialize(controller)
    @controller = controller
  end
end
