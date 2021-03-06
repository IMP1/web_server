require_relative 'http_handler'
require_relative 'scaffold'

class DefaultHttpHandler < HttpHandler

    EXTENSIONS.insert(0, '.rml')

    def get_controller_type(route)
        return Controller.controllers.select { |c| c.match_path?(route) }.first
    end

    # Overwritten
    def get_file_type(filename)
        if filename.end_with? ".rml"
            return "text/html"
        end
        return super
    end

    # Overwritten
    def parse_file_contents(filename, file_contents, args)
        if filename.end_with? ".rml"
            return RMLParser.new(file_string, filename).parse(variables)
        end
        return super
    end

    # Overwritten
    def handle_request(socket, request_type, request_args)
        path = request_args[0].split('/')
        case request_type
        when :HEAD
            handle_head(socket)
        when :POST
            handle_post(socket, path)
        when :GET
            handle_get(socket, path)
        end
    end

    def handle_head(socket)
        no_content(socket)
    end

    def handle_post(socket, path)
        no_content(socket)
        # post_headers = {}
        # loop do
        #     line = socket.gets.split(' ', 2)
        #     break if line[0] == ""
        #     post_headers[line[0].chop] = line[1].strip
        # end
        # post_body = socket.read(post_headers["Content-Length"].to_i)

        # data = Hash[post_body.split(/\&/).map{ |pair| pair.split("=") }]

        # p data

        # # handle data, do creation or whatever
        # # return location to new data if relevant

        # location = 'foo/bar'
        # socket.print http_header(201, "Created", {"Location"=>"#{location}"})
        # socket.print EMPTY_LINE

        # or alternatively, give a no content response
    end

    def handle_get(socket, path)
        serve_file(socket, path)
    end

end
