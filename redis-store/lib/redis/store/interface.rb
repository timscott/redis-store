class Redis
  class Store < self
    module Interface

      ERRORS_TO_TOLERATE = [Redis::TimeoutError, Redis::CannotConnectError]

      # TODO: Make these user configurable
      TOLERATE_UNAVAILABLE_SERVICE = true
      RETRY_UNAVAILABLE_SERVICE_AFTER = 10

      def get(key, options = nil)
        tolerate { super(key) }
      end

      def set(key, value, options = nil)
        tolerate { super(key, value) } || false
      end

      def setnx(key, value, options = nil)
        tolerate { super(key, value) } || false
      end

      def setex(key, expiry, value, options = nil)
        tolerate { super(key, expiry, value) } || false
      end

    private

      def tolerate
        if TOLERATE_UNAVAILABLE_SERVICE
          begin
            unless @rety_after && Time.now < @rety_after
              @rety_after = nil
              yield
            end
          rescue *ERRORS_TO_TOLERATE
            @rety_after = Time.now + RETRY_UNAVAILABLE_SERVICE_AFTER
            nil
          end
        else
          yield
        end
      end
    end
  end
end
