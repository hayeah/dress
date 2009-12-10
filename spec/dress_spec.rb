require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'pp'
require 'tempfile'

describe "Dress" do
  
  def test_data
    Nokogiri.make { foo { bar { baz }}}.parent
  end

  it "transforms" do
    d = Dress {
      match("bar") do
        wrap(nil) { qux }
      end

      match("bar") do
        set("attr","oh yay!")
      end
    }
    
    node = d.on(test_data)
    (node / "qux bar").should_not be_empty
  end

  it "transforms xml string or file" do
    d = Dress {
      match("bar") do
        wrap(nil) { qux }
      end
    }
    doc_str = "<bar></bar>"
    r = d.on(doc_str)
    (r / "qux bar").should_not be_empty

    Tempfile.open("test-xml") do |f|
      f.puts doc_str
      f.flush
      r = d.on(File.new(f.path))
      (r / "qux bar").should_not be_empty  
    end
  end

  it "transforms the first element found with at" do
    d = Dress {
      at("bar") do
        me.name = "bar2"
      end
    }
    r = d.on(test_data)
    (r / "bar2").should_not be_empty
  end
  
  it "chains transforms" do
    d1 = Dress {
      match("bar") do
        wrap(nil) { qux }
      end
    }

    d2 = Dress {
      match("bar") do
        set("attr","oh yay!")
      end
    }

    line = (d1 | d2)
    line.should be_a(Dress::Line)
    node = line.on(test_data)
    (node / "qux").should_not be_empty
    (node / "qux bar").should_not be_empty
    node.xpath("//@attr").map(&:value).should == ["oh yay!"]
  end

  it "chains chains" do
    d1 = Dress {
      match("foo") do
        set("a","1")
      end
    }

    d2 = Dress {
      match("foo") do
        set("b","2")
      end
    }

    d3 = Dress {
      match("bar") do
        set("a","1")
      end
    }

    d4 = Dress {
      match("bar") do
        set("b","2")
      end
    }

    line1 = (d1 | d2)
    line2 = (d3 | d4)
    line = (line1 | line2)
    line.length.should == 4
    node = line.on(test_data)
    node.xpath("foo/@a").map(&:value).should == ["1"]
    node.xpath("foo/@b").map(&:value).should == ["2"]
    node.xpath("//bar/@a").map(&:value).should == ["1"]
    node.xpath("//bar/@b").map(&:value).should == ["2"]
  end
end

describe "Dress::Maker" do
  it "renders" do
    d = DressMaker {
      layout { wrap1 { wrap2 { content }}}
      layout(:foo) { foo { content }}
      def content1
        some_stuff(:a => "10", :b => "20") { inside }
      end
    }
    d.render(:content1).to_s.should == '<wrap1><wrap2><some_stuff a="10" b="20"><inside></inside></some_stuff></wrap2></wrap1>'
    d.render(:content1,:foo).to_s.should == '<foo><some_stuff a="10" b="20"><inside></inside></some_stuff></foo>'
  end
end
