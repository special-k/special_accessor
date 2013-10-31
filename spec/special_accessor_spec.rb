require 'benchmark'
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "SpecialAccessor" do

  before :all do
    class P
      special_accessor x: 1
      question_accessor :x
    end

    class A
      question_accessor :a, :b, :c => true, :d => true
      special_accessor f: 1, h: ->s{[]}
      proxy_accessor :x, :through => :w
      attr_accessor :g
      attr_reader :w

      proxy_method :x?, :through => :w

      def initialize
        @w = P.new
      end

      def e?
        if @is_e.nil?
          @is_e = false
        end
        @is_e
      end

      def g
        @g ||= 1
      end

      def i
        @i ||= []
      end

      def xx
        w.x
      end

      def xx= v
        w.x= v
      end

      def xx?
        w.x?
      end

    end

  end

  it "question_accessor" do
    a = A.new

    a.a?.should eq false
    a.b?.should eq false

    a.c?.should eq true
    a.d?.should eq true

    a.a!.should eq true
    a.b!.should eq true
    a.a?.should eq true
    a.b?.should eq true

    a.unset_c!.should eq false
    a.unset_d!.should eq false
    a.c?.should eq false
    a.d?.should eq false

  end

  it 'special_accessor' do
    a = A.new

    a.f.should eq 1
    a.f = 2
    a.f.should eq 2
    a.h.is_a?( Array ).should be_true
    a.h.should be_empty
    a.h << 1

    b = A.new
    b.h.should be_empty

  end

  it 'proxy_accessor' do
    a = A.new

    a.x.should eq 1
    a.x = 2
    a.x.should eq 2

  end

  it 'proxy_method' do
    a = A.new
    a.x?.should be_false
  end

  it 'exeptions' do
    expect{ A.class_eval{ special_accessor :"o o" => 1 } }.to raise_error(NameError)
    expect{ A.class_eval{ special_accessor :o? => 1 } }.to raise_error(NameError)
    expect{ A.class_eval{ question_accessor :o => 1 } }.to raise_error(ArgumentError)
    expect{ A.class_eval{ proxy_accessor :o } }.to raise_error(ArgumentError)
    expect{ A.class_eval{ proxy_method :o } }.to raise_error(ArgumentError)
  end

  it "benchmark" do
    a = A.new
    n = 1000000
    Benchmark.bm(3) do |b|
      b.report("meta:  "){ n.times{ a.a? } }
      b.report("static:"){ n.times{ a.e? } }

      b.report("meta:  "){ n.times{ a.f } }
      b.report("static:"){ n.times{ a.g } }

      b.report("meta:  "){ n.times{ a.f = 2 } }
      b.report("static:"){ n.times{ a.g = 2 } }

      b.report("meta:  "){ n.times{ a.h } }
      b.report("static:"){ n.times{ a.i } }

      b.report("meta:  "){ n.times{ a.x } }
      b.report("static:"){ n.times{ a.xx } }

      b.report("meta:  "){ n.times{ a.x = 2 } }
      b.report("static:"){ n.times{ a.xx = 2 } }

      b.report("meta:  "){ n.times{ a.x? } }
      b.report("static:"){ n.times{ a.xx? } }
    end
  end

end
