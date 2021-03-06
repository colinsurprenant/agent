require "helper"

describe "Channel of Channels" do

  Request = Struct.new(:args, :resultChan)

  it "should be able to pass channels as first class citizens" do
    server = Proc.new do |reqs|
      2.times do |n|
        res = Request.new(n, Agent::Channel.new(:name => "resultChan_#{n}".to_sym, :type => Integer))

        reqs << res
        res.resultChan.receive.should == n+1
      end
    end

    worker = Proc.new do |reqs|
      loop do
        req = reqs.receive
        req.resultChan << req.args+1
      end
    end

    clientRequests = Agent::Channel.new(:name => :clientRequests, :type => Request)

    s = go(clientRequests, &server)
    c = go(clientRequests, &worker)

    s.join
    clientRequests.close
  end

  it "should work with multiple workers" do
    worker = Proc.new do |reqs|
      loop do
        req = reqs.receive
        req.resultChan << req.args+1
      end
    end

    clientRequests = Agent::Channel.new(:name => :clientRequests, :type => Request)

    # start multiple workers
    go(clientRequests, &worker)
    go(clientRequests, &worker)

    # start server
    s = go clientRequests do |reqs|
      2.times do |n|
        res = Request.new(n, Agent::Channel.new(:name => "resultChan_#{n}".to_sym, :type => Integer))

        reqs << res
        res.resultChan.receive.should == n+1
      end
    end

    s.join
  end
end