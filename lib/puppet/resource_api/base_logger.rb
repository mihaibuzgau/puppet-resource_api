
class Puppet::ResourceApi::BaseLogger
  def initialize(typename)
    @typename = typename
  end

  [:debug, :info, :notice, :warning, :err].each do |level|
    define_method(level) do |*args|
      if args.length == 1
        message = "#{@context || @typename}: #{args.last}"
      elsif args.length == 2
        resources = format_titles(args.first)
        message = "#{resources}: #{args.last}"
      else
        message = args.map(&inspect).join(', ').to_s
      end
      send_log(level, message)
    end
  end

  [:creating, :updating, :deleting, :failing].each do |method|
    define_method(method) do |titles, message: method.to_s.capitalize|
      setup_context(titles, message)
      begin
        debug('Start')
        yield
        notice('Finished in x.yz seconds')
      rescue
        err('Failed after x.yz seconds')
        raise
      ensure
        @context = nil
      end
    end
  end

  def processing(titles, is, should, message: 'Processing')
    setup_context(titles, message)
    begin
      debug("Changing #{is.inspect} to #{should.inspect}")
      yield
      notice("Changed from #{is.inspect} to #{should.inspect} in x.yz seconds")
    rescue
      err("Failed changing #{is.inspect} to #{should.inspect} after x.yz seconds")
      raise
    ensure
      @context = nil
    end
  end

  def attribute_changed(titles, is, should, message: nil)
    setup_context(titles, message)
    notice("Changed from #{is.inspect} to #{should.inspect}")
  end

  private

  def format_titles(titles)
    "#{@typename}[#{[titles].flatten.compact.join(', ')}]"
  end

  def setup_context(titles, message = nil)
    @context = format_titles(titles)
    @context += ": #{message}: " if message
  end
end
