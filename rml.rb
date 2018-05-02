require_relative 'log'

class RMLParser

    SEPARATOR = " "

    def initialize(string, filename="Raw text")
        @filename = filename
        @string = string
        @logger = Logger.new("RML Parser")
    end

    def parse(variables=nil)
        @variables = variables || {}
        @logger.push("Beginning Parse of #{@filename}...")
        add_included_files
        handle_blocks
        eval_ruby
        fix_formatting
        @logger.pop("Successful Parse of #{@filename}.")
        return @string
    end

    def add_included_files
        @string.scan(/<ruby include=.+?>/).each do |m|
            filename = m[/include="(.+?)"/, 1]
            args = m[/args="(.+?)"/, 1]
            include_string = HttpHandler.file_contents(filename)
            if include_string.nil?
                @logger.log("Could not find #{filename}.", Logger::ERROR)
            else
                if !args.nil?
                    args.split("&").each do |pair| 
                        key, value = *pair.split("=")
                        include_string.gsub!(/\#\{#{key}\}/, value)
                    end
                end
                import = RMLParser.new(include_string, filename)
                # TODO: do any imported files need more processing?
                @string.sub!(m, import.add_included_files)
            end
        end
        return @string
    end

    def handle_blocks
        blocks = {}

        @string.scan(/<ruby block\-begin=".+?">/m).each do |m|
            block_name = m[19..-3]
            blocks[block_name] ||= []
            i = (0..blocks[block_name].size).inject(-1) { |memo, i| @string.index(m, memo + 1) }
            j = @string.index(/<ruby block\-end="#{block_name}">/m, i)
            k = @string.index(">", j + 1)
            blocks[block_name].push( @string[i+m.size...j] )
        end

        blocks.each do |block_name, block_levels|
            block_levels.each_with_index do |block, i|
                block_levels[i].gsub!(/<ruby block\-super>/, block_levels[i-1])
            end
        end

        blocks.keys.each do |block_name|
            @string.sub!(/<ruby block\-begin="#{block_name}">.+?<ruby block\-end="#{block_name}">/m, blocks[block_name].last)
        end
        @string.gsub!(/<ruby block\-begin="(.+?)">.+?<ruby block\-end="\1">/m, "")
        return @string
    end

    def eval_ruby
        @view_bag = @variables
        @view_bag['nav'] ||= []
        alias puts_inspect p  # Save p in a local method
        define_singleton_method("p"){ |arg| @current_output.push(arg) }
        @string.scan(/<ruby>.+?<\/ruby>/m).each do |m|
            @current_output = []
            code = m[6..-8]
            binding.eval(code)    
            @string = @string.sub(m, @current_output.join(SEPARATOR))
        end
        alias p puts_inspect  # Restore p
        return @string
    end

    def fix_formatting
        # TODO: there seems to be a problem with lots of tags on one line fucking up
        #       the formatting/indenting.
        string_copy = @string
        opening_tags = []
        void_tags = []
        loop do
            tag_name = string_copy[/<([\w\-]+).*?>.*?<\/\1>/m, 1]
            # TODO: include void tags. 
            # void_tag_name = string_copy[/<([\w\-]+).*?\/?/m, 1]
            # check that void tag name is not the same as the tag name
            # use whichever has the smaller index (whichever is first)
            # and then either add the opening tag OR the void tag.
            break if tag_name.nil?
            i = string_copy.index("<"+tag_name) + tag_name.size
            string_copy = string_copy[i..-1]
            opening_tags.push tag_name if !['html'].include? tag_name
        end
        closing_tags = []

        @string.gsub!(/\n\s*\n?/m, "\n") # remove empty lines

        unfinished_tags = []
        lines = @string.split("\n")
        depth = 0
        lines = lines.map.with_index do |line, line_number|
            padding = " " * (depth * 4)
            if opening_tags.size > 0 && line.include?("<#{opening_tags.first}")
                tag_name = opening_tags.delete_at(0)
                depth += 1
                closing_tags.push(tag_name)
            elsif void_tags.size > 0 and line.include?("<#{void_tags.first}")
                tag_name = void_tags.delete_at(0)
                puts "THIS SHOULDN'T ACTUALLY HAPPEN YET"
            end
            if closing_tags.size > 0 && line.include?("</#{closing_tags.last}")
                closing_tags.pop
                depth -= 1
                padding = " " * (depth * 4)
            end
            if line.count('<') > line.count('>') and !tag_name.nil?
                unfinished_tags.push({ :tag => tag_name, :line => line_number })
            end
            padding + line # return the line with its corrected padding
        end
        unfinished_tags.each do |a|
            i = a[:tag].length + 1
            line_number = a[:line] + 1
            loop do
                lines[line_number] = (" " * i) + lines[line_number][3..-1]
                break if lines[line_number].include? ">"
                line_number += 1
            end
        end
        @string = lines.join("\n")
    end

end