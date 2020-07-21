class ApplicationService
  attr_accessor :result, :called

  def self.call(*args, &block)
    service = new(*args, &block)
    service.result = service.call
    service.called = true
    service
  end

  def success?
    called? && !failure?
  end
  alias_method :successful?, :success?

  def failure?
    called? && errors.any?
  end
  alias_method :failed?, :failure?

  def errors
    @errors ||= ApplicationService::Errors.new
  end

  private

  def called?
    @called ||= false
  end

  class Errors < Hash
    def add(key, value, _opts = {})
      self[key] ||= []
      self[key] << value
      self[key].uniq!
    end

    def add_multiple_errors(errors_hash)
      errors_hash.each do |key, values|
        values.each { |value| add key, value }
      end
    end

    def each
      each_key do |field|
        self[field].each { |message| yield field, message }
      end
    end

    def full_messages
      map { |attribute, message| full_message(attribute, message) }
    end

    private

    def full_message(attribute, message)
      return message if attribute == :base
      attr_name = attribute.to_s.tr('.', '_').capitalize
      "%s %s" % [attr_name, message]
    end
  end
end