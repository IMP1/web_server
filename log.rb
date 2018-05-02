class Logger

    NONE        = 0
    ERROR       = 1
    WARNING     = 2
    INFORMATION = 3
    DEBUG       = 4

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
        @out.puts "[#{@source}] " + (" " * @padding * @@depths[@out]) + message 
        @last_message = message
    end

end