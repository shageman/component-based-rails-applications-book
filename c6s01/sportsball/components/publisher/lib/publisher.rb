
module Publisher
  def add_subscriber(object)
    @subscribers ||= []
    @subscribers << object
  end

  def publish(message, *args)
    return if @subscribers == [] || @subscribers == nil
    @subscribers.each do |subscriber|
      if subscriber.respond_to?(message)
        subscriber.send(message, *args)
      end
    end
  end
end

