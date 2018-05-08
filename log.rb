class Logger

    NONE        = 0
    FATAL       = 1
    ERROR       = 2
    WARNING     = 3
    INFORMATION = 4
    DEBUG       = 5
    TRACE       = 6

    PRIORITY_STRINGS = %w(None Fatal Error Warning Info Debug Trace)

    attr_reader :last_message
    
    @@depths = {}

    def initialize(source, output=$stdout)
        @source = source
        @out = output
        @padding = 4
        @last_message = ""
        @importance_level = DEBUG
        @@depths[@out] ||= 0
    end

    def set_level(level)
        @importance_level = level
    end

    def push(message, importance=INFORMATION)
        log_message(message, importance)
        @@depths[@out] += 1
    end

    def pop(message, importance=INFORMATION)
        @@depths[@out] -= 1
        @@depths[@out] = 0 if @@depths[@out] < 0
        log_message(message, importance)
    end

    def log(message, importance=INFORMATION)
        log_message(message, importance)
    end

    def log_message(message, importance)
        return if importance > @importance_level
        @out.puts "[#{@source}] (#{PRIORITY_STRINGS[importance]}): " + (" " * @padding * @@depths[@out]) + message 
        @last_message = message
    end

end