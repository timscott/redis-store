require 'test_helper'

class InterfacedRedis < Redis
  include Redis::Store::Interface
end

describe Redis::Store::Interface do
  before do
    @r = InterfacedRedis.new
  end

  it "should get an element" do
    lambda { @r.get("key", :option => true) } #.wont_raise ArgumentError
  end

  it "should set an element" do
    lambda { @r.set("key", "value", :option => true) } #.wont_raise ArgumentError
  end

  it "should setnx an element" do
    lambda { @r.setnx("key", "value", :option => true) } #.wont_raise ArgumentError
  end

  it "should setex an element" do
    lambda { @r.setex("key", 1, "value", :option => true) } #.wont_raise ArgumentError
  end

  [Redis::TimeoutError, Redis::CannotConnectError].each do |tolerable_error|
    describe "when connect raises #{tolerable_error}" do

      before do
        Redis::Client.any_instance.stubs(:ensure_connected).raises(tolerable_error)
      end

      it 'should return nil upon get' do
        @r.get('key').must_equal nil
      end

      it 'should return false and set last failure upon set' do
        @r.set('key', 'value').must_equal false
      end

      it 'should return false and set last failure upon setnx' do
        @r.setnx('key', 'value').must_equal false
      end

      it 'should return false and set last failure upon setex' do
        @r.setex('key', 1, 'value').must_equal false
      end

      describe 'after tolerated unavailable service' do

        let(:now) { Time.now }

        before do
          Timecop.freeze now
          @r.get('key')
        end

        after { Timecop.return }

        it 'should retry only after enough time elapsed' do
          Timecop.travel Time.now + 9
          Redis::Client.any_instance.expects(:ensure_connected).never
          @r.get('key')
          Timecop.travel Time.now + 1
          Redis::Client.any_instance.expects(:ensure_connected).once
          @r.get('key')
        end

      end

    end
  end

end
